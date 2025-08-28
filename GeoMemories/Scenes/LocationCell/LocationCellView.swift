//
//  LocationCellView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 21.08.2025.
//

import UIKit

protocol LocationCellModelRepresentable {
    var viewModel: LocationCellViewModelProtocol? { get }
}

class LocationCellView: UITableViewCell {
    static let reuseIdentifier = "LocationCell"
    
    var viewModel: LocationCellViewModelProtocol? {
        didSet {
            updateView()
        }
    }
    
    private func updateView() {
        guard let viewModel else { return }
        
        var content = defaultContentConfiguration()
        content.text = viewModel.description
        backgroundColor = .clear
        selectionStyle = .gray
        
        contentConfiguration = content
    }
}
