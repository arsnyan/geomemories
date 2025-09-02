//
//  CreateEditEntryViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import SnapKit
import MapKit

// MARK: - View Protocol
protocol CreateEditEntryDisplayLogic: AnyObject {
    func configureNavigationBarTitle(
        viewModel: CreateEditEntry.ConfigurePurpose.ViewModel
    )
    func setInitialTexts(viewModel: CreateEditEntry.ConfigureInitial.ViewModel)
    
    func dismissView()
}

// MARK: - View Controller
class CreateEditEntryViewController: UIViewController {
    var interactor: CreateEditEntryBusinessLogic?
    var router: (NSObjectProtocol & CreateEditEntryRoutingLogic & CreateEditEntryDataPassing)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var searchLocation: SearchLocationContainerViewController!
    private var entryTitleTextField: RoundedCornersTextField!
    
    private var entryDescriptionContainer: UIStackView!
    private var entryDescriptionTextView: UITextView!
    
    private var mediaContainer: MediaContainerViewController!
    private var mediaContainerHeightConstraint: Constraint?
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - CreateEditEntryDisplayLogic
extension CreateEditEntryViewController: CreateEditEntryDisplayLogic {
    func configureNavigationBarTitle(viewModel: CreateEditEntry.ConfigurePurpose.ViewModel) {
        title = viewModel.title
    }
    
    func dismissView() {
        dismiss(animated: true)
    }
    
    func setInitialTexts(viewModel: CreateEditEntry.ConfigureInitial.ViewModel) {
        entryTitleTextField.text = viewModel.title
        entryDescriptionTextView.text = viewModel.description
    }
}

// MARK: - Private selector methods
@objc private extension CreateEditEntryViewController {
    func dismissSheet() {
        interactor?.clearMediaInfo()
        dismiss(animated: true)
    }
    
    func saveEntry() {
        interactor?.saveEntry(
            request: .init(
                title: entryTitleTextField.text ?? "",
                description: entryDescriptionTextView.text ?? ""
            )
        )
    }
}

// MARK: - UI Setup
private extension CreateEditEntryViewController {
    func setupUI() {
        interactor?.provideNavigationBarTitle()
        interactor?.provideInitialValues()
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSheet)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveEntry)
        )
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        setupSearchLocationContainer()
        setupTitleTextField()
        setupDescriptionContainer()
        setupMediaContainer()
    }
    
    func setupSearchLocationContainer() {
        searchLocation = SearchLocationContainerViewController()
        SearchLocationContainerConfigurator.shared.configure(
            viewController: searchLocation,
            with: router?.dataStore?.entry
        )
        searchLocation.interactor?.delegate = interactor
        addChild(searchLocation)
        contentView.addSubview(searchLocation.view)
        
        searchLocation.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        searchLocation.didMove(toParent: self)
    }
    
    func setupTitleTextField() {
        entryTitleTextField = RoundedCornersTextField()
        entryTitleTextField.placeholder = String(localized: "geoEntryTitleTextFieldPlaceholder")
        entryTitleTextField.backgroundColor = .systemGray6
        entryTitleTextField.layer.cornerRadius = Constants.cornerRadius
        entryTitleTextField.clearButtonMode = .whileEditing
        entryTitleTextField.returnKeyType = .next
        entryTitleTextField.delegate = self
        
        let icon = UIImage(systemName: "text.cursor")
        let imageView = UIImageView(image: icon)
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.width.equalTo(24)
        }
        entryTitleTextField.leftView = imageView
        entryTitleTextField.leftViewMode = .always
        
        contentView.addSubview(entryTitleTextField)
        
        entryTitleTextField.snp.makeConstraints { make in
            make.top.equalTo(searchLocation.view.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    func setupDescriptionContainer() {
        let icon = UIImage(systemName: "note.text")
        let imageView = UIImageView(image: icon)
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(24)
        }
        
        let label = UILabel()
        label.text = String(localized: "geoEntryDescriptionTextFieldPlaceholder")
        label.numberOfLines = 1
        label.textColor = .systemGray2
        
        let header = UIStackView(arrangedSubviews: [imageView, label])
        header.axis = .horizontal
        header.spacing = 8
        header.distribution = .fillProportionally
        header.alignment = .fill
        header.backgroundColor = .systemGray5
        header.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        header.isLayoutMarginsRelativeArrangement = true
        
        header.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        entryDescriptionTextView = UITextView()
        entryDescriptionTextView.backgroundColor = .clear
        entryDescriptionTextView.textContainerInset = .init(
            top: 8,
            left: 16,
            bottom: 8,
            right: 16
        )
        entryDescriptionTextView.font = .systemFont(ofSize: 17)
        entryDescriptionTextView.snp.makeConstraints { make in
            make.height.equalTo(160)
        }
        
        entryDescriptionContainer = UIStackView(
            arrangedSubviews: [
                header,
                entryDescriptionTextView
            ]
        )
        entryDescriptionContainer.axis = .vertical
        entryDescriptionContainer.spacing = 0
        entryDescriptionContainer.alignment = .fill
        entryDescriptionContainer.distribution = .fill
        entryDescriptionContainer.backgroundColor = .systemGray6
        entryDescriptionContainer.layer.cornerRadius = Constants.cornerRadius
        entryDescriptionContainer.layer.masksToBounds = true
        
        contentView.addSubview(entryDescriptionContainer)
        
        entryDescriptionContainer.snp.makeConstraints { make in
            make.top.equalTo(entryTitleTextField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    func setupMediaContainer() {
        mediaContainer = MediaContainerViewController()
        mediaContainer.delegate = self
        mediaContainer.geoEntry = router?.dataStore?.entry
        addChild(mediaContainer)
        contentView.addSubview(mediaContainer.view)
        
        mediaContainer.view.snp.makeConstraints { make in
            make.top.equalTo(entryDescriptionContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            mediaContainerHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(16)
        }
        mediaContainer.didMove(toParent: self)
    }
    
    func showAlert(with title: String, message: String, performing actions: [UIAlertAction] = []) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        actions.forEach { alertController.addAction($0) }
        alertController.addAction(
            UIAlertAction(
                title: String(localized: "ok"),
                style: .default
            )
        )
        present(alertController, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension CreateEditEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == entryTitleTextField {
            entryDescriptionTextView.becomeFirstResponder()
        }
        return true
    }
}

extension CreateEditEntryViewController: MediaContainerViewControllerDelegate {
    func updateContentHeight(_ height: CGFloat) {
        mediaContainerHeightConstraint?.update(offset: height)
        
        UIView.animate(withDuration: 0.25) { [unowned self] in
            view.layoutIfNeeded()
        }
    }
    
    func mediaItemsDidChange(_ items: [MediaEntry]) {
        interactor?.updateMediaItems(request: .init(mediaItems: items))
    }
}

#if DEBUG
import SwiftUI

struct CreateEditEntryViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CreateEditEntryViewController {
        let viewController = CreateEditEntryViewController()
        CreateEditEntryConfigurator.shared.configure(with: viewController)
        // Configure with mock dependencies if necessary
        return viewController
    }
    func updateUIViewController(_ uiViewController: CreateEditEntryViewController, context: Context) {}
}

#Preview {
    CreateEditEntryViewControllerPreview()
}
#endif
