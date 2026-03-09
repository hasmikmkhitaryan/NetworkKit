//
//  NetworkClient.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public protocol NetworkClient {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
    func sendRaw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
