//
//  GithubService_Tests.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 14/06/22.
//

import XCTest
import GithubStargazers

final class GithubStargazersLoader_Tests: XCTestCase {

    func test_loader_doesNotRequestUrlUponCreation() {
        let (client, _) = makeSUT()

        XCTAssertEqual([], client.requestedUrls, "expecting sut not to perform any requests upon creation")
    }

    func test_loadStargazers_requestCorrectUrlEveryTimeIsInvoked() {
        let user = "a-user"
        let repo = "a-repo"
        let otherUser = "other-user"
        let otherRepo = "other-repo"
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: user, withRepo: repo, page: 1) { _ in }
        sut.loadStargazers(forUser: otherUser, withRepo: otherRepo, page: 2) { _ in }

        XCTAssertEqual(
            [
                "https://api.github.com/repos/\(user)/\(repo)/stargazers?page=1",
                "https://api.github.com/repos/\(otherUser)/\(otherRepo)/stargazers?page=2"
            ],
            client.requestedUrls,
            "expecting sut to hit github endpoint every time loadStargazers is invoked"
        )
    }

    func test_loadStargazers_requestCorrectEscapedUrl() {
        let user = "a user"
        let repo = "a repo"
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: user, withRepo: repo, page: 1) { _ in }

        XCTAssertEqual(
            ["https://api.github.com/repos/\(user)/\(repo)/stargazers?page=1".replacingOccurrences(of: " ", with: "%20")],
            client.requestedUrls,
            "expecting sut to hit github endpoint escaping spaces and special chars"
        )
    }

    func test_loadStargazers_passTheCorrectHttpHeadersToTheClient() {
        let (client, sut) = makeSUT()

        sut.loadStargazers(forUser: "a-user", withRepo: "a-repo") { _ in }

        let (receivedHeaderField, receivedHeaderValue) = client.requestedHeader
        XCTAssertEqual("Accept", receivedHeaderField)
        XCTAssertEqual("application/vnd.github.v3+json", receivedHeaderValue)
    }

    func test_loadStargazers_deliversConnectivityErrorOnClientError() {
        let (client, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(GithubStargazersLoader.Error.connectivity)) {
            let error = NSError(domain: "Error", code: -1)
            client.complete(with: error)
        }
    }

    func test_loadStargazers_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (client, sut) = makeSUT()

        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(GithubStargazersLoader.Error.invalidData), when: {
                let json = makeStargazersJSON()
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_loadStargazers_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (client, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(GithubStargazersLoader.Error.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_loadStargazers_deliversSuccessWithStargazersAndMorePagesToFetchOn200HTTPResponseWithJSONStargazers() {
        let (client, sut) = makeSUT()
        let s1 = makeStargazer(login: "login-1", avatarURL: URL(string: "http://avatar-1.com")!)
        let s2 = makeStargazer(login: "login-2", avatarURL: URL(string: "http://avatar-2.com")!)
        let headers = ["link": "<http://any-url.com>; rel=\"next\", <http://any-url.com>; rel=\"last\""]

        expect(sut, toCompleteWith: .success(StargazersPage(isLast: false, stargazers: [s1.stargazer, s2.stargazer]))) {
            let json = makeStargazersJSON([s1.json, s2.json])
            client.complete(withStatusCode: 200, data: json, headers: headers)
        }
    }

    func test_loadStargazers_deliversSuccessWithoutStargazersOn200HTTPResponseWithEmptyJSON() {
        let (client, sut) = makeSUT()

        expect(sut, toCompleteWith: .success(StargazersPage(isLast: true, stargazers: []))) {
            let json = makeStargazersJSON([])
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_loadStargazers_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: GithubStargazersLoader? = GithubStargazersLoader(client)

        var capturedResults = [GithubStargazersLoader.Result]()
        sut?.loadStargazers(forUser: "a-user", withRepo: "a-repo") { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeStargazersJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (client: HTTPClientSpy, sut: GithubStargazersLoader) {
        let client = HTTPClientSpy()
        let sut = GithubStargazersLoader(client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (client, sut)
    }

    private func makeStargazer(login: String, avatarURL: URL) -> (stargazer: Stargazer, json: [String: Any]) {
        let item = Stargazer(login: login, avatarURL: avatarURL)

        let json = [
            "login": login,
            "avatar_url": avatarURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeStargazersJSON(_ stargazers: [[String: Any]] = []) -> Data {
        return try! JSONSerialization.data(withJSONObject: stargazers)
    }

    private func expect(_ sut: GithubStargazersLoader, toCompleteWith expectedResult: GithubStargazersLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for client to complete")

        sut.loadStargazers(forUser: "user", withRepo: "repo") { receivedResult in
            switch (receivedResult, expectedResult) {

            case let (.success(receivedPage), .success(expectedPage)):
                XCTAssertEqual(receivedPage.isLast, expectedPage.isLast, "expected isLast page to be \(expectedPage.isLast), got \(receivedPage.isLast) instead", file: file, line: line)
                XCTAssertEqual(receivedPage.stargazers, expectedPage.stargazers, "expected page with \(expectedPage.stargazers) stargazers, got \(receivedPage.stargazers) instead", file: file, line: line)

            case let (.failure(receivedError as GithubStargazersLoader.Error), .failure(expectedError as GithubStargazersLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 0.1)
    }

}
