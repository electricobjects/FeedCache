//
//  FeedKitTests.swift
//  FeedKitTests
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import UIKit
import XCTest
@testable import FeedKit


class FeedControllerTests: XCTestCase, FeedKitControllerDelegate {
    
    let testItems : [TestItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
    var delegateResponseExpectation: XCTestExpectation?
    var feedController: FeedController<TestItem>!
    
    var itemsAdded: [NSIndexPath]?
    var itemsDeleted: [NSIndexPath]?
    
    override func setUp() {
        super.setUp()
        feedController = FeedController<TestItem>(cachePreferences: TestFeedKitCachePreferences.CacheOn, section: 0)
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
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: true, pageNumber: 1, itemsPerPage: 10)
        feedController.fetchItems(request)
        
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
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: true, pageNumber: 1, itemsPerPage: 10)
        feedController.fetchItems(request)
        
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
    
    func test_redundantRequest(){
        MockService.mockResponseItems = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: false, pageNumber: 1, itemsPerPage: 10)
        feedController.fetchItems(request)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            if let itemsAdded = self.itemsAdded, itemsDeleted = self.itemsDeleted {
                XCTAssert(itemsAdded.count == 0)
                XCTAssert(itemsDeleted.count == 0)
            }
            else {
                XCTAssert(false)
            }
            XCTAssert(self.feedController.items.count == 3)
        }
    }
    
    func test_addPages(){
        MockService.mockResponseItems = [TestItem(name: "foo"), TestItem(name: "bar"), TestItem(name: "baz")]
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: false, pageNumber: 2, itemsPerPage: 10)
        feedController.fetchItems(request)
        
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
    
    func test_insertItem(){
        let insertItem = TestItem(name: "InsertTest")
        feedController.insertItem(insertItem, atIndex: 0)
        XCTAssert(feedController.items[0] == insertItem)
        
        feedController.loadCacheSynchronously()
        XCTAssert(feedController.items[0] == insertItem)
    }

    func test_deleteItem(){
        feedController.removeItemAtIndex(0)
        XCTAssert(feedController.items[0] == testItems[1])
        feedController.loadCacheSynchronously()
        XCTAssert(feedController.items[0] == testItems[1])
    }
    
    func test_noCache(){
        let testItem = TestItem(name: "No Cache")
        MockService.mockResponseItems = [testItem]
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        
        let cachelessFc = FeedController<TestItem>(cachePreferences: TestFeedKitCachePreferences.CacheOff, section: 0)
        cachelessFc.delegate = self
        
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: true, pageNumber: 1, itemsPerPage: 10)
        cachelessFc.fetchItems(request)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            XCTAssert(cachelessFc.items == [testItem])
        }

    }
    
    func test_nonUniqueItems(){
        MockService.mockResponseItems = [TestItem(name: "1"), TestItem(name: "1"), TestItem(name: "2"), TestItem(name: "3")]
        let cacheItems =  [TestItem(name: "2"), TestItem(name: "3"), TestItem(name: "4")]
        
        self.delegateResponseExpectation = self.expectationWithDescription("delegate expectation")
        
        feedController.cache?.clearCache()
        feedController.cache?.addItems(cacheItems)
        feedController.loadCacheSynchronously()
        let itemsCount = feedController.items.count
        let request = TestFeedKitRequest(clearStaleDataOnCompletion: false, pageNumber: 2, itemsPerPage: 10)
        feedController.fetchItems(request)
        
        self.waitForExpectationsWithTimeout(1.0) { (error) -> Void in
            guard let itemsAdded = self.itemsAdded, itemsDeleted = self.itemsDeleted else { XCTAssert(false); return}
            let beforeCount = itemsCount
            let afterCount = self.feedController.items.count
            
            XCTAssert(beforeCount + itemsAdded.count - itemsDeleted.count == afterCount)
        }
    }
    
    func test_uniqueCacheLoading(){
        let cacheItems =  [TestItem(name: "2"), TestItem(name: "2"), TestItem(name: "3"), TestItem(name: "4")]
        feedController.cache?.clearCache()
        feedController.cache?.addItems(cacheItems)
        feedController.loadCacheSynchronously()
        XCTAssert(feedController.items.count == 3)
    }
    
    func test_cacheLoadingPerformance(){
        var numberStrings = [String]()
        for i in 0...10000 {
            numberStrings.append(String(i))
        }
        let cacheItems =  numberStrings.map({TestItem(name: $0)})
        feedController.cache?.clearCache()
        feedController.cache?.addItems(cacheItems)
        measureBlock { () -> Void in
            self.feedController.loadCacheSynchronously()
        }
    }
    
    
    //MARK: FeedKit Delegate methods
    
    func feedController(feedController: FeedControllerGeneric, itemsCopy: [AnyObject], itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]) {
        self.itemsAdded = itemsAdded
        self.itemsDeleted = itemsDeleted
        self.delegateResponseExpectation?.fulfill()
    }
    
    func feedController(feedController: FeedControllerGeneric, requestFailed error: NSError) {
        
    }
}
