//
//  InputViewController.swift
//  GithubStargazersApp
//
//  Created by Stefano Martinallo on 18/06/22.
//

import UIKit
import GithubStargazers
import GithubStargazersiOS

class InputViewController: UIViewController {

    @IBOutlet private(set) weak var githubUserTF: UITextField!
    @IBOutlet private(set) weak var githubRepoTF: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func displayStargazersDidTap(_ sender: UIButton) {
        displayStargazersViewController()
    }

    private func displayStargazersViewController() {
        let user = githubUserTF.text ?? ""
        let repository = githubRepoTF.text ?? ""
        let client = URLSessionHTTPClient(session: .shared)
        let avatarLoader = GithubAvatarsLoader(client: client)
        let stargazerLoader = GithubStargazersLoader(client)

        let stargazersViewController = StargazersUIComposer.stargazerController(
            withAvatarLoader: avatarLoader,
            stargazersLoader: stargazerLoader,
            user: user,
            repository: repository
        )

        navigationController?.show(stargazersViewController, sender: self)
    }

}
