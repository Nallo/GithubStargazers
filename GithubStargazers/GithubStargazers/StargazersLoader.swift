//
//  StargazersLoader.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 17/06/22.
//

import Foundation

public protocol StargazersLoader {
    typealias Result = Swift.Result<StargazersPage, Error>
    typealias Completion = (Result) -> Void

    func loadStargazers(forUser user: String, withRepo repo: String, page: Int, completion: @escaping Completion)
}
