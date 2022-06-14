//
//  HTTPClient.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public protocol HTTPClient {
    typealias HTTPHeader = (headerField: String, headerValue: String)
    func get(url: URL, headers: HTTPHeader)
}
