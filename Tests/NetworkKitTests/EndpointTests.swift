//
//  EndpointTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class EndpointTests: XCTestCase {
    
    func testDefaultImplementations() {
        // Given
        struct TestEndpoint: Endpoint {
            typealias Response = EmptyResponse
            var method: HTTPMethod { .GET }
            var path: String { "/test" }
        }
        
        let endpoint = TestEndpoint()
        
        // When/Then
        XCTAssertTrue(endpoint.query.isEmpty)
        XCTAssertEqual(endpoint.headers["Accept"], "application/json")
        XCTAssertNil(endpoint.body)
        XCTAssertFalse(endpoint.requiresAuth)
        XCTAssertEqual(endpoint.cachePolicy, .useURLCache)
        XCTAssertNil(endpoint.decoder)
    }
    
    func testCustomImplementations() {
        // Given
        struct CustomEndpoint: Endpoint {
            typealias Response = EmptyResponse
            var method: HTTPMethod { .POST }
            var path: String { "/custom" }
            var query: [URLQueryItem] { [URLQueryItem(name: "test", value: "value")] }
            var headers: Headers { ["Custom-Header": "custom-value"] }
            var body: Data? { Data("test body".utf8) }
            var requiresAuth: Bool { true }
            var cachePolicy: CachePolicy { .reloadIgnoringCache }
            var decoder: JSONDecoder? { JSONDecoder() }
        }
        
        let endpoint = CustomEndpoint()
        
        // When/Then
        XCTAssertEqual(endpoint.query.count, 1)
        XCTAssertEqual(endpoint.query.first?.name, "test")
        XCTAssertEqual(endpoint.query.first?.value, "value")
        XCTAssertEqual(endpoint.headers["Custom-Header"], "custom-value")
        XCTAssertNotNil(endpoint.body)
        XCTAssertTrue(endpoint.requiresAuth)
        XCTAssertEqual(endpoint.cachePolicy, .reloadIgnoringCache)
        XCTAssertNotNil(endpoint.decoder)
    }
    
    func testEmptyResponse() {
        // Given
        let emptyResponse = EmptyResponse()
        
        // When/Then
        XCTAssertNotNil(emptyResponse)
    }
}
