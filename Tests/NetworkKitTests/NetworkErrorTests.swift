//
//  NetworkErrorTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class NetworkErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        // Given/When/Then
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(NetworkError.timeout.errorDescription, "Request timed out")
        XCTAssertEqual(NetworkError.cancelled.errorDescription, "Request was cancelled")
        
        let transportError = NetworkError.transport(URLError(.notConnectedToInternet))
        XCTAssertTrue(transportError.errorDescription?.contains("Network transport error") == true)
        
        let serverError = NetworkError.server(status: 404, data: nil)
        XCTAssertEqual(serverError.errorDescription, "Server error with status code: 404")
        
        let decodeError = NetworkError.decode(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test")), data: nil)
        XCTAssertTrue(decodeError.errorDescription?.contains("Failed to decode response") == true)
        
        let encodeError = NetworkError.encode(EncodingError.invalidValue("test", .init(codingPath: [], debugDescription: "test")))
        XCTAssertTrue(encodeError.errorDescription?.contains("Failed to encode request") == true)
        
        let unknownError = NetworkError.unknown(NSError(domain: "Test", code: 1))
        XCTAssertTrue(unknownError.errorDescription?.contains("Unknown error") == true)
    }
    
    func testFailureReasons() {
        // Given
        let errorData = Data("Server error message".utf8)
        let serverError = NetworkError.server(status: 500, data: errorData)
        
        // When/Then
        XCTAssertEqual(serverError.failureReason, "Server error message")
        
        let decodeData = Data("Invalid JSON".utf8)
        let decodeError = NetworkError.decode(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test")), data: decodeData)
        XCTAssertEqual(decodeError.failureReason, "Response data: Invalid JSON")
    }
    
    func testRecoverySuggestions() {
        // Given/When/Then
        XCTAssertEqual(NetworkError.timeout.recoverySuggestion, "Check your internet connection and try again")
        XCTAssertEqual(NetworkError.transport(URLError(.notConnectedToInternet)).recoverySuggestion, "Check your internet connection and try again")
        
        XCTAssertEqual(NetworkError.server(status: 401, data: nil).recoverySuggestion, "Please log in again")
        XCTAssertEqual(NetworkError.server(status: 403, data: nil).recoverySuggestion, "You don't have permission to access this resource")
        XCTAssertEqual(NetworkError.server(status: 404, data: nil).recoverySuggestion, "The requested resource was not found")
        XCTAssertEqual(NetworkError.server(status: 500, data: nil).recoverySuggestion, "Server error. Please try again later")
        XCTAssertEqual(NetworkError.server(status: 400, data: nil).recoverySuggestion, "Please try again")
        
        XCTAssertEqual(NetworkError.invalidURL.recoverySuggestion, "Please try again")
    }
}
