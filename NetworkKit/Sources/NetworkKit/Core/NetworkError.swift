//
//  NetworkError.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public enum NetworkError: Error, CustomNSError, LocalizedError {
    case invalidURL
    case transport(URLError)
    case timeout
    case cancelled
    case server(status: Int, data: Data?)
    case decode(Error, data: Data?)
    case encode(Error)
    case unknown(Error)
    
    public static var errorDomain: String { "NetworkKit.NetworkError" }
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .transport(let error):
            return "Network transport error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .server(let status, _):
            return "Server error with status code: \(status)"
        case .decode(let error, _):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encode(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .server(let status, let data):
            if let data = data, let message = String(data: data, encoding: .utf8) {
                return message
            }
            return "HTTP \(status)"
        case .decode(_, let data):
            if let data = data, let message = String(data: data, encoding: .utf8) {
                return "Response data: \(message)"
            }
            return nil
        default:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .timeout:
            return "Check your internet connection and try again"
        case .server(let status, _):
            switch status {
            case 401:
                return "Please log in again"
            case 403:
                return "You don't have permission to access this resource"
            case 404:
                return "The requested resource was not found"
            case 500...599:
                return "Server error. Please try again later"
            default:
                return "Please try again"
            }
        case .transport:
            return "Check your internet connection and try again"
        default:
            return "Please try again"
        }
    }
}
