//
//  WikiModel.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import Foundation

struct WikiApiResponse: Codable {
    let query: WikiQuery
}

struct WikiQuery: Codable {
    let pages: [String: WikiPage]
}

struct WikiPage: Codable {
    let extract: String
}
