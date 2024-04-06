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
    }

    func test_loadingIndicator_isNotVisibleWhenLoadingCompletesSuccessfully() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator while service is loading")

        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when service completes loading")
    }

    func test_loadingIndicator_isNotVisibleWhenLoadingCompletesWithError() {
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "expected to display loading indicator while service is loading")

        loader.completeLoadingWithError(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "expected to hide loading indicator when service completes loading with error")
    }

    private func makePage(isLast: Bool = true, stargazers: [Stargazer]) -> StargazersPage {
        return StargazersPage(isLast: isLast, stargazers: stargazers)
    }

    func test_loadCompletion_rendersSuccessfullyLoadedStargazers_withEmptyResult() {
        let pageWithoutStargazers = makePage(stargazers: [])

        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: pageWithoutStargazers)

        loader.completeLoading(with: pageWithoutStargazers)
        assertThat(sut, isRendering: pageWithoutStargazers)
    }

    func test_loadCompletion_rendersSuccessfullyLoadedStargazers() {
        let stargazer0 = makeStargazer(username: "stargazer0")
        let stargazer1 = makeStargazer(username: "stargazer1")
        let stargazer2 = makeStargazer(username: "stargazer2")

        let pageWithoutStargazers = makePage(stargazers: [])
        let pageWithThreeStargazers = makePage(stargazers: [stargazer0, stargazer1, stargazer2])

        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: pageWithoutStargazers)

        loader.completeLoading(with: pageWithThreeStargazers)
        assertThat(sut, isRendering: pageWithThreeStargazers)
    }

    func test_avatarImageView_loadsImageURLWhenVisible() {
        let stargazer0 = makeStargazer(avatarURL: URL(string: "http://0-avatar-url.com")!)
        let stargazer1 = makeStargazer(avatarURL: URL(string: "http://1-avatar-url.com")!)
        let page = makePage(stargazers: [stargazer0, stargazer1])
        let (loader, sut) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeLoading(with: page, at: 0)
        XCTAssertEqual([], loader.loadedAvatarURLs, "expected no avatars are loaded until cell is visible")

        sut.simulateAvatarViewVisible(at: 0)
        XCTAssertEqual([stargazer0.avatarURL], loader.loadedAvatarURLs, "expected first avatar loaded when first cell is visible")

        sut.simulateAvatarViewVisible(at: 1)
        XCTAssertEqual([stargazer0.avatarURL, stargazer1.avatarURL], loader.loadedAvatarURLs, "expected first and second avatars loaded when second cell is visible")
    }

    private func assertThat(_ sut: StargazersViewController, isRendering stargazersPage: StargazersPage, file: StaticString = #filePath, line: UInt = #line) {
        let stargazers = stargazersPage.stargazers

        XCTAssertEqual(stargazers.count, sut.numberOfRenderedStargazers(), "expected view controller to render \(stargazers.count) cells, got \(sut.numberOfRenderedStargazers()) instead", file: file, line: line)

        stargazers.enumerated().forEach { idx, stargazer in
            let view = sut.stargazerView(at: idx)
            XCTAssertNotNil(view, "expected view controller to render view with \(stargazer)", file: file, line: line)
            XCTAssertEqual(stargazer.login.capitalized, view?.usernameText, "expected view controller to configure cell with \(stargazer.login), got \(view?.usernameText ?? "") instead", file: file, line: line)
        }
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (loader: StargazersLoaderSpy, sut: StargazersViewController) {
        let user = "any-user"
        let repository = "any-repository"
        let loader = StargazersLoaderSpy()
        let sut = StargazersUIComposer.stargazerController(withAvatarLoader: loader, stargazersLoader: loader, user: user, repository: repository)
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

    func loadStargazers(forUser user: String, withRepo repo: String, page: Int, completion: @escaping StargazersLoader.Completion) {
        stargazersRequests.append(completion)
    }

    func completeLoading(with stargazersPage: StargazersPage = StargazersPage(isLast: true, stargazers: []), at index: Int = 0) {
        guard index < stargazersRequests.count else {
            return XCTFail("cannot complete loading never made")
        }

        stargazersRequests[index](.success(stargazersPage))
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

    func numberOfRenderedStargazers() -> Int {
        return collectionView.numberOfItems(inSection: 0)
    }

    func stargazerView(at row: Int) -> StargazerCollectionViewCell? {
        let datasource = collectionView.dataSource
        let index = IndexPath(row: row, section: 0)
        return datasource?.collectionView(collectionView, cellForItemAt: index) as? StargazerCollectionViewCell
    }

    var isShowingLoadingIndicator: Bool {
        return refreshControl.isAnimating
    }

}

private extension StargazerCollectionViewCell {
    var usernameText: String? {
        return textLabel.text
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
