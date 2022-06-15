//
//  HTTPClient.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    typealias HTTPHeader = (headerField: String, headerValue: String)

    func get(url: URL, headers: HTTPHeader, completion: @escaping (Result) -> Void)
}
