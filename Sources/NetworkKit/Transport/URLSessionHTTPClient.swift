//
//  URLSessionHTTPClient.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public final class URLSessionHTTPClient: NSObject, HTTPClient {
    private let session: URLSession
    public init(configuration: URLSessionConfiguration = .default) {
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024
        )
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }

    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, resp) = try await session.data(for: request)
            return (data, resp)
        } catch let e as URLError {
            if e.code == .timedOut { throw NetworkError.timeout }
            if e.code == .cancelled { throw NetworkError.cancelled }
            throw NetworkError.transport(e)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
