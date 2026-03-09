//
//  JSONCoder.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public enum JSONCoder {
    public static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        if #available(iOS 15.0, macOS 12.0, *) {
            d.dateDecodingStrategy = .iso8601
        }
        return d
    }()
    public static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 15.0, macOS 12.0, *) {
            e.dateEncodingStrategy = .iso8601
        }
        return e
    }()
}
