//
//  StargazersViewController_Tests.swift
//  GithubStargazersiOSTests
//
//  Created by Stefano Martinallo on 17/06/22.
//

import XCTest
import GithubStargazers

final class StargazersViewController: UIViewController {

    private var loader: StargazersLoader?
    private var user: String?
    private var repository: String?

    convenience init(loader: StargazersLoader, user: String, repository: String) {
        self.init()
        self.loader = loader
        self.user = user
        self.repository = repository
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loader?.loadStargazers(forUser: user!, withRepo: repository!) { _ in }

    }

}

class StargazersViewController_Tests: XCTestCase {

    func test_init_doesNotTriggerLoad() {
        let user = "any-user"
        let repository = "any-repository"
        let service = StargazersLoaderSpy()
        let _ = StargazersViewController(loader: service, user: user, repository: repository)

        XCTAssertEqual(0, service.loadCallCount)
    }

    func test_viewDidLoad_triggersStargazersLoad() {
        let user = "any-user"
        let repository = "any-repository"
        let service = StargazersLoaderSpy()
        let sut = StargazersViewController(loader: service, user: user, repository: repository)

        sut.loadViewIfNeeded()

        XCTAssertEqual(1, service.loadCallCount)
    }

    // MARK: - Helpers

}

class StargazersLoaderSpy: StargazersLoader {

    private(set) var loadCallCount = 0

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
        loadCallCount += 1
    }

}
