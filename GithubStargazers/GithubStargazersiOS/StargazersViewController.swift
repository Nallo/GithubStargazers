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

    private let imageViewPlaceholder: UIImage = {
        let bundle = Bundle(for: StargazerCollectionViewCell.self)
        let image = UIImage(named: "avatar", in: bundle, with: .none)!
        return image
    }()

    private let imageViewShadow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOffset = CGSize(width: 3, height: 3)
        view.layer.shadowOpacity = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 0.5
        return view
    }()

    public lazy var imageView: UIImageView = {
        let iv = UIImageView(image: imageViewPlaceholder)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.clipsToBounds = true
        return iv
    }()

    public let textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .white
        contentView.addSubview(imageViewShadow)
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)

        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.lightGray.cgColor
        contentView.layer.shadowOffset = CGSize(width: 3, height: 3)
        contentView.layer.shadowOpacity = 1
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.borderWidth = 0.5

        NSLayoutConstraint.activate([
            imageViewShadow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageViewShadow.bottomAnchor.constraint(equalTo: textLabel.topAnchor, constant: -8),
            imageViewShadow.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageViewShadow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: textLabel.topAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            textLabel.heightAnchor.constraint(equalToConstant: 30),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        imageViewShadow.layoutIfNeeded()
        imageViewShadow.layer.cornerRadius = imageViewShadow.frame.height / 2

        imageView.layoutIfNeeded()
        imageView.layer.cornerRadius = imageView.frame.height / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        imageView.image = imageViewPlaceholder
    }

}

public final class StargazersViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {

    var avatarsLoader: AvatarsLoader?
    var stargazersLoader: StargazersLoader?
    var user: String?
    var repository: String?

    private var model = [Stargazer]()
    private var isLastPage = true
    private var isLoadingNewPage = false
    private var currentLoadedPage = 1

    public var refreshControl: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()

    public lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 16
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(red: 243/255, green: 250/225, blue: 250/255, alpha: 1)
        collectionView.register(StargazerCollectionViewCell.self, forCellWithReuseIdentifier: StargazerCollectionViewCell.identifier)
        collectionView.contentInset = .init(top: 0, left: 24, bottom: 0, right: 24)
        return collectionView
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = getTitle(fromRepositoryName: repository)

        view.addSubview(collectionView)
        collectionView.addSubview(refreshControl)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            refreshControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshControl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        load()
    }

    private func load() {
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

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellModel = model[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StargazerCollectionViewCell
        cell.textLabel.text = cellModel.login.capitalized
        avatarsLoader?.loadAvatar(from: cellModel.avatarURL) { [weak cell] reult in
            if let data = try? reult.get() {
                 cell?.imageView.image = UIImage(data: data)
            }
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if let lastIndexPath = indexPaths.last, lastIndexPath.row == model.count - 1 && !isLoadingNewPage && !isLastPage {
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

    private func getTitle(fromRepositoryName repository: String?) -> String? {
        guard let unwrappedRepository = repository else { return nil }
        return unwrappedRepository.replacingOccurrences(of: "-", with: " ").capitalized.appending(" ⭐️")
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns = 2
        let width = collectionView.bounds.width / CGFloat(numberOfColumns) - 4 - 32
        let height = width
        return CGSize(width: width, height: height)
    }

}
