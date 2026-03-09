//
//  Endpoint.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

/// Marker type for endpoints that expect no response body (e.g., 204 No Content)
public struct EmptyResponse: Decodable {
    public init() {}
}

public protocol Endpoint {
    associatedtype Response: Decodable
    var method: HTTPMethod { get }
    var path: String { get }
    var query: [URLQueryItem] { get }
    var headers: Headers { get }
    var body: Data? { get }
    var requiresAuth: Bool { get }
    var cachePolicy: CachePolicy { get }
    var decoder: JSONDecoder? { get }
}

// MARK: - Default Implementations
public extension Endpoint {
    var query: [URLQueryItem] { [] }
    var headers: Headers { ["Accept": "application/json"] }
    var body: Data? { nil }
    var requiresAuth: Bool { false }
    var cachePolicy: CachePolicy { .useURLCache }
    var decoder: JSONDecoder? { nil }
}
