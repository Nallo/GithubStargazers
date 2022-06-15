//
//  HTTPClientSpy.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation
import GithubStargazers

class HTTPClientSpy: HTTPClient {
    private(set) var requestedUrls = [String]()
    private(set) var requestedHeader: (headerField: String, headerValue: String) = ("","")

    func get(url: URL, headers: HTTPHeader, completion: @escaping (HTTPClient.Result) -> Void) {
        requestedUrls.append(url.absoluteString)
        requestedHeader = headers
    }
}
