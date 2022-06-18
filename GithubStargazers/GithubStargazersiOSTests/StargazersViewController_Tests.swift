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
        XCTAssertEqual(0, loader.loadStargazersCallCount, "expected no service loading before the view is loaded into memory")

        sut.loadViewIfNeeded()
        XCTAssertEqual(1, loader.loadStargazersCallCount, "expected loading once when the view is loaded into memory")

        sut.triggerReloading()
        XCTAssertEqual(2, loader.loadStargazersCallCount, "expected loading when user pull to refresh")

        sut.triggerReloading()
        XCTAssertEqual(3, loader.loadStargazersCallCount, "expected loading when user pull to refresh")
    }

    func test_loadingIndicator_isVisibleWhileLoading() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator while service is loading")

        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when service completes loading")

        sut.triggerReloading()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator when user trigger reloading")

        loader.completeLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when reloading completes")
    }

    func test_loadCompletion_rendersSuccessfullyLoadedStargazers() {
        let stargazer0 = makeStargazer(username: "stargazer0")
        let stargazer1 = makeStargazer(username: "stargazer1")
        let stargazer2 = makeStargazer(username: "stargazer2")
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])

        loader.completeLoading(with: [stargazer0], at: 0)
        assertThat(sut, isRendering: [stargazer0])

        sut.triggerReloading()
        loader.completeLoading(with: [stargazer0, stargazer1, stargazer2], at: 1)
        assertThat(sut, isRendering: [stargazer0, stargazer1, stargazer2])

        sut.triggerReloading()
        loader.completeLoadingWithError(at: 2)
        assertThat(sut, isRendering: [stargazer0, stargazer1, stargazer2])
    }

    func test_avatarImageView_loadsImageURLWhenVisible() {
        let stargazer0 = makeStargazer(avatarURL: URL(string: "http://0-avatar-url.com")!)
        let stargazer1 = makeStargazer(avatarURL: URL(string: "http://1-avatar-url.com")!)
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeLoading(with: [stargazer0, stargazer1], at: 0)
        XCTAssertEqual([], loader.loadedAvatarURLs, "expected no avatars are loaded until cell is visible")

        sut.simulateAvatarViewVisible(at: 0)
        XCTAssertEqual([stargazer0.avatarURL], loader.loadedAvatarURLs, "expected first avatar loaded when first cell is visible")

        sut.simulateAvatarViewVisible(at: 1)
        XCTAssertEqual([stargazer0.avatarURL, stargazer1.avatarURL], loader.loadedAvatarURLs, "expected first and second avatars loaded when second cell is visible")
    }

    private func assertThat(_ sut: StargazersViewController, isRendering stargazers: [Stargazer], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(stargazers.count, sut.numberOfRenderedStargazers(), "expected view controller to render \(stargazers.count) cells, got \(sut.numberOfRenderedStargazers()) instead", file: file, line: line)

        stargazers.enumerated().forEach { idx, stargazer in
            let view = sut.stargazerView(at: idx) as? UITableViewCell
            XCTAssertNotNil(view, "expected view controller to render view with \(stargazer)", file: file, line: line)
            XCTAssertEqual(stargazer.login, view?.usernameText, "expected view controller to configure cell with \(stargazer.login), got \(view?.usernameText ?? "") instead", file: file, line: line)
        }
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (loader: StargazersLoaderSpy, sut: StargazersViewController) {
        let user = "any-user"
        let repository = "any-repository"
        let loader = StargazersLoaderSpy()
        let sut = StargazersViewController(avatarsLoader: loader, stargazersLoader: loader, user: user, repository: repository)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (loader, sut)
    }

    private func makeStargazer(username: String = "any username", avatarURL url: URL = URL(string: "http://an-avatar-url.com")!) -> Stargazer {
        return Stargazer(login: username, avatarURL: url)
    }

}

class StargazersLoaderSpy: StargazersLoader, AvatarsLoader {

    // MARK: - StargazersLoader

    private var stargazersRequests = [StargazersLoader.Completion]()

    var loadStargazersCallCount: Int {
        return stargazersRequests.count
    }

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping StargazersLoader.Completion) {
        stargazersRequests.append(completion)
    }

    func completeLoading(with stargazers: [Stargazer] = [], at index: Int = 0) {
        guard index < stargazersRequests.count else {
            return XCTFail("cannot complete loading never made")
        }

        stargazersRequests[index](.success(stargazers))
    }

    func completeLoadingWithError(at index: Int = 0) {
        guard index < stargazersRequests.count else {
            return XCTFail("cannot complete loading never made")
        }

        let error = NSError(domain: "any-error", code: -1)
        stargazersRequests[index](.failure(error))
    }

    // MARK: - AvatarsLoader

    private(set) var loadedAvatarURLs = [URL]()

    func loadAvatar(from url: URL, completion: @escaping AvatarsLoader.Completion) {
        loadedAvatarURLs.append(url)
    }

}

private extension StargazersViewController {

    func simulateAvatarViewVisible(at row: Int) {
        _ = stargazerView(at: row)
    }

    func triggerReloading() {
        refreshControl?.simulatePullToRefresh()
    }

    func numberOfRenderedStargazers() -> Int {
        return tableView.numberOfRows(inSection: 0)
    }

    func stargazerView(at row: Int) -> UITableViewCell? {
        let datasource = tableView.dataSource
        let index = IndexPath(row: row, section: 0)
        return datasource?.tableView(tableView, cellForRowAt: index)
    }

    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }

}

private extension UITableViewCell {
    var usernameText: String? {
        return textLabel?.text
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
