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
        refreshControl?.beginRefreshing()
        load()
    }

    @objc private func load() {
        loader?.loadStargazers(forUser: user!, withRepo: repository!) { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }

}

class StargazersViewController_Tests: XCTestCase {

    func test_loadStargazers_requestStargazersToLoader() {
        let (loader, sut) = makeSUT()
        XCTAssertEqual(0, loader.loadCallCount)

        sut.loadViewIfNeeded()
        XCTAssertEqual(1, loader.loadCallCount)

        sut.triggerReloading()
        XCTAssertEqual(2, loader.loadCallCount)

        sut.triggerReloading()
        XCTAssertEqual(3, loader.loadCallCount)
    }

    func test_viewDidLoad_displaysLoadingIndicator() {
        let (_, sut) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(true, sut.refreshControl?.isRefreshing)
    }

    func test_viewDidLoad_hidesLoadingIndicatorWhenLoadingCompletes() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeLoading()

        XCTAssertEqual(false, sut.refreshControl?.isRefreshing)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (loader: StargazersLoaderSpy, sut: StargazersViewController) {
        let user = "any-user"
        let repository = "any-repository"
        let loader = StargazersLoaderSpy()
        let sut = StargazersViewController(loader: loader, user: user, repository: repository)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loader, sut)
    }

}

class StargazersLoaderSpy: StargazersLoader {

    private var completions = [Completion]()
    var loadCallCount: Int {
        return completions.count
    }

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
        completions.append(completion)
    }

    func completeLoading(at index: Int = 0) {
        guard index < completions.count else {
            return XCTFail("cannot complete loading never made")
        }

        completions[index](.success([]))
    }

}

private extension StargazersViewController {

    func triggerReloading() {
        refreshControl?.simulatePullToRefresh()
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
