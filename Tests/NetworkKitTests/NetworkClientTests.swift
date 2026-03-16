//
//  NetworkClientTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class NetworkClientTests: XCTestCase {
    var client: DefaultNetworkClient!
    var mockHTTPClient: MockHTTPClient!
    var builder: RequestBuilder!
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        builder = RequestBuilder(baseURL: URL(string: "https://api.example.com")!)
        client = DefaultNetworkClient(
            http: mockHTTPClient,
            builder: builder,
            middlewares: []
        )
    }
    
    func testSuccessfulRequest() async throws {
        // Given
        let expectedUser = GetUser.UserDTO(id: "123", name: "John Doe")
        let responseData = try JSONEncoder().encode(expectedUser)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/users/123")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockHTTPClient.mockResponse = (responseData, response)
        
        // When
        let result: GetUser.UserDTO = try await client.send(GetUser(id: "123"))
        
        // Then
        XCTAssertEqual(result.id, "123")
        XCTAssertEqual(result.name, "John Doe")
    }
    
    func testEmptyResponse() async throws {
        // Given
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/posts/123")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockHTTPClient.mockResponse = (Data(), response)
        
        // When
        let result: EmptyResponse = try await client.send(DeletePost(id: "123"))
        
        // Then
        XCTAssertNotNil(result)
    }
    
    func testServerError() async {
        // Given
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/users/123")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockHTTPClient.mockResponse = (Data(), response)
        
        // When/Then
        do {
            let _: GetUser.UserDTO = try await client.send(GetUser(id: "123"))
            XCTFail("Expected NetworkError.server")
        } catch let error as NetworkError {
            if case .server(let status, _) = error {
                XCTAssertEqual(status, 404)
            } else {
                XCTFail("Expected server error with status 404")
            }
        } catch {
            XCTFail("Expected NetworkError")
        }
    }
    
    func testDecodeError() async {
        // Given
        let invalidJSON = Data("invalid json".utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/users/123")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockHTTPClient.mockResponse = (invalidJSON, response)
        
        // When/Then
        do {
            let _: GetUser.UserDTO = try await client.send(GetUser(id: "123"))
            XCTFail("Expected NetworkError.decode")
        } catch let error as NetworkError {
            if case .decode = error {
                // Expected
            } else {
                XCTFail("Expected decode error")
            }
        } catch {
            XCTFail("Expected NetworkError")
        }
    }
}

// MARK: - Mock HTTP Client
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var mockResponse: (Data, URLResponse)?
    var mockError: Error?
    
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse else {
            throw NetworkError.unknown(NSError(domain: "MockError", code: -1))
        }
        
        return response
    }
}
