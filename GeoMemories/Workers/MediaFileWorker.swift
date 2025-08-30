//
//  FileService.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 28.08.2025.
//

import OSLog
import UIKit
import PhotosUI
import Combine
import AVFoundation

enum MediaFileWorkerError: LocalizedError {
    case storageServiceError(error: StorageServiceError)
    case unsupportedFormat
    case copyError(error: Error)
    case readingError(error: Error?)
    case noSelfFound
    
    var errorDescription: String {
        switch self {
        case .storageServiceError(let error):
            error.localizedDescription
        case .unsupportedFormat:
            "The picker result is not a supported format"
        case .copyError(let error):
            "Failed to copy file: \(error.localizedDescription)"
        case .readingError:
            "Failed to transform file contents to UIImage"
        case .noSelfFound:
            "Self was captured but not available. Something went wrong"
        }
    }
}

protocol MediaFileWorkerProtocol {
    
}

final class MediaFileWorker: MediaFileWorkerProtocol {
    private let logger = Logger(subsystem: "GeoMemories", category: "FileService")
    private let storageService: StorageServiceProtocol
    
    private let placeholderCache = NSCache<NSString, UIImage>()
    
    private var cancellables: Set<AnyCancellable> = []
    
    internal init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }
    
    func loadMediaPlaceholder(
        from mediaEntry: MediaEntry
    ) -> AnyPublisher<UIImage, MediaFileWorkerError> {
        if let image = placeholderCache.object(
            forKey: NSString(string: mediaEntry.mediaPath)
        ) {
            return Just(image)
                .setFailureType(to: MediaFileWorkerError.self)
                .eraseToAnyPublisher()
        }
        
        return Future<UIImage, MediaFileWorkerError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noSelfFound))
                return
            }
            
            let path = getDocumentsDirectory().appending(path: mediaEntry.mediaPath, directoryHint: .notDirectory)
            
            if mediaEntry.mediaType == MediaType.image.rawValue {
                guard let image = UIImage(contentsOfFile: path.path()) else {
                    promise(.failure(.readingError(error: nil)))
                    return
                }
                
                placeholderCache.setObject(
                    image,
                    forKey: NSString(string: mediaEntry.mediaPath)
                )
                
                promise(.success(image))
            } else if mediaEntry.mediaType == MediaType.video.rawValue {
                let asset = AVURLAsset(url: path)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
                
                do {
                    let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                    let image = UIImage(cgImage: imageRef)
                    
                    placeholderCache.setObject(
                        image,
                        forKey: NSString(string: mediaEntry.mediaPath)
                    )
                    
                    promise(.success(image))
                } catch {
                    promise(.failure(.readingError(error: error)))
                }
            } else {
                promise(.failure(.unsupportedFormat))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveMedia(
        forEntry geoEntry: GeoEntry? = nil,
        result: PHPickerResult
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future<MediaEntry, MediaFileWorkerError> { promise in
            let provider = result.itemProvider
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(
                    forTypeIdentifier: UTType.movie.identifier
                ) { [weak self] url, error in
                    guard let self else { return }
                    
                    if let url {
                        let fileName = UUID().uuidString + ".mov"
                        let destinationURL = getDocumentsDirectory().appending(
                            path: fileName,
                            directoryHint: .notDirectory
                        )
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                        } catch {
                            promise(.failure(.copyError(error: error)))
                        }
                        
                        storageService.addMediaEntry(
                            of: .video,
                            withPath: fileName,
                            for: geoEntry
                        )
                        .mapError { MediaFileWorkerError.storageServiceError(error: $0) }
                        .sink(
                            receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { mediaEntry in
                                promise(.success(mediaEntry))
                            }
                        )
                        .store(in: &cancellables)
                    } else {
                        logger.error("\(error)")
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self else { return }
                    
                    if let image = image as? UIImage {
                        let imageName = UUID().uuidString + ".jpg"
                        let imagePath = getDocumentsDirectory().appending(
                            path: imageName,
                            directoryHint: .notDirectory
                        )
                        if let jpegData = image.jpegData(compressionQuality: 0.95) {
                            try? jpegData.write(to: imagePath)
                            
                            storageService.addMediaEntry(
                                of: .image,
                                withPath: imagePath.absoluteString,
                                for: geoEntry
                            )
                            .mapError({ MediaFileWorkerError.storageServiceError(error: $0) })
                            .sink(
                                receiveCompletion: { completion in
                                    if case let .failure(error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { mediaEntry in
                                    promise(.success(mediaEntry))
                                }
                            )
                            .store(in: &cancellables)
                        }
                    }
                }
            } else {
                promise(.failure(.unsupportedFormat))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
