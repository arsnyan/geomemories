//
//  MediaContainerViewController.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 26.08.2025.
//

import UIKit

class MediaContainerViewController: UIViewController {
    private var addMediaButton: UIButton!
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
}

// MARK: - UI Configuration
private extension MediaContainerViewController {
    func setupUI() {
        configureAddMediaButton()
    }
    
    func configureAddMediaButton() {
        addMediaButton = UIButton()
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
