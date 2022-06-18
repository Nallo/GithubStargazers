//
//  StargazersViewController.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 17/06/22.
//

import UIKit
import GithubStargazers

public final class StargazersViewController: UITableViewController {

    var avatarsLoader: AvatarsLoader?
    var stargazersLoader: StargazersLoader?
    var user: String?
    var repository: String?
    private var model = [Stargazer]()

    public override func viewDidLoad() {
        super.viewDidLoad()

        load()
    }

    @IBAction private func load() {
        refreshControl?.beginRefreshing()

        stargazersLoader?.loadStargazers(forUser: user!, withRepo: repository!) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let stargazers = try? result.get() {
                    self.model = stargazers
                    self.tableView.reloadData()
                }
                self.refreshControl?.endRefreshing()
            }
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = model[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = cellModel.login
        avatarsLoader?.loadAvatar(from: cellModel.avatarURL) { [weak cell] reult in
            DispatchQueue.main.async {
                if let data = try? reult.get() {
                    cell?.imageView?.image = UIImage(data: data)
                }
            }
        }
        return cell
    }

}
