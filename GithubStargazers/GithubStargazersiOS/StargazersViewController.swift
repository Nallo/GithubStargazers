//
//  StargazersViewController.swift
//  GithubStargazersiOS
//
//  Created by Stefano Martinallo on 17/06/22.
//

import UIKit
import GithubStargazers


public final class StargazerCollectionViewCell: UICollectionViewCell {

    public static let identifier: String = "cell"

    public let textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .green
        contentView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

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

        collectionView.register(StargazerCollectionViewCell.self, forCellWithReuseIdentifier: StargazerCollectionViewCell.identifier)
        collectionView.contentInset = .init(top: 0, left: 16, bottom: 0, right: 16)

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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StargazerCollectionViewCell
        cell.textLabel.text = cellModel.login
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

extension StargazersViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let collectionViewWidth = collectionView.bounds.width - collectionView.contentInset.right - collectionView.contentInset.left
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let spaceBetweenCells = flowLayout.minimumInteritemSpacing * (columns - 1)
        let adjustedWidth = collectionViewWidth - spaceBetweenCells
        let width: CGFloat = adjustedWidth / columns
        let height: CGFloat = width * 4 / 3
        return CGSize(width: width, height: height)
    }

}
