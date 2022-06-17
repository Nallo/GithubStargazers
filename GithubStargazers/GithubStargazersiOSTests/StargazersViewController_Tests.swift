//
//  StargazersViewController_Tests.swift
//  GithubStargazersiOSTests
//
//  Created by Stefano Martinallo on 17/06/22.
//

import XCTest
import GithubStargazers

final class StargazersViewController {

    init(service: GithubServiceSpy) {}

}

class StargazersViewController_Tests: XCTestCase {

    func test_init_doesNotTriggerLoad() {
        let service = GithubServiceSpy()
        let _ = StargazersViewController(service: service)

        XCTAssertEqual(0, service.loadCallCount)
    }

    // MARK: - Helpers

}

class GithubServiceSpy {
    private(set) var loadCallCount = 0
}
