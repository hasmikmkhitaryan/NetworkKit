//
//  Logger.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

/// Protocol for logging network requests and responses
public protocol Logger {
    func logRequest(_ request: URLRequest, level: LogLevel)
    func logResponse(_ response: HTTPURLResponse, data: Data?, for request: URLRequest, level: LogLevel)
    func logError(_ error: NetworkError, for request: URLRequest, level: LogLevel)
}

public enum LogLevel {
    case debug, info, warning, error
}

/// Default console logger with redaction capabilities
public struct ConsoleLogger: Logger {
    private let redactor: HeaderRedactor
    private let minLevel: LogLevel
    
    public init(redactor: HeaderRedactor = DefaultHeaderRedactor(), minLevel: LogLevel = .debug) {
        self.redactor = redactor
        self.minLevel = minLevel
    }
    
    public func logRequest(_ request: URLRequest, level: LogLevel) {
        guard shouldLog(level) else { return }
        
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        let headers = redactor.redact(request.allHTTPHeaderFields ?? [:])
        
        print("🌐 [REQUEST] \(method) \(url)")
        if !headers.isEmpty {
            print("📋 [HEADERS] \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 [BODY] \(bodyString)")
        }
    }
    
    public func logResponse(_ response: HTTPURLResponse, data: Data?, for request: URLRequest, level: LogLevel) {
        guard shouldLog(level) else { return }
        
        let status = response.statusCode
        let url = request.url?.absoluteString ?? "nil"
        let emoji = (200..<300).contains(status) ? "✅" : "⚠️"
        
        print("\(emoji) [RESPONSE] \(status) \(url)")
        
        if let data = data, !data.isEmpty {
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                print("📦 [RESPONSE_BODY] \(truncated)")
            }
        }
    }
    
    public func logError(_ error: NetworkError, for request: URLRequest, level: LogLevel) {
        guard shouldLog(level) else { return }
        
        let url = request.url?.absoluteString ?? "nil"
        print("❌ [ERROR] \(error.localizedDescription) \(url)")
    }
    
    private func shouldLog(_ level: LogLevel) -> Bool {
        switch (minLevel, level) {
        case (.debug, _): return true
        case (.info, .info), (.info, .warning), (.info, .error): return true
        case (.warning, .warning), (.warning, .error): return true
        case (.error, .error): return true
        default: return false
        }
    }
}

/// Protocol for redacting sensitive headers
public protocol HeaderRedactor {
    func redact(_ headers: [String: String]) -> [String: String]
}

/// Default implementation that redacts common sensitive headers
public struct DefaultHeaderRedactor: HeaderRedactor {
    private let sensitiveHeaders = Set([
        "authorization", "x-api-key", "x-auth-token", "cookie", "set-cookie"
    ])
    
    public func redact(_ headers: [String: String]) -> [String: String] {
        let redactedHeaders = Dictionary(uniqueKeysWithValues: headers.map { (key, value) in
            if sensitiveHeaders.contains(key.lowercased()) {
                return (key, "[REDACTED]")
            } else {
                return (key, value)
            }
        })
        return redactedHeaders
    }

    public init() {}
}
