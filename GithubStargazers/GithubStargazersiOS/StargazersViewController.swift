//
//  StargazersViewController.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 17/06/22.
//

import UIKit
import GithubStargazers

public final class StargazersViewController: UICollectionViewController {

    var avatarsLoader: AvatarsLoader?
    var stargazersLoader: StargazersLoader?
    var user: String?
    var repository: String?

    @IBOutlet public weak var refreshControl: UIActivityIndicatorView!

    private var model = [Stargazer]()
    private var isLastPage = true
    private var isLoadingNewPage = false
    private var currentLoadedPage = 1

    public override func viewDidLoad() {
        super.viewDidLoad()

        load()
    }

    @IBAction private func load() {
        refreshControl.startAnimating()

        isLoadingNewPage = true

        stargazersLoader?.loadStargazers(forUser: user!, withRepo: repository!, page: 1) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingNewPage = false
            self.currentLoadedPage = 1

            if let stargazersPage = try? result.get() {
                self.isLastPage = stargazersPage.isLast
                self.model = stargazersPage.stargazers
                self.collectionView.reloadData()
            }
            self.refreshControl.stopAnimating()
        }
    }

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellModel = model[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        // cell.textLabel?.text = cellModel.login
        avatarsLoader?.loadAvatar(from: cellModel.avatarURL) { [weak cell] reult in
            if let data = try? reult.get() {
                // cell?.imageView?.image = UIImage(data: data)
            }
        }
        return cell
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        if (offsetY > contentHeight - scrollView.frame.height && !isLoadingNewPage && !isLastPage) {
            requestNextPage()
        }
    }

    private func requestNextPage() {
        isLoadingNewPage = true
        let pageToLoad = currentLoadedPage + 1

        stargazersLoader?.loadStargazers(forUser: user!, withRepo: repository!, page: pageToLoad) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingNewPage = false
            self.currentLoadedPage = pageToLoad

            if let stargazersPage = try? result.get() {
                self.isLastPage = stargazersPage.isLast
                self.model.append(contentsOf: stargazersPage.stargazers)
                self.collectionView.reloadData()
            }
        }
    }
}
