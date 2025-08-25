//
//  RoundTextField.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 21.08.2025.
//

import UIKit

class RoundedCornersTextField: UITextField {
    private lazy var padding = UIEdgeInsets(
        top: 0,
        left: paddingValue,
        bottom: 0,
        right: paddingValue
    )
    
    @IBInspectable var paddingValue: CGFloat = 16
    
    @IBInspectable var borderColor: UIColor? = .clear {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        insetTextRect(forBounds: bounds)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        insetTextRect(forBounds: bounds)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        insetTextRect(forBounds: bounds)
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x += paddingValue
        return rect
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= paddingValue
        return rect
    }
    
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.clearButtonRect(forBounds: bounds)
        rect.origin.x -= paddingValue / 2
        return rect
    }
    
    private func insetTextRect(forBounds bounds: CGRect) -> CGRect {
        var insetBounds = bounds.inset(by: padding)
        if let rightView {
            insetBounds.size.width -= paddingValue + rightView.bounds.width
        }
        if let leftView {
            insetBounds.origin.x += leftView.bounds.width + paddingValue / 2
            insetBounds.size.width -= paddingValue + leftView.bounds.width
        }
        if clearButtonMode != .never {
            let clearRect = super.clearButtonRect(forBounds: bounds)
            insetBounds.size.width -= clearRect.width
        }
        return insetBounds
    }
}
