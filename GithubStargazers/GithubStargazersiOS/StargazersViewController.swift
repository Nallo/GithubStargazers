//
//  StargazersViewController.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 17/06/22.
//

import UIKit
import GithubStargazers

public final class StargazersViewController: UITableViewController {

    private var avatarsLoader: AvatarsLoader?
    private var stargazersLoader: StargazersLoader?
    private var user: String?
    private var repository: String?
    private var model = [Stargazer]()

    public convenience init(avatarsLoader: AvatarsLoader, stargazersLoader: StargazersLoader, user: String, repository: String) {
        self.init()
        self.avatarsLoader = avatarsLoader
        self.stargazersLoader = stargazersLoader
        self.user = user
        self.repository = repository
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }

    @objc private func load() {
        refreshControl?.beginRefreshing()

        stargazersLoader?.loadStargazers(forUser: user!, withRepo: repository!) { [weak self] result in
            guard let self = self else { return }
            if let stargazers = try? result.get() {
                self.model = stargazers
                self.tableView.reloadData()
            }
            self.refreshControl?.endRefreshing()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = model[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = cellModel.login
        avatarsLoader?.loadAvatar(from: cellModel.avatarURL) { [weak cell] reult in
            if let data = try? reult.get() {
                cell?.imageView?.image = UIImage(data: data)
            }
        }
        return cell
    }

}
