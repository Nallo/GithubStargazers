//
//  StargazersUIComposer.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 18/06/22.
//

import UIKit
import GithubStargazers

public final class StargazersUIComposer {
    private init() {}

    public static func stargazerController(withAvatarLoader avatarLoader: AvatarsLoader, stargazersLoader: StargazersLoader, user: String, repository: String) -> StargazersViewController {
        let stargazerController = StargazersViewController()
        stargazerController.avatarsLoader = MainQueueDispatchDecorator(decoratee: avatarLoader)
        stargazerController.stargazersLoader = MainQueueDispatchDecorator(decoratee: stargazersLoader)
        stargazerController.user = user
        stargazerController.repository = repository

        return stargazerController
    }
}

private final class MainQueueDispatchDecorator<T> {

    private let decoratee: T

    init(decoratee: T) {
        self.decoratee = decoratee
    }
}

extension MainQueueDispatchDecorator: StargazersLoader where T == StargazersLoader {

    func loadStargazers(forUser user: String, withRepo repo: String, page: Int, completion: @escaping StargazersLoader.Completion) {
        decoratee.loadStargazers(forUser: user, withRepo: repo, page: page) { result in
            if Thread.isMainThread {
                completion(result)
            } else {
                DispatchQueue.main.async { completion(result) }
            }
        }
    }
}

extension MainQueueDispatchDecorator: AvatarsLoader where T == AvatarsLoader {

    func loadAvatar(from url: URL, completion: @escaping AvatarsLoader.Completion) {
        decoratee.loadAvatar(from: url) { result in
            if Thread.isMainThread {
                completion(result)
            } else {
                DispatchQueue.main.async { completion(result) }
            }
        }
    }
}
