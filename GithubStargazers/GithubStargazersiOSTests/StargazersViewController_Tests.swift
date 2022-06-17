//
//  StargazersViewController_Tests.swift
//  GithubStargazersiOSTests
//
//  Created by Stefano Martinallo on 17/06/22.
//

import XCTest
import GithubStargazers
import GithubStargazersiOS

class StargazersViewController_Tests: XCTestCase {

    func test_loadStargazers_requestStargazersToLoader() {
        let (loader, sut) = makeSUT()
        XCTAssertEqual(0, loader.loadCallCount, "expected no service loading before the view is loaded into memory")

        sut.loadViewIfNeeded()
        XCTAssertEqual(1, loader.loadCallCount, "expected loading once when the view is loaded into memory")

        sut.triggerReloading()
        XCTAssertEqual(2, loader.loadCallCount, "expected loading when user pull to refresh")

        sut.triggerReloading()
        XCTAssertEqual(3, loader.loadCallCount, "expected loading when user pull to refresh")
    }

    func test_loadingIndicator_isVisibleWhileLoading() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator while service is loading")

        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when service completes loading")

        sut.triggerReloading()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator when user trigger reloading")

        loader.completeLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when reloading completes")
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

    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
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
