//
//  MemoryAnnotationView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//

import UIKit
import MapKit

class MemoryAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "MemoryAnnotationView"
    
    private let detailView = MemoryCalloutDetailView()
    
    override var annotation: MKAnnotation? {
        didSet {
            guard let memoryAnnotation = annotation as? MemoryAnnotation else { return }
            
            if let baseImage = memoryAnnotation.icon {
                image = circularImage(
                    from: baseImage,
                    size: CGSize(
                        width: 48,
                        height: 48
                    )
                )
            } else {
                image = UIImage(systemName: "xmark.circle.fill")
            }
            
            detailView.configure(with: memoryAnnotation)
        }
    }
    
    override init(annotation: MKAnnotation? = nil, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = true
        detailCalloutAccessoryView = detailView
        
        var config = UIButton.Configuration.glassOrPlain()
        config.contentInsets = .zero
        config.image = UIImage(systemName: "square.and.pencil")
        let editButton = UIButton(configuration: config)
        editButton.sizeToFit()
        
        var seeFullConfig = config
        seeFullConfig.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
        let seeFullButton = UIButton(configuration: seeFullConfig)
        seeFullButton.sizeToFit()
        
        leftCalloutAccessoryView = editButton
        rightCalloutAccessoryView = seeFullButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func circularImage(from image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let circlePath = UIBezierPath(ovalIn: rect)
            circlePath.addClip()
            
            image.draw(in: rect)
            
            UIColor.systemGray6.setStroke()
            circlePath.lineWidth = 1
            circlePath.stroke()
        }
    }
}

extension UIButton.Configuration {
    static func glassOrPlain() -> UIButton.Configuration {
        if #available(iOS 26.0, *) {
            glass()
        } else {
            plain()
        }
    }
}
