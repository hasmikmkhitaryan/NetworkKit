//
//  LoggerTests.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import XCTest
@testable import NetworkKit
import Foundation

final class LoggerTests: XCTestCase {
    
    func testConsoleLoggerLogLevels() {
        // Given
        let debugLogger = ConsoleLogger(minLevel: .debug)
        let infoLogger = ConsoleLogger(minLevel: .info)
        let warningLogger = ConsoleLogger(minLevel: .warning)
        let errorLogger = ConsoleLogger(minLevel: .error)
        
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        
        // When/Then - Debug level should log everything
        debugLogger.logRequest(request, level: .debug)
        debugLogger.logRequest(request, level: .info)
        debugLogger.logRequest(request, level: .warning)
        debugLogger.logRequest(request, level: .error)
        
        // When/Then - Info level should log info, warning, error
        infoLogger.logRequest(request, level: .debug) // Should not log
        infoLogger.logRequest(request, level: .info)
        infoLogger.logRequest(request, level: .warning)
        infoLogger.logRequest(request, level: .error)
        
        // When/Then - Warning level should log warning, error
        warningLogger.logRequest(request, level: .debug) // Should not log
        warningLogger.logRequest(request, level: .info) // Should not log
        warningLogger.logRequest(request, level: .warning)
        warningLogger.logRequest(request, level: .error)
        
        // When/Then - Error level should log only error
        errorLogger.logRequest(request, level: .debug) // Should not log
        errorLogger.logRequest(request, level: .info) // Should not log
        errorLogger.logRequest(request, level: .warning) // Should not log
        errorLogger.logRequest(request, level: .error)
    }
    
    func testHeaderRedactor() {
        // Given
        let redactor = DefaultHeaderRedactor()
        let headers = [
            "Authorization": "Bearer token123",
            "Content-Type": "application/json",
            "X-API-Key": "secret-key",
            "Accept": "application/json"
        ]
        
        // When
        let redacted = redactor.redact(headers)
        
        // Then
        XCTAssertEqual(redacted["Authorization"], "[REDACTED]")
        XCTAssertEqual(redacted["X-API-Key"], "[REDACTED]")
        XCTAssertEqual(redacted["Content-Type"], "application/json")
        XCTAssertEqual(redacted["Accept"], "application/json")
    }
    
    func testHeaderRedactorCaseInsensitive() {
        // Given
        let redactor = DefaultHeaderRedactor()
        let headers = [
            "AUTHORIZATION": "Bearer token123",
            "content-type": "application/json",
            "X-Auth-Token": "secret-token"
        ]
        
        // When
        let redacted = redactor.redact(headers)
        
        // Then
        XCTAssertEqual(redacted["AUTHORIZATION"], "[REDACTED]")
        XCTAssertEqual(redacted["content-type"], "application/json")
        XCTAssertEqual(redacted["X-Auth-Token"], "[REDACTED]")
    }
}
