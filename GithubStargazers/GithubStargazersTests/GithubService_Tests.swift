//
//  GithubService_Tests.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 14/06/22.
//

import XCTest

protocol HTTPClient {
    func get(url: URL)
}

final class GithubService {
    private let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }

    func loadStargazers(forUser user: String, withRepo repo: String) {
        let url = URL(string: "https://api.github.com/repos/\(user)/\(repo)/stargazers")

        client.get(url: url!)
    }
}

class HTTPClientSpy: HTTPClient {
    private(set) var requestedUrls = [URL]()

    func get(url: URL) {
        requestedUrls.append(url)
    }
}

class GithubService_Tests: XCTestCase {

    func test_service_doesNotRequestUrlUponCreation() {
        let (client, _) = makeSUT()

        XCTAssertEqual([], client.requestedUrls, "expecting sut not to perform any requests upon creation")
    }

    func test_loadStargazers_requestCorrectUrlEveryTimeIsInvoked() {
        let user = "a-user"
        let repo = "a-repo"
        let otherUser = "other-user"
        let otherRepo = "other-repo"
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: user, withRepo: repo)
        sut.loadStargazers(forUser: otherUser, withRepo: otherRepo)

        XCTAssertEqual(
            [
                URL(string: "https://api.github.com/repos/\(user)/\(repo)/stargazers"),
                URL(string: "https://api.github.com/repos/\(otherUser)/\(otherRepo)/stargazers")
            ],
            client.requestedUrls,
            "expecting sut to hit github endpoint every time loadStargazers is invoked"
        )
    }

    // MARK: - Helpers

    private func makeSUT() -> (client: HTTPClientSpy, sut: GithubService) {
        let client = HTTPClientSpy()
        let sut = GithubService(client)

        return (client, sut)
    }

}
