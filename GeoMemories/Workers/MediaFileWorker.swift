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

// MARK: - Errors
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

// MARK: - Protocol
protocol MediaFileWorkerProtocol {
    func loadMediaPlaceholder(
        from mediaEntry: MediaEntry
    ) -> AnyPublisher<UIImage, MediaFileWorkerError>
    
    func saveMedia(
        forEntry geoEntry: GeoEntry?,
        result: PHPickerResult
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError>
    
    func saveMedia(
        forEntry geoEntry: GeoEntry?,
        image: UIImage
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError>
    
    func deleteMedia(_ entry: MediaEntry, completionHandler: @escaping () -> Void)
}

// MARK: - Worker itself
final class MediaFileWorker: MediaFileWorkerProtocol {
    // MARK: - Dependencies and Logging
    private let logger = Logger(subsystem: "GeoMemories", category: "FileService")
    private let storageService: StorageServiceProtocol
    
    // MARK: - Properties and Init
    
    private let placeholderCache = NSCache<NSString, UIImage>()
    
    internal init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }
    
    // MARK: - Cell Image Loading
    
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
    
    // MARK: - Saving Media — Wrappers
    
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
    
    func saveMedia(forEntry geoEntry: GeoEntry?, image: UIImage) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return save(image: image, forGeoEntry: geoEntry).eraseToAnyPublisher()
    }
    
    // MARK: - Saving Media — Private Generic Functions
    
    private func save(
        videoAt sourceURL: URL,
        forGeoEntry geoEntry: GeoEntry? = nil
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future<String, MediaFileWorkerError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noSelfFound))
                return
            }
            
            let fileName = UUID().uuidString + "." + sourceURL.pathExtension
            let destinationURL = getDocumentsDirectory(appending: fileName)
            
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                promise(.success(fileName))
            } catch {
                logger.error("\(MediaFileWorkerError.copyError(error: error).errorDescription)")
            }
        }
        .flatMap { [storageService] fileName -> AnyPublisher<MediaEntry, MediaFileWorkerError> in
            storageService.addMediaEntry(
                of: .video,
                withPath: fileName,
                for: geoEntry
            )
            .mapError { MediaFileWorkerError.storageServiceError(error: $0) }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    private func save(
        image: UIImage,
        forGeoEntry geoEntry: GeoEntry? = nil
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future<String, MediaFileWorkerError> { [weak self] promise in
            guard let self else {
                promise(.failure(.noSelfFound))
                return
            }
            
            let imageName = UUID().uuidString + ".jpg"
            let imagePath = getDocumentsDirectory(appending: imageName)
            
            guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
                promise(.failure(.readingError(error: nil)))
                return
            }
            
            do {
                try jpegData.write(to: imagePath)
                promise(.success(imageName))
            } catch {
                logger.error("There was an error copying the image to the documents directory: \(error.localizedDescription)")
                promise(.failure(.copyError(error: error)))
            }
        }
        .flatMap { [storageService] imageName -> AnyPublisher<MediaEntry, MediaFileWorkerError> in
            return storageService.addMediaEntry(
                of: .image,
                withPath: imageName,
                for: geoEntry
            )
            .mapError { MediaFileWorkerError.storageServiceError(error: $0) }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Saving Media — Generic Functions for each use case
    
    private func saveVideo(
        forGeoEntry geoEntry: GeoEntry? = nil,
        provider: NSItemProvider
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future<URL, MediaFileWorkerError> { promise in
            provider.loadFileRepresentation(
                forTypeIdentifier: UTType.movie.identifier
            ) { url, error in
                guard let url,
                      error == nil else {
                    promise(.failure(.readingError(error: error)))
                    return
                }
                
                promise(.success(url))
            }
        }
        .flatMap { [weak self] url -> AnyPublisher<MediaEntry, MediaFileWorkerError> in
            guard let self else {
                return Fail(error: MediaFileWorkerError.noSelfFound)
                    .eraseToAnyPublisher()
            }
            
            return self.save(videoAt: url, forGeoEntry: geoEntry)
        }
        .eraseToAnyPublisher()
    }
    
    private func saveImage(
        forGeoEntry geoEntry: GeoEntry? = nil,
        provider: NSItemProvider
    ) -> AnyPublisher<MediaEntry, MediaFileWorkerError> {
        return Future<UIImage, MediaFileWorkerError> { promise in
            provider.loadObject(ofClass: UIImage.self) { object, error in
                guard let image = object as? UIImage,
                      error == nil else {
                    promise(.failure(.readingError(error: error)))
                    return
                }
                
                promise(.success(image))
            }
        }
        .flatMap { [weak self] image -> AnyPublisher<MediaEntry, MediaFileWorkerError> in
            guard let self else {
                return Fail(error: MediaFileWorkerError.noSelfFound)
                    .eraseToAnyPublisher()
            }
            
            return save(image: image, forGeoEntry: geoEntry)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete Media
    
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
    
    // MARK: - Helper Functions
    
    private func getDocumentsDirectory(appending fileName: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appending(path: fileName)
    }
}
