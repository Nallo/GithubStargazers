//
//  Stargazer.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public struct StargazersPage: Hashable {
    public let isLast: Bool
    public let stargazers: [Stargazer]

    public init(isLast: Bool, stargazers: [Stargazer]) {
        self.isLast = isLast
        self.stargazers = stargazers
    }
}

public struct Stargazer: Hashable {
    public let login: String
    public let avatarURL: URL

    public init(login: String, avatarURL: URL) {
        self.login = login
        self.avatarURL = avatarURL
    }
}
