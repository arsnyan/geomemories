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
import CoreStore

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
    func loadMediaPlaceholder(
        from mediaEntry: MediaEntry
    ) -> AnyPublisher<UIImage, MediaFileWorkerError>
    
    func saveMedia(
        forEntry geoEntry: GeoEntry?,
        result: PHPickerResult
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError>
    
    func deleteMedia(_ entry: MediaEntry, completionHandler: @escaping () -> Void)
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
        return CoreStoreDefaults.dataStack.reactive.perform { [weak self] transaction -> UIImage in
            guard let self else {
                throw MediaFileWorkerError.noSelfFound
            }
            
            let mediaEntry = transaction.fetchExisting(mediaEntry)!
            
            if let image = placeholderCache.object(
                forKey: NSString(string: mediaEntry.mediaPath)
            ) {
                return image
            }
            
            let pathUrl = getDocumentsDirectory(appending: mediaEntry.mediaPath)
            
            if mediaEntry.mediaType == MediaType.image.rawValue {
                return try loadImagePlaceholder(from: pathUrl.path())
            } else if mediaEntry.mediaType == MediaType.video.rawValue {
                return try loadVideoPlaceholder(from: pathUrl, for: mediaEntry.mediaPath)
            } else {
                throw MediaFileWorkerError.unsupportedFormat
            }
        }
        .mapError({ .storageServiceError(error: .coreStoreError($0)) })
        .eraseToAnyPublisher()
    }
    
    func saveMedia(
        forEntry geoEntry: GeoEntry? = nil,
        result: PHPickerResult
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        let provider = result.itemProvider
        
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return saveVideo(forGeoEntry: geoEntry, provider: provider)
                .eraseToAnyPublisher()
        } else if provider.canLoadObject(ofClass: UIImage.self) {
            return saveImage(forGeoEntry: geoEntry, provider: provider)
                .eraseToAnyPublisher()
        } else {
            logger.error("\(MediaFileWorkerError.unsupportedFormat.errorDescription)")
            return Fail(error: MediaFileWorkerError.unsupportedFormat)
                .eraseToAnyPublisher()
        }
    }
    
    private func loadImagePlaceholder(from mediaPath: String) throws -> UIImage {
        guard let image = UIImage(contentsOfFile: mediaPath) else {
            throw MediaFileWorkerError.readingError(error: nil)
        }
        
        placeholderCache.setObject(
            image,
            forKey: NSString(string: mediaPath)
        )
        
        return image
    }
    
    private func loadVideoPlaceholder(
        from pathUrl: URL,
        for mediaPath: String
    ) throws -> UIImage {
        let asset = AVURLAsset(url: pathUrl)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            
            placeholderCache.setObject(
                image,
                forKey: NSString(string: mediaPath)
            )
            
            return image
        } catch {
            throw MediaFileWorkerError.readingError(error: error)
        }
    }
    
    private func saveVideo(
        forGeoEntry geoEntry: GeoEntry? = nil,
        provider: NSItemProvider
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future { promise in
            provider.loadFileRepresentation(
                forTypeIdentifier: UTType.movie.identifier
            ) { [weak self] url, error in
                guard let self,
                      let url,
                      error == nil else {
                    promise(.failure(.readingError(error: error)))
                    return
                }
                
                let fileName = UUID().uuidString + ".mov"
                let destinationURL = getDocumentsDirectory(appending: fileName)
                
                do {
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                } catch {
                    logger.error("\(MediaFileWorkerError.copyError(error: error).errorDescription)")
                    promise(.failure(.copyError(error: error)))
                }
                
                storageService.addMediaEntry(
                    of: .video,
                    withPath: fileName,
                    for: geoEntry
                )
                .mapError { MediaFileWorkerError.storageServiceError(error: $0) }
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case let .failure(error) = completion {
                            self?.logger.error("\(error.localizedDescription)")
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
        .eraseToAnyPublisher()
    }
    
    private func saveImage(
        forGeoEntry geoEntry: GeoEntry? = nil,
        provider: NSItemProvider
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future { promise in
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self,
                      let image = object as? UIImage,
                      error == nil else {
                    promise(.failure(.readingError(error: error)))
                    return
                }
                
                let imageName = UUID().uuidString + ".jpg"
                let imagePath = getDocumentsDirectory(appending: imageName)
                if let jpegData = image.jpegData(compressionQuality: 0.95) {
                    do {
                        try jpegData.write(to: imagePath)
                    } catch {
                        promise(.failure(.copyError(error: error)))
                    }
                    
                    storageService.addMediaEntry(
                        of: .image,
                        withPath: imageName,
                        for: geoEntry
                    )
                    .mapError({ MediaFileWorkerError.storageServiceError(error: $0) })
                    .receive(on: DispatchQueue.global())
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
        .eraseToAnyPublisher()
    }
    
    func deleteMedia(_ entry: MediaEntry, completionHandler: @escaping () -> Void) {
        CoreStoreDefaults.dataStack.perform(
            asynchronous: { transaction in
                let existing = transaction.fetchExisting(entry)!
                transaction.delete(existing)
            },
            completion: { [weak self] completion in
                switch completion {
                case .success(_):
                    completionHandler()
                case .failure(let error):
                    self?.logger.error("Something went wrong while deleting media: \(error)")
                }
            }
        )
    }
    
    private func getDocumentsDirectory(appending fileName: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appending(path: fileName)
    }
}
