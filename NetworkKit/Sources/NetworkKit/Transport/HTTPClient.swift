//
//  HTTPClient.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public protocol HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
