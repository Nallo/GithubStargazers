//
//  GithubService_Tests.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 14/06/22.
//

import XCTest
import GithubStargazers

final class GithubService {
    private let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }

    func loadStargazers(forUser user: String, withRepo repo: String) {
        let url = URL(string: "https://api.github.com/repos/")!
            .appendingPathComponent(user)
            .appendingPathComponent(repo)
            .appendingPathComponent("stargazers")
        let headers = ("Accept", "application/vnd.github.v3+json")

        client.get(url: url, headers: headers) { _ in }
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
                "https://api.github.com/repos/\(user)/\(repo)/stargazers",
                "https://api.github.com/repos/\(otherUser)/\(otherRepo)/stargazers"
            ],
            client.requestedUrls,
            "expecting sut to hit github endpoint every time loadStargazers is invoked"
        )
    }

    func test_loadStargazers_requestCorrectEscapedUrl() {
        let user = "a user"
        let repo = "a repo"
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: user, withRepo: repo)

        XCTAssertEqual(
            ["https://api.github.com/repos/\(user)/\(repo)/stargazers".replacingOccurrences(of: " ", with: "%20")],
            client.requestedUrls,
            "expecting sut to hit github endpoint escaping spaces and special chars"
        )
    }

    func test_loadStargazers_passTheCorrectHttpHeadersToTheClient() {
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: "a-user", withRepo: "a-repo")

        let (receivedHeaderField, receivedHeaderValue) = client.requestedHeader
        XCTAssertEqual("Accept", receivedHeaderField)
        XCTAssertEqual("application/vnd.github.v3+json", receivedHeaderValue)
    }

//    func test_loadStargazers_deliversConnectivityErrorOnClientError() {
//        let clientError = NSError(domain: "Error", code: -1)
//        let (client, sut) = makeSUT()
//
//        sut.loadStargazers(forUser: "user", withRepo: "repo")
//        client.complete(with: clientError)
//    }

    // MARK: - Helpers

    private func makeSUT() -> (client: HTTPClientSpy, sut: GithubService) {
        let client = HTTPClientSpy()
        let sut = GithubService(client)

        return (client, sut)
    }

}
