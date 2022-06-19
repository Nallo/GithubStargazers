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
        let bundle = Bundle(for: StargazersViewController.self)
        let storyboard = UIStoryboard(name: "Stargazers", bundle: bundle)

        let stargazerController = storyboard.instantiateInitialViewController() as! StargazersViewController
        stargazerController.avatarsLoader = avatarLoader
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

    func loadStargazers(forUser user: String, withRepo repo: String, completion: @escaping Completion) {
        decoratee.loadStargazers(forUser: user, withRepo: repo) { result in
            if Thread.isMainThread {
                completion(result)
            } else {
                DispatchQueue.main.async { completion(result) }
            }
        }
    }
}
