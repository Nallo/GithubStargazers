//
//  StargazersViewController_Tests.swift
//  GithubStargazersiOSTests
//
//  Created by Stefano Martinallo on 17/06/22.
//

import XCTest
import GithubStargazers

final class StargazersViewController: UITableViewController {

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

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }

    @objc private func load() {
        loader?.loadStargazers(forUser: user!, withRepo: repository!) { _ in }
    }

}

class StargazersViewController_Tests: XCTestCase {

    func test_init_doesNotTriggerLoad() {
        let (loader, _) = makeSUT()

        XCTAssertEqual(0, loader.loadCallCount)
    }

    func test_viewDidLoad_triggersStargazersLoad() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(1, loader.loadCallCount)
    }

    func test_pullToRefresh_triggersStargazersLoad() {
        let (loader, sut) = makeSUT()
        sut.loadViewIfNeeded()

        sut.refreshControl?.simulatePullToRefresh()

        XCTAssertEqual(2, loader.loadCallCount)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (loader: StargazersLoaderSpy, sut: StargazersViewController) {
        let user = "any-user"
        let repository = "any-repository"
        let loader = StargazersLoaderSpy()
        let sut = StargazersViewController(loader: loader, user: user, repository: repository)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (loader, sut)
    }

}

class StargazersLoaderSpy: StargazersLoader {

    private(set) var loadCallCount = 0

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
        loadCallCount += 1
    }

}

private extension UIRefreshControl {

    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({
                (target as NSObject).perform(Selector($0))
            })
        }
    }
}
