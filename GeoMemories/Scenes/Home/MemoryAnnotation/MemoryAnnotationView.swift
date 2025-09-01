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
    
    override var annotation: MKAnnotation? {
        didSet {
            guard let memoryAnnotation = annotation as? MemoryAnnotation else { return }
            
            // swiftlint:disable line_length
            // TODO: - really would rather make a custom clustering image — https://medium.com/mobilepeople/enhance-your-map-experience-with-annotations-13e28507f892
            clusteringIdentifier = "memories"
            
            if let baseImage = memoryAnnotation.image {
                image = circularImage(
                    from: baseImage,
                    size: CGSize(
                        width: 48,
                        height: 48
                    )
                )
//                markerTintColor = .clear
//                glyphTintColor = nil
            } else {
                image = UIImage(systemName: "xmark.circle.fill")
//                glyphImage = nil
//                markerTintColor = .systemRed
            }
        }
    }
    
    override init(annotation: MKAnnotation? = nil, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = true
        // detailCalloutAccessoryView = 
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
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
