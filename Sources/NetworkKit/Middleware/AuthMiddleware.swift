//
//  AuthMiddleware.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public protocol TokenProvider: AnyObject, Sendable {
    var accessToken: String? { get }
    func refreshToken() async throws -> String
}

public final class AuthMiddleware: Middleware {
    private weak let tokenProvider: TokenProvider?
    public init(tokenProvider: TokenProvider?) { self.tokenProvider = tokenProvider }

    public func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest {
        guard requiresAuth, let token = tokenProvider?.accessToken else { return request }
        var r = request
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }

    public func didReceive(_ result: Result<(Data, HTTPURLResponse), NetworkError>,
                           for request: URLRequest) async { /* no-op */ }
}
