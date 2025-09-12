//
//  MediaCardViewModel.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import Foundation
import CoreStore
import UIKit

protocol MediaCardViewModelProtocol: AnyObject {
    var mediaType: MediaType { get }
    var mediaURL: URL { get }
    
    var cachedImage: UIImage { get }
    
    init(mediaEntry: MediaEntry)
}

final class MediaCardViewModel: MediaCardViewModelProtocol {
    internal struct Entry {
        let fileName: String
        let type: MediaType
    }
    
    private let entry: Entry
    private let cache = NSCache<NSString, UIImage>()
    
    var mediaType: MediaType {
        entry.type
    }
    
    var mediaURL: URL {
        guard !entry.fileName.isEmpty else {
            fatalError("Impossible to not have file name")
        }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appending(path: entry.fileName)
    }
    
    var cachedImage: UIImage {
        if let image = cache.object(forKey: NSString(string: entry.fileName)) {
            return image
        } else {
            let image = UIImage(contentsOfFile: mediaURL.path())!
            cache.setObject(image, forKey: NSString(string: entry.fileName))
            return image
        }
    }
    
    init(mediaEntry: MediaEntry) {
        let existing = Dependencies.dataStack.fetchExisting(mediaEntry)!
        self.entry = .init(
            fileName: existing.mediaPath,
            type: MediaType(rawValue: existing.mediaType)!
        )
    }
}
