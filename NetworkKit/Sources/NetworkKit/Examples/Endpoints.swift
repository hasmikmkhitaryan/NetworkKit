//
//  Endpoints.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public struct GetUser: Endpoint {
    public struct UserDTO: Codable, Equatable { public let id: String; public let name: String }
    public typealias Response = UserDTO
    public let id: String
    public init(id: String) { self.id = id }
    public var method: HTTPMethod { .GET }
    public var path: String { "/users/\(id)" }
    public var requiresAuth: Bool { true }
    public var cachePolicy: CachePolicy { .revalidate }
}

public struct CreatePost: Endpoint {
    public struct Body: Encodable { public let text: String }
    public struct PostDTO: Decodable, Equatable { public let id: String; public let text: String }
    public typealias Response = PostDTO
    public let payload: Body
    public init(payload: Body) { self.payload = payload }
    public var method: HTTPMethod { .POST }
    public var path: String { "/posts" }
    public var headers: Headers { ["Content-Type": "application/json"] }
    public var body: Data? { try? JSONCoder.encoder.encode(payload) }
    public var requiresAuth: Bool { true }
    public var cachePolicy: CachePolicy { .reloadIgnoringCache }
}

// Example of an endpoint that returns no content
public struct DeletePost: Endpoint {
    public typealias Response = EmptyResponse
    public let id: String
    public init(id: String) { self.id = id }
    public var method: HTTPMethod { .DELETE }
    public var path: String { "/posts/\(id)" }
    public var requiresAuth: Bool { true }
    public var cachePolicy: CachePolicy { .reloadIgnoringCache }
}
