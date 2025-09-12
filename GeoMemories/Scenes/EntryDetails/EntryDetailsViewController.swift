//
//  EntryDetailsViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import UIKit
import SnapKit
import Combine
import CoreStore
import MapKit

final class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

final class EntryDetailsViewController: UICollectionViewController {
    var viewModel: EntryDetailsViewModelProtocol!
    
    // MARK: - View Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(collectionViewLayout: UICollectionViewLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.loadInitialWikiData()
        bindViewModel()
        if #unavailable(iOS 26.0) {
            view.backgroundColor = .systemBackground
        }
    }
}

// MARK: - UI Setup
private extension EntryDetailsViewController {
    func setupUI() {
        setupNavigationBar()
        setupCollectionView()
    }
    
    func setupNavigationBar() {
        navigationItem.title = viewModel.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissSheet)
        )
    }
    
    @objc func dismissSheet() {
        dismiss(animated: true)
    }
    
    func setupCollectionView() {
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.backgroundColor = .systemBackground
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            TextCellView.self,
            forCellWithReuseIdentifier: TextCellView.reuseIdentifier
        )
        collectionView.register(
            MediaCardView.self,
            forCellWithReuseIdentifier: MediaCardView.reuseIdentifier
        )
        collectionView.register(
            MapCellView.self,
            forCellWithReuseIdentifier: MapCellView.reuseIdentifier
        )
    }
}

// MARK: - View Model Binding
private extension EntryDetailsViewController {
    func bindViewModel() {
        viewModel.wikiDescription.bind { [weak self] _ in
            guard let self else { return }
            collectionView.reloadData()
//            collectionView.performBatchUpdates {
//                self.collectionView.reloadSections(
//                    IndexSet(integer: EntryDetailsSection.placeInfo.rawValue)
//                )
//            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension EntryDetailsViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        EntryDetailsSection.allCases.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let sectionType = EntryDetailsSection(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .userInfo:
            return viewModel.description.isEmpty ? 0 : 1
        case .mapView:
            return 1
        case .mediaCards:
            return viewModel.mediaCards.count
        case .placeInfo:
            if let value = viewModel.wikiDescription.value {
                return value.isEmpty ? 0 : 1
            }
            return 0
        }
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let sectionType = EntryDetailsSection(rawValue: indexPath.section) else {
            fatalError("Invalid section: \(indexPath.section)")
        }
        
        // swiftlint:disable force_cast
        switch sectionType {
        case .userInfo:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TextCellView.reuseIdentifier,
                for: indexPath
            ) as! TextCellView
            cell.configure(with: viewModel.description)
            return cell
        case .mediaCards:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MediaCardView.reuseIdentifier,
                for: indexPath
            ) as! MediaCardView
            cell.viewModel = viewModel.mediaCards[indexPath.item]
            return cell
        case .mapView:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MapCellView.reuseIdentifier,
                for: indexPath
            ) as! MapCellView
            cell.coords = viewModel.coordinates
            return cell
        case .placeInfo:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TextCellView.reuseIdentifier,
                for: indexPath
            ) as! TextCellView
            cell.configure(with: viewModel.wikiDescription.value ?? "")
            return cell
        }
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let sectionType = EntryDetailsSection(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }
        
        // swiftlint:disable force_cast
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! SectionHeaderView
        header.configure(with: sectionType.title)
        return header
    }
}

// MARK: - Compositional Layout Methods
private extension EntryDetailsViewController {
    func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let sectionType = EntryDetailsSection(rawValue: sectionIndex) else {
                fatalError("There isn't supposed to be a section for given section index: \(sectionIndex)")
            }
            
            switch sectionType {
            case .userInfo, .mapView, .placeInfo:
                return self?.createVerticalSection(
                    forSection: sectionIndex, using: environment
                )
            case .mediaCards:
                return self?.createHorizontalSection()
            }
        }
    }
    
    func createVerticalSection(
        forSection sectionIndex: Int,
        using layoutEnvironment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = sectionIndex == 0 ? .none : .supplementary
        configuration.headerTopPadding = 0
        configuration.showsSeparators = false
        
        let section = NSCollectionLayoutSection.list(
            using: configuration,
            layoutEnvironment: layoutEnvironment
        )
        section.boundarySupplementaryItems.forEach {
            $0.contentInsets = .init(top: 24, leading: 16, bottom: 4, trailing: 16)
        }
        section.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        return section
    }
    
    // swiftlint:disable line_length
    func createHorizontalSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(240), heightDimension: .absolute(320))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 16
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(32))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
}
