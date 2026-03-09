//
//  LoggingMiddleware.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public final class LoggingMiddleware: Middleware {
    private let logger: Logger
    
    public init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    public func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest {
        logger.logRequest(request, level: .debug)
        return request
    }
    
    public func didReceive(_ result: Result<(Data, HTTPURLResponse), NetworkError>,
                           for request: URLRequest) async {
        switch result {
        case .success((let data, let response)):
            logger.logResponse(response, data: data, for: request, level: .debug)
        case .failure(let error):
            logger.logError(error, for: request, level: .error)
        }
    }
}
