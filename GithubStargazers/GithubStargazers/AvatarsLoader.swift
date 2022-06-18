//
//  AvatarsLoader.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 18/06/22.
//

import Foundation

public protocol AvatarsLoader {
    typealias Result = Swift.Result<Data, Error>
    typealias Completion = (Result) -> Void

    func loadAvatar(from url: URL, completion: @escaping Completion)
}
