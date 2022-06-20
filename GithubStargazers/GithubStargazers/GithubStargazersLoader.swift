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


    public func loadStargazers(forUser user: String, withRepo repo: String, page: Int = 1, completion: @escaping StargazersLoader.Completion) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.github.com"
        urlComponents.path = "/repos/\(user)/\(repo)/stargazers"
        urlComponents.queryItems = [URLQueryItem(name: "page", value: "\(page)")]
        let url = URL(string: urlComponents.string!)!
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
                isLast: isLastPage(response),
                stargazers: json.map { Stargazer(login: $0.login, avatarURL: $0.avatar_url) }
            ))
    }

    private func isLastPage(_ response: HTTPURLResponse) -> Bool {
        guard let linkHeaders = response.allHeaderFields["Link"] as? String else {
            return true
        }

        return !linkHeaders.contains("rel=\"last\"")
    }
}
