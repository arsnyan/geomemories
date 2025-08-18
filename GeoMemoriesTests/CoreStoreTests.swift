//
//  CoreStoreTests.swift
//  GeoMemoriesTests
//
//  Created by Арсен Саруханян on 18.08.2025.
//

import XCTest
import CoreStore
@testable import GeoMemories

class MockSceneDelegate: CoreStoreConfiguratorProtocol {
    var dataStack: DataStack!
    
    func configureDataStack() {
        dataStack = DataStack(
            CoreStoreSchema(modelVersion: "V1", entities: [
                Entity<GeoEntry>("GeoEntry", uniqueConstraints: [[\.$id]]),
                Entity<MediaEntry>("MediaEntry", uniqueConstraints: [[\.$linkedGeoEntry]])
            ])
        )
    }
    
    func configureCoreStore() {
        configureDataStack()
        try! dataStack.addStorageAndWait(InMemoryStore())
        CoreStoreDefaults.dataStack = dataStack
    }
}

final class CoreStoreTests: XCTestCase {
    var sut: CoreStoreConfiguratorProtocol!
    
    override func setUp() {
        sut = MockSceneDelegate()
    }

    override func tearDown() {
        
    }

    func testDataStackConfiguredAndNotNil() {
        // Given
        sut = MockSceneDelegate()
        
        // When
        sut.configureCoreStore()
        
        // Then
        XCTAssertNotNil(sut.dataStack)
    }
    
    func testDelegateAddsGeoEntry_WhenPerformsTransactionOnDataStack() {
        // Given
        sut = MockSceneDelegate()
        sut.configureCoreStore()
        let expectation = expectation(description: "Should perform basic operations")
        
        // When
        sut.dataStack.perform(
            asynchronous: { transaction in
                let geoEntry = transaction.create(Into<GeoEntry>())
                geoEntry.title = "Test"
                geoEntry.description = "Test description"
                return geoEntry
            }, completion: { result in
                // Then
                switch result {
                case .success(let entry):
                    XCTAssertNotNil(entry)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Failed to create GeoEntry: \(error)")
                }
            }
        )
        
        wait(for: [expectation])
    }
    
    func testAppFailsWhenAddingDuplicate() throws {
        // Given
        sut = MockSceneDelegate()
        sut.configureCoreStore()
        let expectation = expectation(description: "Should fail when adding duplicate")
        
        // When
        sut.dataStack.perform(
            asynchronous: { transaction in
                let geoEntry = transaction.create(Into<GeoEntry>())
                geoEntry.title = "Test"
                geoEntry.description = "Test description"
                
                let duplicateGeoEntry = transaction.create(Into<GeoEntry>())
                duplicateGeoEntry.id = geoEntry.id
                duplicateGeoEntry.title = "Test"
                duplicateGeoEntry.description = "Test description"
                
                return duplicateGeoEntry
            },
            completion: { result in
                // Then
                switch result {
                case .success(_):
                    XCTFail("The object was duplicated")
                case .failure(let error):
                    print(error)
                    expectation.fulfill()
                }
            }
        )
        wait(for: [expectation])
    }
}
