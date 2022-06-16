//
//  GithubStargazersEnd2EndTests.swift
//  GithubStargazersEnd2EndTests
//
//  Created by Stefano Martinallo on 16/06/22.
//

import XCTest
import GithubStargazers

class GithubStargazersEnd2EndTests: XCTestCase {

    func test_URLSessionHTTPClient_completesWithGivenStatusCode() {
        let baseURL = URL(string: "https://httpbin.org/status")!
        let session = URLSession(configuration: .ephemeral)
        let sut = URLSessionHTTPClient(session: session)

        let samples = [200, 300, 400, 500]
        let exp = expectation(description: "wait for client completion")
        exp.expectedFulfillmentCount = samples.count

        for sample in samples {
            let url = baseURL.appendingPathComponent("\(sample)")
            let headers = ("accept", "text/plain")

            sut.get(url: url, headers: headers) { result in
                if let (_, httpResponse) = try? result.get() {
                    XCTAssertEqual(sample, httpResponse.statusCode, "expected status code \(sample), got \(httpResponse.statusCode) instead")
                } else {
                    XCTFail("expected status code \(sample), when getting \(url)")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 5.0)
    }

}
