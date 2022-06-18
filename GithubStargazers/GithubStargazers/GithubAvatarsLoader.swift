//
//  GithubAvatarsLoader.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 18/06/22.
//

import Foundation

public final class GithubAvatarsLoader: AvatarsLoader {

    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func loadAvatar(from url: URL, completion: @escaping AvatarsLoader.Completion) {
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

    private func map(_ data: Data, and response: HTTPURLResponse) -> AvatarsLoader.Result {
        guard response.statusCode < 400 else {
            return .failure(Error.invalidData)
        }

        return .success(data)
    }

}
