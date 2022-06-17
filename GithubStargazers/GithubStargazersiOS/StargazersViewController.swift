//
//  StargazersViewController.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 17/06/22.
//

import UIKit
import GithubStargazers

public final class StargazersViewController: UITableViewController {

    private var loader: StargazersLoader?
    private var user: String?
    private var repository: String?
    private var model = [Stargazer]()

    public convenience init(loader: StargazersLoader, user: String, repository: String) {
        self.init()
        self.loader = loader
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

        loader?.loadStargazers(forUser: user!, withRepo: repository!) { [weak self] result in
            self?.model = (try? result.get()) ?? []
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

}
