//
//  CachePolicy.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public enum CachePolicy {
    case useURLCache
    case reloadIgnoringCache
    case revalidate // ETag/If-None-Match via middleware
}
