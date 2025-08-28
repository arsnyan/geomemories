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

enum FileServiceError: LocalizedError {
    case storageServiceError(error: StorageServiceError)
    case unsupportedFormat
    case copyError(error: Error)
    
    var errorDescription: String {
        switch self {
        case .storageServiceError(let error):
            error.localizedDescription
        case .unsupportedFormat:
            "The picker result is not a supported format"
        case .copyError(let error):
            "Failed to copy file: \(error.localizedDescription)"
        }
    }
}

protocol FileServiceProtocol {
    
}

final class FileService: FileServiceProtocol {
    private let logger = Logger(subsystem: "GeoMemories", category: "FileService")
    private let storageService: StorageServiceProtocol
    
    private var cancellables: Set<AnyCancellable> = []
    
    internal init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }
    
    func saveMedia(
        forEntry geoEntry: GeoEntry? = nil,
        result: PHPickerResult
    ) -> AnyPublisher<MediaEntry, FileServiceError> {
        return Future<MediaEntry, FileServiceError>() { promise in
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
                            withPath: destinationURL.absoluteString,
                            for: geoEntry
                        )
                        .mapError { FileServiceError.storageServiceError(error: $0) }
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
                            .mapError({ FileServiceError.storageServiceError(error: $0) })
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
