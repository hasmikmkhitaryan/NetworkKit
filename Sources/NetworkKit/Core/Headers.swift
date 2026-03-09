//
//  Headers.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public struct Headers: ExpressibleByDictionaryLiteral {
    public private(set) var storage: [String: String] = [:]
    public init(dictionaryLiteral elements: (String, String)...) {
        for (k, v) in elements { storage[k] = v }
    }
    public subscript(_ key: String) -> String? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
}
