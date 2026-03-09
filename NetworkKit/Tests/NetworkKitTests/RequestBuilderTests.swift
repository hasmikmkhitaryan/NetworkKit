//
//  RequestBuilderTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class RequestBuilderTests: XCTestCase {
    
    var builder: RequestBuilder!
    
    override func setUp() {
        super.setUp()
        builder = RequestBuilder(baseURL: URL(string: "https://api.example.com")!)
    }
    
    func testBasicRequest() throws {
        // Given
        let endpoint = TestEndpoint(
            method: .GET,
            path: "/users",
            query: [URLQueryItem(name: "page", value: "1")],
            headers: ["Accept": "application/json"],
            body: nil,
            requiresAuth: false,
            cachePolicy: .useURLCache,
            decoder: nil
        )
        
        // When
        let request = try builder.makeRequest(endpoint)
        
        // Then
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/users?page=1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.cachePolicy, .useProtocolCachePolicy)
    }
    
    func testPOSTRequestWithBody() throws {
        // Given
        let body = Data("test body".utf8)
        let endpoint = TestEndpoint(
            method: .POST,
            path: "/posts",
            query: [],
            headers: ["Content-Type": "application/json"],
            body: body,
            requiresAuth: true,
            cachePolicy: .reloadIgnoringCache,
            decoder: nil
        )
        
        // When
        let request = try builder.makeRequest(endpoint)
        
        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/posts")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
    }
    
    func testCachePolicyRevalidate() throws {
        // Given
        let endpoint = TestEndpoint(
            method: .GET,
            path: "/users",
            query: [],
            headers: [:],
            body: nil,
            requiresAuth: false,
            cachePolicy: .revalidate,
            decoder: nil
        )
        
        // When
        let request = try builder.makeRequest(endpoint)
        
        // Then
        XCTAssertEqual(request.cachePolicy, .useProtocolCachePolicy)
    }
    
    func testInvalidURL() {
        // Given
        let builder = RequestBuilder(baseURL: URL(string: "https://example.com")!)
        let endpoint = TestEndpoint(
            method: .GET,
            path: "////  ",
            query: [],
            headers: [:],
            body: nil,
            requiresAuth: false,
            cachePolicy: .useURLCache,
            decoder: nil
        )
        
        // When/Then
        XCTAssertThrowsError(try builder.makeRequest(endpoint)) { error in
            if case NetworkError.invalidURL = error {
                // Expected
            } else {
                XCTFail("Expected NetworkError.invalidURL")
            }
        }
    }
}

// MARK: - Test Endpoint
struct TestEndpoint: Endpoint {
    typealias Response = EmptyResponse
    
    let method: HTTPMethod
    let path: String
    let query: [URLQueryItem]
    let headers: Headers
    let body: Data?
    let requiresAuth: Bool
    let cachePolicy: CachePolicy
    let decoder: JSONDecoder?
}
