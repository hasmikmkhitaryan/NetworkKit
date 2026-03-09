//
//  Wiring.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public final class AppTokenProvider: TokenProvider {
    public init() {}
    public private(set) var accessToken: String?
    public func refreshToken() async throws -> String {
        let new = "newAccessToken"
        self.accessToken = new
        return new
    }
}

public func makeDefaultClient(baseURL: URL) -> DefaultNetworkClient {
    let builder = RequestBuilder(baseURL: baseURL)
    let http = URLSessionHTTPClient()
    let tokenProvider = AppTokenProvider()
    return DefaultNetworkClient(
        http: http,
        builder: builder,
        middlewares: [
            LoggingMiddleware(),
            ETagMiddleware(),
            AuthMiddleware(tokenProvider: tokenProvider),
            RetryMiddleware(policy: .limited(3), tokenProvider: tokenProvider)
        ])
}
