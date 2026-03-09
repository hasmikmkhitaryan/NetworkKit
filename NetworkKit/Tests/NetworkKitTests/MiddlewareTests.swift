//
//  MiddlewareTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class MiddlewareTests: XCTestCase {
    
    func testAuthMiddleware() async throws {
        // Given
        let tokenProvider = MockTokenProvider(accessToken: "test-token")
        let middleware = AuthMiddleware(tokenProvider: tokenProvider)
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When
        let result = try await middleware.prepare(request, requiresAuth: true)
        
        // Then
        XCTAssertEqual(result.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }
    
    func testAuthMiddlewareNoAuthRequired() async throws {
        // Given
        let tokenProvider = MockTokenProvider(accessToken: "test-token")
        let middleware = AuthMiddleware(tokenProvider: tokenProvider)
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When
        let result = try await middleware.prepare(request, requiresAuth: false)
        
        // Then
        XCTAssertNil(result.value(forHTTPHeaderField: "Authorization"))
    }
    
    func testAuthMiddlewareNoToken() async throws {
        // Given
        let tokenProvider = MockTokenProvider(accessToken: nil)
        let middleware = AuthMiddleware(tokenProvider: tokenProvider)
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When
        let result = try await middleware.prepare(request, requiresAuth: true)
        
        // Then
        XCTAssertNil(result.value(forHTTPHeaderField: "Authorization"))
    }
    
    func testRetryMiddlewarePolicy() async {
        // Given
        let middleware = RetryMiddleware(policy: .limited(2))
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When
        let advice1 = await middleware.retryAdvice(
            response: nil,
            error: .timeout,
            request: request,
            attempt: 0
        )
        
        let advice2 = await middleware.retryAdvice(
            response: nil,
            error: .timeout,
            request: request,
            attempt: 1
        )
        
        let advice3 = await middleware.retryAdvice(
            response: nil,
            error: .timeout,
            request: request,
            attempt: 2
        )
        
        // Then
        XCTAssertTrue(advice1.shouldRetry)
        XCTAssertTrue(advice2.shouldRetry)
        XCTAssertFalse(advice3.shouldRetry)
    }
    
    func testRetryMiddlewareTokenRefresh() async {
        // Given
        let tokenProvider = MockTokenProvider(accessToken: "old-token")
        let middleware = RetryMiddleware(policy: .limited(2), tokenProvider: tokenProvider)
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When
        let advice = await middleware.retryAdvice(
            response: response,
            error: .server(status: 401, data: nil),
            request: request,
            attempt: 0
        )
        
        // Then
        XCTAssertTrue(advice.shouldRetry)
        XCTAssertNotNil(advice.newRequest)
        XCTAssertEqual(advice.newRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer new-token")
    }
    
    func testETagMiddleware() async throws {
        // Given
        let cache = InMemoryETagCache()
        let middleware = ETagMiddleware(cache: cache)
        var request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        request.setValue("GET", forHTTPHeaderField: "HTTPMethod")
        
        // When - first request (no ETag)
        let result1 = try await middleware.prepare(request, requiresAuth: false)
        
        // Then - should not have If-None-Match header
        XCTAssertNil(result1.value(forHTTPHeaderField: "If-None-Match"))
        
        // When - simulate response with ETag
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["ETag": "\"abc123\""]
        )!
        
        await middleware.didReceive(.success((Data(), response)), for: request)
        
        // When - second request (should have ETag)
        let result2 = try await middleware.prepare(request, requiresAuth: false)
        
        // Then - should have If-None-Match header
        XCTAssertEqual(result2.value(forHTTPHeaderField: "If-None-Match"), "\"abc123\"")
    }
    
    func testLoggingMiddleware() async throws {
        // Given
        let mockLogger = MockLogger()
        let middleware = LoggingMiddleware(logger: mockLogger)
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When
        let _ = try await middleware.prepare(request, requiresAuth: false)
        
        // Then
        XCTAssertTrue(mockLogger.requestLogged)
    }
}

// MARK: - Mock Token Provider
class MockTokenProvider: TokenProvider {
    var accessToken: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func refreshToken() async throws -> String {
        accessToken = "new-token"
        return "new-token"
    }
}

// MARK: - Mock Logger
class MockLogger: Logger {
    var requestLogged = false
    var responseLogged = false
    var errorLogged = false
    
    func logRequest(_ request: URLRequest, level: LogLevel) {
        requestLogged = true
    }
    
    func logResponse(_ response: HTTPURLResponse, data: Data?, for request: URLRequest, level: LogLevel) {
        responseLogged = true
    }
    
    func logError(_ error: NetworkError, for request: URLRequest, level: LogLevel) {
        errorLogged = true
    }
}
