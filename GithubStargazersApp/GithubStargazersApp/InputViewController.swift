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
        dismissKeyboard()

        if isFormFilledCorrectly() {
            displayStargazersViewController()
        } else {
            displayAlert()
        }
    }

    private func dismissKeyboard() {
        view.subviews.forEach { $0.resignFirstResponder() }
    }

    private func isFormFilledCorrectly() -> Bool {
        guard
            let user = githubUserTF.text, !user.isEmpty,
            let repo = githubRepoTF.text, !repo.isEmpty
        else { return false }

        return true
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

    private func displayAlert() {
        let title = "Missing information"
        let message = "You should provide a Github user and repo to display the stargazers"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)

        present(alert, animated: true)
    }
}
