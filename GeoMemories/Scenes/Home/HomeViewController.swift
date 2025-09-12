//
//  HomeViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import UIKit
import SnapKit
import MapKit

protocol HomeDisplayLogic: AnyObject {
    func displayCurrentLocation(viewModel: Home.SelectCurrentLocation.ViewModel)
    // TODO: - Make show details functionality and `edit entry` action
    func displayMapEntries(viewModel: Home.ShowMapEntries.ViewModel)
}

class HomeViewController: UIViewController {
    let defaultPinIdentifier = "DefaultPin"
    
    var interactor: HomeBusinessLogic?
    var router: (NSObjectProtocol & HomeRoutingLogic & HomeDataPassing)?
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.register(
            MemoryAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MemoryAnnotationView.reuseIdentifier
        )
        map.showsUserLocation = true
        return map
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.center = view.center
        return indicator
    }()
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateEntries),
            name: NSNotification.Name("EntriesUpdated"),
            object: nil
        )
    }
}

// MARK: - MKMapViewDelegate
extension HomeViewController: MKMapViewDelegate {
    func mapView(
        _ mapView: MKMapView,
        viewFor annotation: any MKAnnotation
    ) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        if let memoryAnnotation = annotation as? MemoryAnnotation {
            let identifier = MemoryAnnotationView.reuseIdentifier
            var view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            )
            if view == nil {
                view = MemoryAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
            } else {
                view?.annotation = memoryAnnotation
            }
            return view
        }
        
        return nil
    }
    
    func mapView(
        _ mapView: MKMapView,
        annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl
    ) {
        guard let annotation = view.annotation as? MemoryAnnotation else { return }
        
        if control == view.leftCalloutAccessoryView {
            router?.routeToCreateEditEntry(geoEntry: annotation.geoEntry)
        } else {
            router?.routeToEntryDetails(geoEntry: annotation.geoEntry)
        }
    }
}

// MARK: - UI Setup
private extension HomeViewController {
    func setupToolbar() {
        let locationPinItem = UIBarButtonItem(
            image: UIImage(systemName: "location.fill"),
            style: .plain,
            target: self,
            action: #selector(locationPinToolbarButtonTapped)
        )
        
        let addItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addBarButtonTapped)
        )
        
        if #available(iOS 26.0, *) {
            toolbarItems = [.flexibleSpace(), addItem, .fixedSpace(), locationPinItem]
        } else {
            toolbarItems = [.flexibleSpace(), addItem, .fixedSpace(16), locationPinItem]
            
            if let toolbar = navigationController?.toolbar {
                let appearance = UIToolbarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
                toolbar.standardAppearance = appearance
                toolbar.scrollEdgeAppearance = appearance
            }
        }
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func setupUI() {
        defer { setupConstraints() }
        setupToolbar()
        mapView.delegate = self
        view.addSubview(mapView)
        interactor?.provideMapEntries()
    }
    
    func setupConstraints() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Private selector actions
@objc private extension HomeViewController {
    func locationPinToolbarButtonTapped() {
        interactor?.provideCurrentLocation()
    }
    
    func addBarButtonTapped() {
        router?.routeToCreateEditEntry(geoEntry: nil)
    }
    
    func updateEntries() {
        interactor?.provideMapEntries()
    }
}

// MARK: - Private methods
private extension HomeViewController {
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

extension HomeViewController: HomeDisplayLogic {
    func displayCurrentLocation(viewModel: Home.SelectCurrentLocation.ViewModel) {
        switch viewModel {
        case .loading:
            activityIndicator.startAnimating()
        case .success(let region):
            activityIndicator.stopAnimating()
            mapView.setRegion(region, animated: true)
        case .failure(let alertTitle, let alertMessage):
            activityIndicator.stopAnimating()
            self.showAlert(with: alertTitle, message: alertMessage)
        }
    }
    
    func displayMapEntries(viewModel: Home.ShowMapEntries.ViewModel) {
        switch viewModel {
        case .loading:
            activityIndicator.startAnimating()
        case .sucess(let annotations):
            activityIndicator.stopAnimating()
            mapView.addAnnotations(annotations)
        case .failure(let alertTitle, let alertMessage):
            activityIndicator.stopAnimating()
            self.showAlert(
                with: alertTitle,
                message: alertMessage,
                performing: [UIAlertAction(
                    title: String(localized: "retry"),
                    style: .default,
                    handler: { [weak self] _ in
                        self?.interactor?.provideMapEntries()
                    })]
            )
        }
    }
}
