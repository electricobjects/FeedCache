//
//  FeedKitTests.swift
//  FeedKitTests
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import UIKit
import XCTest
import FeedKit




class FeedControllerTests: XCTestCase, FeedKitDelegate {
    
    let testItems : [FeedItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
    var delegateResponseExpectation: XCTestExpectation?
    var feedController: FeedController!
    
    var itemsAdded: [NSIndexPath]?
    var itemsDeleted: [NSIndexPath]?
    
    override func setUp() {
        super.setUp()
        feedController = FeedController(feedType: TestFeedKitType.TestFeedType, cachingOn: true, section: 0)
        feedController.delegate = self
        feedController.cache?.addItems(self.testItems)
        feedController.cache?.waitUntilSynchronized()
        feedController.loadCacheSynchronously()
    }
    
    override func tearDown() {
        feedController.cache?.clearCache()
        feedController.cache?.waitUntilSynchronized()
        super.tearDown()
    }

    
    func test_feedKitCacheLoad() {
        feedController.loadCacheSynchronously()
        XCTAssert(feedController.items.count > 0)
    }

    func test_allNewItems(){
        MockService.mockResponseItems = [TestItem(name: "foo"), TestItem(name: "bar"), TestItem(name: "baz")]
        
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        feedController.fetchItems(1, itemsPerPage: 10, parameters: nil)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            if let itemsAdded = self.itemsAdded, itemsDeleted = self.itemsDeleted {
                XCTAssert(itemsAdded.count == 3)
                XCTAssert(itemsDeleted.count == 3)
            }
            else {
                XCTAssert(false)
            }
        }
    }
    
    func test_oneNewItem(){
        MockService.mockResponseItems = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "baz")]
        
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        feedController.fetchItems(1, itemsPerPage: 10, parameters: nil)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            if let itemsAdded = self.itemsAdded, itemsDeleted = self.itemsDeleted {
                XCTAssert(itemsAdded.count == 1)
                XCTAssert(itemsDeleted.count == 1)
            }
            else {
                XCTAssert(false)
            }
        }
    }
    
    func test_addPages(){
        MockService.mockResponseItems = [TestItem(name: "foo"), TestItem(name: "bar"), TestItem(name: "baz")]
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        feedController.fetchItems(2, itemsPerPage: 10, parameters: nil)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            if let itemsAdded = self.itemsAdded, itemsDeleted = self.itemsDeleted {
                XCTAssert(itemsAdded.count == 3)
                XCTAssert(itemsDeleted.count == 0)
            }
            else {
                XCTAssert(false)
            }
            XCTAssert(self.feedController.items.count == 6)
        }
    }
    
    //MARK: FeedKit Delegate methods
    
    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]){
        self.itemsAdded = itemsAdded
        self.itemsDeleted = itemsDeleted
        self.delegateResponseExpectation?.fulfill()
    }
}
