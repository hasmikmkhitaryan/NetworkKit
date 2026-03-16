//
//  RequestBuilder.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public struct RequestBuilder: Sendable {
    public let baseURL: URL
    public init(baseURL: URL) { self.baseURL = baseURL }

    public func makeRequest<E: Endpoint>(_ endpoint: E) throws -> URLRequest {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(endpoint.path),
                                        resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        comps.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
        guard let url = comps.url else { throw NetworkError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        req.httpBody = endpoint.body
        endpoint.headers.storage.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        switch endpoint.cachePolicy {
        case .useURLCache: req.cachePolicy = .useProtocolCachePolicy
        case .reloadIgnoringCache: req.cachePolicy = .reloadIgnoringLocalCacheData
        case .revalidate: req.cachePolicy = .useProtocolCachePolicy // handled via middleware
        }
        return req
    }
}
