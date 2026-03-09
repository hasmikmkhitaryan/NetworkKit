//
//  RetryMiddleware.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public final class RetryMiddleware: Middleware {
    public enum Policy: Sendable {
        case never
        case limited(Int)
    }

    private let policy: Policy
    private let backoff: @Sendable (Int) -> UInt64 // nanoseconds
    private weak let tokenProvider: TokenProvider?

    public init(policy: Policy = .limited(2),
                tokenProvider: TokenProvider? = nil,
                backoff: @escaping @Sendable (Int) -> UInt64 = { attempt in
                    let base = UInt64(200_000_000) << attempt // 0.2s, 0.4s, 0.8s...
                    return base + UInt64.random(in: 0..<100_000_000)
                }) {
        self.policy = policy
        self.tokenProvider = tokenProvider
        self.backoff = backoff
    }

    public func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest { request }

    public func didReceive(_ result: Result<(Data, HTTPURLResponse), NetworkError>,
                           for request: URLRequest) async { /* passive */ }

    public func retryAdvice(response: HTTPURLResponse?, error: NetworkError, request: URLRequest, attempt: Int) async -> (shouldRetry: Bool, newRequest: URLRequest?) {
        switch policy {
        case .never:
            return (false, nil)
        case .limited(let max):
            guard attempt < max else { return (false, nil) }
        }
        if let resp = response, resp.statusCode == 401, let provider = tokenProvider {
            do {
                let newToken = try await provider.refreshToken()
                var r = request
                r.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                return (true, r)
            } catch { return (false, nil) }
        }
        switch error {
        case .timeout, .transport: return (true, request)
        case .server(let code, _ ) where (500...599).contains(code): return (true, request)
        default: return (false, nil)
        }
    }

    public func sleep(attempt: Int) async {
        try? await Task.sleep(nanoseconds: backoff(attempt))
    }
}
