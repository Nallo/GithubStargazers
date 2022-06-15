//
//  HTTPClientSpy.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 15/06/22.
//

import XCTest
import GithubStargazers

class HTTPClientSpy: HTTPClient {
    private(set) var requestedUrls = [String]()
    private(set) var requestedHeader: (headerField: String, headerValue: String) = ("","")

    private var completions = [(HTTPClient.Result) -> Void]()

    func get(url: URL, headers: HTTPHeader, completion: @escaping (HTTPClient.Result) -> Void) {
        requestedUrls.append(url.absoluteString)
        requestedHeader = headers
        completions.append(completion)
    }

    func complete(withStatusCode code: Int, data: Data, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) {
        guard index < completions.count else {
            return XCTFail("Can't complete request never made", file: file, line: line)
        }

        let response = HTTPURLResponse(
            url: URL(string: requestedUrls[index])!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!

        completions[index](.success((data, response)))
    }

    func complete(with error: Error, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) {
        guard index < completions.count else {
            return XCTFail("Can't complete request never made", file: file, line: line)
        }

        completions[index](.failure(error))
    }

}
