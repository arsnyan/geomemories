//
//  HomeScreen.swift
//  GeoMemoriesUITests
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import XCTest
@testable import GeoMemories

final class HomeScreen: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testExample() throws {
        // Given
        
        
        // When
        
        
        // Then
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
