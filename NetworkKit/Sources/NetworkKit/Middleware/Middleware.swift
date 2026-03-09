//
//  Middleware.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public protocol Middleware {
    func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest
    func didReceive(_ result: Result<(Data, HTTPURLResponse), NetworkError>,
                    for request: URLRequest) async
}
