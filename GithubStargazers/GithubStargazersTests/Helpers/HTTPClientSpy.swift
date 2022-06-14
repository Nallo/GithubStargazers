//
//  HTTPClientSpy.swift
//  GithubStargazersTests
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation
import GithubStargazers

class HTTPClientSpy: HTTPClient {
    private(set) var requestedUrls = [URL]()
    private(set) var requestedHeader: (headerField: String, headerValue: String) = ("","")

    func get(url: URL, headers: (headerField: String, headerValue: String)) {
        requestedUrls.append(url)
        requestedHeader = headers
    }
}
