//
//  Stargazer.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public struct Stargazer: Hashable {
    public let login: String
    public let avatarURL: URL

    public init(login: String, avatarURL: URL) {
        self.login = login
        self.avatarURL = avatarURL
    }
}
