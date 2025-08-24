//
//  MemoryAnnotationView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 20.08.2025.
//

import UIKit
import MapKit

class MemoryAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "MemoryAnnotationView"
    
    override var annotation: MKAnnotation? {
        didSet {
            guard let memoryAnnotation = annotation as? MemoryAnnotation else { return }
            
            // TODO: - really would rather make a custom clustering image — https://medium.com/mobilepeople/enhance-your-map-experience-with-annotations-13e28507f892
            clusteringIdentifier = "memories"
            
            if let baseImage = memoryAnnotation.image {
                glyphImage = circularImage(
                    from: baseImage,
                    size: CGSize(
                        width: 48,
                        height: 48
                    )
                )
                markerTintColor = .clear
                glyphTintColor = nil
            } else {
                glyphImage = nil
                markerTintColor = .systemRed
            }
        }
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
