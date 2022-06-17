//
//  StargazersViewController_Tests.swift
//  GithubStargazersiOSTests
//
//  Created by Stefano Martinallo on 17/06/22.
//

import XCTest
import GithubStargazers

final class StargazersViewController {

    init(service: StargazersLoader) {}

}

class StargazersViewController_Tests: XCTestCase {

    func test_init_doesNotTriggerLoad() {
        let service = GithubServiceSpy()
        let _ = StargazersViewController(service: service)

        XCTAssertEqual(0, service.loadCallCount)
    }

    // MARK: - Helpers

}

class GithubServiceSpy: StargazersLoader {

    private(set) var loadCallCount = 0

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
    }

}
