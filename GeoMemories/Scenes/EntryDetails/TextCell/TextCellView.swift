//
//  TextCellView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import UIKit
import SnapKit

final class TextCellView: UICollectionViewCell {
    static let reuseIdentifier = "TextCell"
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(safeAreaInsets)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String) {
        textLabel.text = text
    }
}
