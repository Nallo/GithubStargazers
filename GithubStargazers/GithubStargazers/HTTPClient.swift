//
//  HTTPClient.swift
//  GithubStargazers
//
//  Created by Stefano Martinallo on 15/06/22.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    typealias HTTPHeader = (headerField: String, headerValue: String)

    func get(url: URL, headers: HTTPHeader, completion: @escaping (Result) -> Void)
}

public final class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(url: URL, headers: HTTPHeader, completion: @escaping (HTTPClient.Result) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(headers.headerValue, forHTTPHeaderField: headers.headerField)

        session.dataTask(with: request) { data, response, error in
            if let data = data, let httpResponse = response as? HTTPURLResponse {
                completion(.success((data, httpResponse)))
            } else if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}
