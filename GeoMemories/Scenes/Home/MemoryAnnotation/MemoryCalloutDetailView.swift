//
//  MemoryCalloutDetailView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 01.09.2025.
//

import UIKit
import SnapKit
import Combine

class MemoryCalloutDetailView: UIView {
    // MARK: - Properties
    private var media: [MediaEntry] = []
    private let mediaWorker: MediaFileWorkerProtocol
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.register(
            MediaPlaceholderViewCell.self,
            forCellWithReuseIdentifier: MediaPlaceholderViewCell.reuseIdentifier
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    // MARK: - View Lifecycle
    
    init(mediaWorker: MediaFileWorkerProtocol = Dependencies.mediaFileWorker) {
        self.mediaWorker = mediaWorker
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with annotation: MemoryAnnotation) {
        titleLabel.text = annotation.entryTitle
        descriptionLabel.text = annotation.entryDescription
        media = annotation.media
        mediaCollectionView.reloadData()
        mediaCollectionView.isHidden = media.isEmpty
    }
}

// MARK: - UI Setup
private extension MemoryCalloutDetailView {
    func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, mediaCollectionView])
        stackView.axis = .vertical
        stackView.spacing = 8
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        mediaCollectionView.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        
        self.snp.makeConstraints { make in
            make.width.equalTo(250)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension MemoryCalloutDetailView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaPlaceholderViewCell.reuseIdentifier,
            for: indexPath
        ) as? MediaPlaceholderViewCell else {
            return UICollectionViewCell()
        }
        
        cell.setup(with: media[indexPath.item], isRemovable: false)
        
        return cell
    }
}
