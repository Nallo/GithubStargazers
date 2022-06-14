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
    private(set) var requestedUrls = [URL]()
}

class GithubService_Tests: XCTestCase {

    func test_load_doesNotRequestUrlUponCreation() {
        let client = HTTPClientSpy()
        let _ = GithubService(client)

        XCTAssertEqual([], client.requestedUrls, "expecting sut not to perform any requests upon creation")
    }

}
