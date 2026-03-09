//
//  ETagMiddleware.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

/// Middleware that implements ETag-based cache revalidation
public final class ETagMiddleware: Middleware {
    private let cache: ETagCache
    
    public init(cache: ETagCache = InMemoryETagCache()) {
        self.cache = cache
    }
    
    public func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest {
        guard let url = request.url else { return request }
        
        // Only add If-None-Match for GET requests
        guard request.httpMethod == "GET" else { return request }
        
        if let etag = await cache.etag(for: url) {
            var modifiedRequest = request
            modifiedRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
            return modifiedRequest
        }
        
        return request
    }
    
    public func didReceive(_ result: Result<(Data, HTTPURLResponse), NetworkError>, for request: URLRequest) async {
        guard let url = request.url else { return }
        
        switch result {
        case .success((let data, let response)):
            // Store ETag from response
            if let etag = response.allHeaderFields["ETag"] as? String {
                await cache.store(etag: etag, for: url)
            }
            
            // Handle 304 Not Modified - serve from cache
            if response.statusCode == 304 {
                if let cachedData = await cache.cachedData(for: url) {
                    // Replace the empty data with cached data
                    // Note: This requires modifying the result, which isn't possible in current design
                    // In a real implementation, you'd need to modify the client to handle this
                }
            }
            
        case .failure:
            break
        }
    }
}

/// Protocol for ETag caching
public protocol ETagCache: Actor {
    func etag(for url: URL) async -> String?
    func store(etag: String, for url: URL) async
    func cachedData(for url: URL) async -> Data?
    func store(data: Data, for url: URL) async
}

/// In-memory implementation of ETagCache
public actor InMemoryETagCache: ETagCache {
    private var etags: [URL: String] = [:]
    private var cachedData: [URL: Data] = [:]

    public init() {

    }

    public func etag(for url: URL) async -> String? {
        return etags[url]
    }
    
    public func store(etag: String, for url: URL) async {
        etags[url] = etag
    }
    
    public func cachedData(for url: URL) async -> Data? {
        return cachedData[url]
    }
    
    public func store(data: Data, for url: URL) async {
        cachedData[url] = data
    }
}
