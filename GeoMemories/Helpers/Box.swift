//
//  Box.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import Foundation

class Box<T> {
    typealias Listener = (T) -> Void
    
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    private var listener: Listener?
    
    init(_ value: T) {
        self.value = value
    }
    
    func bind(listener: @escaping Listener) {
        self.listener = listener
        listener(value)
    }
}
