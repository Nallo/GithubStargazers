//
//  GithubService.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public final class GithubStargazersLoader: StargazersLoader {

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private struct Response: Decodable {
        let login: String
        let avatar_url: URL
    }

    private let client: HTTPClient

    public init(_ client: HTTPClient) {
        self.client = client
    }

    public func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping StargazersLoader.Completion) {
        let url = URL(string: "https://api.github.com/repos/")!
            .appendingPathComponent(user)
            .appendingPathComponent(repo)
            .appendingPathComponent("stargazers")
        let headers = ("Accept", "application/vnd.github.v3+json")

        client.get(url: url, headers: headers) { [weak self] result in
            guard let self = self else { return }

            switch result {

            case let .success((data, response)):
                completion(self.map(data, and: response))

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    private func map(_ data: Data, and response: HTTPURLResponse) -> GithubStargazersLoader.Result {
        guard
            response.statusCode == 200,
            let json = try? JSONDecoder().decode([Response].self, from: data)
        else {
            return .failure(Error.invalidData)
        }

        return .success(
            StargazersPage(
                page: 1,
                isLast: true,
                stargazers: json.map { Stargazer(login: $0.login, avatarURL: $0.avatar_url) }
            ))
    }
}
