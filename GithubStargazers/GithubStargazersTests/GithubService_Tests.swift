//
//  GithubService_Tests.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 14/06/22.
//

import XCTest
import GithubStargazers

final class GithubService {

    typealias Result = Swift.Result<String, GithubService.Error>
    typealias Completion = (Result) -> Void

    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private struct Response: Decodable {}

    private let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
        let url = URL(string: "https://api.github.com/repos/")!
            .appendingPathComponent(user)
            .appendingPathComponent(repo)
            .appendingPathComponent("stargazers")
        let headers = ("Accept", "application/vnd.github.v3+json")

        client.get(url: url, headers: headers) { result in
            switch result {

            case let .success((data, response)):
                completion(self.map(data, and: response))

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }

    private func map(_ data: Data, and response: HTTPURLResponse) -> GithubService.Result {
        guard
            response.statusCode == 200,
            let _ = try? JSONDecoder().decode(Response.self, from: data)
        else {
            return .failure(.invalidData)
        }
        return .success("")
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

        sut.loadStargazers(forUser: user, withRepo: repo) { _ in }
        sut.loadStargazers(forUser: otherUser, withRepo: otherRepo) { _ in }

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

        sut.loadStargazers(forUser: user, withRepo: repo) { _ in }

        XCTAssertEqual(
            ["https://api.github.com/repos/\(user)/\(repo)/stargazers".replacingOccurrences(of: " ", with: "%20")],
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

        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let error = NSError(domain: "Error", code: -1)
            client.complete(with: error)
        }
    }

    func test_loadStargazers_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (client, sut) = makeSUT()

        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                let json = makeStargazersJSON()
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_loadStargazers_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (client, sut) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    // MARK: - Helpers

    private func makeSUT() -> (client: HTTPClientSpy, sut: GithubService) {
        let client = HTTPClientSpy()
        let sut = GithubService(client)

        return (client, sut)
    }

    private func makeStargazersJSON() -> Data {
        let json = [String]()
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ sut: GithubService, toCompleteWith expectedResult: GithubService.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for client to complete")

        sut.loadStargazers(forUser: "user", withRepo: "repo") { receivedResult in
            switch (receivedResult, expectedResult) {

            case let (.failure(receivedError), .failure(expectedError)):
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
