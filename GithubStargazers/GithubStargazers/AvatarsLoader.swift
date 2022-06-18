//
//  AvatarsLoader.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 18/06/22.
//

import Foundation

public protocol AvatarsLoader {
    func loadAvatar(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}
