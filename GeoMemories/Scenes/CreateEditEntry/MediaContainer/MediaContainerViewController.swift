//
//  MediaContainerViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 26.08.2025.
//

import UIKit
import SnapKit
import PhotosUI

class MediaContainerViewController: UIViewController {
    private let cellIdentifier = "MediaCell"
    
    // Debug values only
    private var items: [MediaEntry?] = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    private let itemsPerRow = 5
    private let spacing = 8
    
    private var cameraPicker: UIImagePickerController!
    private var picker: PHPickerViewController!
    
    private var buttonContainer: UIStackView!
    private var addMediaButton: UIButton!
    private var takeMediaButton: UIButton!
    
    private var collectionView: UICollectionView!
    private var collectionViewHeightConstraint: Constraint?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateCollectionViewHeight()
    }
}

// MARK: - UI Configuration
private extension MediaContainerViewController {
    func setupUI() {
        configurePicker()
        configureAddMediaButton()
        configureTakeMediaButton()
        configureButtonContainer()
        configureCollectionView()
    }
    
    func configurePicker() {
        cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = true
        cameraPicker.delegate = self
        
        var pickerConfig = PHPickerConfiguration()
        pickerConfig.filter = .any(of: [.images, .videos])
        picker = PHPickerViewController(configuration: pickerConfig)
        picker.delegate = self
    }
    
    func configureAddMediaButton() {
        var config = UIButton.Configuration.tinted()
        config.title = String(localized: "addExistingMediaButtonTitle")
        config.image = UIImage(systemName: "plus")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.cornerStyle = .large
        config.contentInsets = .init(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        
        addMediaButton = UIButton(configuration: config)
        let action = UIAction { _ in
            self.present(self.picker, animated: true)
        }
        addMediaButton.addAction(action, for: .touchUpInside)
    }
    
    func configureTakeMediaButton() {
        var config = UIButton.Configuration.tinted()
        config.title = String(localized: "takeNewMediaButtonTitle")
        config.image = UIImage(systemName: "camera")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.cornerStyle = .large
        config.contentInsets = .init(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        
        takeMediaButton = UIButton(configuration: config)
        let action = UIAction { _ in
            self.present(self.cameraPicker, animated: true)
        }
        takeMediaButton.addAction(action, for: .touchUpInside)
    }
    
    func configureButtonContainer() {
        buttonContainer = UIStackView(
            arrangedSubviews: [
                addMediaButton,
                takeMediaButton
            ]
        )
        buttonContainer.axis = .horizontal
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 8
        buttonContainer.alignment = .fill
        
        view.addSubview(buttonContainer)
        
        buttonContainer.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
    }
    
    func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: cellIdentifier
        )
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(buttonContainer.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            collectionViewHeightConstraint = make.height.equalTo(0).constraint
        }
    }
}

// MARK: - Helper Methods
private extension MediaContainerViewController {
    func isEmptyCell(at index: Int) -> Bool {
        return index >= items.count
    }
    
    func calculateCellSize() -> CGSize {
        let totalSpacing = CGFloat((itemsPerRow - 1) * spacing)
        let side = (collectionView.bounds.width - totalSpacing) / CGFloat(itemsPerRow)
        return CGSize(width: side, height: side)
    }
    
    func updateCollectionViewHeight() {
        let numberOfRows = ceil(CGFloat(items.count) / CGFloat(itemsPerRow))
        let cellHeight = calculateCellSize().height
        let heightWithoutSpacing = numberOfRows * cellHeight
        let totalHeight = heightWithoutSpacing + (max(0, numberOfRows - 1) * CGFloat(spacing))
        
        collectionViewHeightConstraint?.update(offset: totalHeight)
    }
}

extension MediaContainerViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellIdentifier,
            for: indexPath
        )
        
        cell.backgroundColor = .systemBlue
        cell.layer.cornerRadius = 8
        
        return cell
    }
}

extension MediaContainerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return calculateCellSize()
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return CGFloat(spacing)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return CGFloat(spacing)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return .zero
    }
}

extension MediaContainerViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        return !isEmptyCell(at: indexPath.item)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        shouldHighlightItemAt indexPath: IndexPath
    ) -> Bool {
        return !isEmptyCell(at: indexPath.item)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        items.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }
}

extension MediaContainerViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        
    }
}

extension MediaContainerViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        
    }
}

#if DEBUG
import SwiftUI

struct MediaContainerViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MediaContainerViewController {
        return MediaContainerViewController()
    }
    func updateUIViewController(_ uiViewController: MediaContainerViewController, context: Context) {}
}

#Preview {
    MediaContainerViewControllerPreview()
}
#endif
