//
//  GithubService_Tests.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 14/06/22.
//

import XCTest

protocol HTTPClient {}

final class GithubService {
    private let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }
}

class HTTPClientSpy: HTTPClient {
    private(set) var requestedUrls = [String]()
}

class GithubService_Tests: XCTestCase {

    func test_service_doesNotRequestUrlUponCreation() {
        let (client, _) = makeSUT()

        XCTAssertEqual([], client.requestedUrls, "expecting sut not to perform any requests upon creation")
    }

    // MARK: - Helpers

    private func makeSUT() -> (client: HTTPClientSpy, sut: GithubService) {
        let client = HTTPClientSpy()
        let sut = GithubService(client)

        return (client, sut)
    }

}
