//
//  MediaPlaceholderViewCell.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 30.08.2025.
//

import UIKit
import Combine
import SnapKit
import OSLog

class MediaPlaceholderViewCell: UICollectionViewCell {
    static let reuseIdentifier = "MediaPlaceholderViewCell"
    
    private var cancellable: AnyCancellable?
    private let worker: MediaFileWorkerProtocol = Dependencies.mediaFileWorker
    private let logger = Logger(subsystem: "GeoMemories", category: "Media Cell")
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cancellable?.cancel()
        cancellable = nil
    }
    
    func setup(with mediaEntry: MediaEntry, isRemovable: Bool) {
        cancellable = worker.loadMediaPlaceholder(from: mediaEntry)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.logger.error("Loading placeholder image failed: \(error)")
                    }
                },
                receiveValue: { image in
                    self.imageView.image = image
                    
                    if isRemovable {
                        let crossImage = UIImage(systemName: "xmark.circle.fill")
                        let crossImageView = UIImageView(image: crossImage)
                        crossImageView.tintColor = .systemGray
                        
                        self.imageView.addSubview(crossImageView)
                        
                        crossImageView.snp.makeConstraints { make in
                            make.size.equalTo(16)
                            make.top.trailing.equalToSuperview().inset(4)
                        }
                    }
                }
            )
    }
}
