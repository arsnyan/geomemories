//
//  Constants.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 28.08.2025.
//

import UIKit

final class Constants {
    static var cornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            22
        } else {
            8
        }
    }
    
    static var buttonCornerStyle: UIButton.Configuration.CornerStyle {
        if #available(iOS 26.0, *) {
            .large
        } else {
            .medium
        }
    }
}
