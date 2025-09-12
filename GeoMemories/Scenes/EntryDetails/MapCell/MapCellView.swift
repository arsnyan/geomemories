//
//  MapCellView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import UIKit
import CoreLocation
import SnapKit
import MapKit

class MapCellView: UICollectionViewCell {
    static let reuseIdentifier = "MapCell"
    
    // MARK: - Properties
    
    var coords: CLLocationCoordinate2D? {
        didSet {
            if let coords {
                map.camera = MKMapCamera(
                    lookingAtCenter: coords,
                    fromDistance: 300,
                    pitch: 20,
                    heading: 90
                )
            }
        }
    }
    
    // MARK: - UI Elements
    
    private var map: MKMapView!
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Setup
private extension MapCellView {
    func setupUI() {
        map = MKMapView()
        map.layer.cornerRadius = 16
        map.layer.masksToBounds = true
        
        map.showsUserLocation = false
        
        map.isZoomEnabled = true
        map.isPitchEnabled = true
        map.isRotateEnabled = true
        map.isScrollEnabled = false
        map.showsCompass = false
        
        let config = MKHybridMapConfiguration(elevationStyle: .realistic)
        config.pointOfInterestFilter = .excludingAll
        config.showsTraffic = false
        map.preferredConfiguration = config
        
        addSubview(map)
        
        map.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(350)
        }
    }
}
