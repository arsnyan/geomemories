//
//  MediaContainerViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 26.08.2025.
//

import UIKit
import SnapKit
import PhotosUI
import Combine
import OSLog
import CoreStore

protocol MediaContainerViewControllerDelegate: AnyObject {
    func updateContentHeight(_ height: CGFloat)
    func mediaItemsDidChange(_ items: [MediaEntry])
}

class MediaContainerViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    
    private let logger = Logger(subsystem: "GeoMemories", category: "MediaContainerVC")
    private let worker = Dependencies.mediaFileWorker
    
    weak var delegate: MediaContainerViewControllerDelegate?
    var geoEntry: GeoEntry?
    
    private var items: [MediaEntry] = [] {
        didSet {
            delegate?.mediaItemsDidChange(items)
        }
    }
    private let itemsPerRow = 4
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
        
        if let geoEntry {
            if let existing = Dependencies.dataStack.fetchExisting(geoEntry) {
                items = Array(existing.mediaIds)
                collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateCollectionViewHeight()
    }
}

// MARK: - UI Configuration
private extension MediaContainerViewController {
    func setupUI() {
        configureAddMediaButton()
        configureTakeMediaButton()
        configureButtonContainer()
        configureCollectionView()
    }
    
    func configureCameraPicker() {
        cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = true
        cameraPicker.delegate = self
    }
    
    func configurePhotosPicker() {
        var pickerConfig = PHPickerConfiguration()
        pickerConfig.filter = .any(of: [.images, .videos])
        pickerConfig.selectionLimit = 0
        pickerConfig.selection = .default
        picker = PHPickerViewController(configuration: pickerConfig)
        picker.delegate = self
    }
    
    func configureAddMediaButton() {
        var config = UIButton.Configuration.tinted()
        config.title = String(localized: "addExistingMediaButtonTitle")
        config.image = UIImage(systemName: "plus")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.cornerStyle = Constants.buttonCornerStyle
        config.contentInsets = .init(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        
        addMediaButton = UIButton(configuration: config)
        let action = UIAction { [weak self] _ in
            self?.configurePhotosPicker()
            
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .notDetermined:
                    print("impossible")
                case .restricted, .denied:
                    print("oh no")
                case .authorized, .limited:
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.present(self.picker, animated: true)
                    }
                @unknown default:
                    fatalError("OH NO!")
                }
            }
        }
        addMediaButton.addAction(action, for: .touchUpInside)
    }
    
    func configureTakeMediaButton() {
        var config = UIButton.Configuration.tinted()
        config.title = String(localized: "takeNewMediaButtonTitle")
        config.image = UIImage(systemName: "camera")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.cornerStyle = Constants.buttonCornerStyle
        config.contentInsets = .init(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        
        takeMediaButton = UIButton(configuration: config)
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            
            configureCameraPicker()
            present(cameraPicker, animated: true)
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
            MediaPlaceholderViewCell.self,
            forCellWithReuseIdentifier: MediaPlaceholderViewCell.reuseIdentifier
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
        
        let buttonContainerHeight = buttonContainer.frame.height
        let spacingBetweenViews: CGFloat = items.isEmpty ? 0 : 8
        let totalHeightWithButtons = totalHeight + buttonContainerHeight + spacingBetweenViews
        
        delegate?.updateContentHeight(totalHeightWithButtons)
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
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaPlaceholderViewCell.reuseIdentifier,
            for: indexPath
        ) as? MediaPlaceholderViewCell else {
            return UICollectionViewCell()
        }
        
        let item = items[indexPath.item]
        cell.setup(with: item, isRemovable: true)
        
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
        worker.deleteMedia(items[indexPath.item]) {
            DispatchQueue.main.async { [weak self] in
                self?.items.remove(at: indexPath.item)
                self?.collectionView.deleteItems(at: [indexPath])
            }
        }
    }
}

private extension MediaContainerViewController {
    func processSaveAction(
        for publisher: AnyPublisher<MediaEntry, MediaFileWorkerError>
    ) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.logger.error("Error saving media: \(error)")
                    }
                },
                receiveValue: { entry in
                    self.items.append(entry)
                    self.collectionView.insertItems(
                        at: [IndexPath(
                            item: self.items.count - 1,
                            section: 0
                        )]
                    )
                    self.updateCollectionViewHeight()
                }
            )
            .store(in: &cancellables)
    }
}

extension MediaContainerViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        results.forEach { result in
            processSaveAction(for: worker.saveMedia(forEntry: nil, result: result))
        }
        
        picker.dismiss(animated: true)
    }
}

extension MediaContainerViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else { return }
        
        processSaveAction(for: worker.saveMedia(forEntry: geoEntry, image: image))
        
        dismiss(animated: true)
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
