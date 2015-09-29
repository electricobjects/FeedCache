//
//  CacheTests.swift
//  FeedKit
//
//  Created by Rob Seward on 7/21/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import XCTest
import FeedKit

class CacheTests: XCTestCase {
    let testItems : [TestItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
    let cache = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
    
    override func setUp() {
        cache.addItems(testItems)
        cache.waitUntilSynchronized()
        
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cache.clearCache()
        cache.waitUntilSynchronized()
        super.tearDown()
    }
    
    func test_001_addItemsToCache() {
        
        cache.clearCache()
        cache.waitUntilSynchronized()
        XCTAssert(cache.items.count == 0)
        
        cache.addItems(testItems)
        cache.waitUntilSynchronized()
        XCTAssert(cache.items.count > 0)
    }
    
    func test_005_fetchItemsFromCache() {
        
        //Test success is dependent on there already being items in the cache
        
        let cache = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
        let expectation = self.expectationWithDescription("Load cache expectation")
        var testSuccess = false
        cache.loadCache { (success) -> () in
            testSuccess = success && cache.items.count > 0
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            XCTAssert(testSuccess, "Load cache test")
        }
    }
    
    func test_010_clearCache() {
        //This test is dependent on the cache state being set by previous tests.
        //If the cache were already empty before this test was run it would
        //succeed even if it were not operating correctly
        
        //TODO: Refactor this so it is not dependant on previous tests
        
        let cache = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
        cache.loadCache { (success) -> () in
            print(success)
        }
        cache.waitUntilSynchronized()
        cache.clearCache()
        cache.waitUntilSynchronized()
        
        XCTAssert(cache.items.count == 0, "Cache is Empty")
    }
    
    func test_015_addMoreItems() {
        let cache = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
        cache.clearCache()
        let items1 : [TestItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
        let items2 : [TestItem] = [TestItem(name: "test2"), TestItem(name: "test3"), TestItem(name: "test4")]
        
        cache.addItems(items1)
        cache.loadCache()
        cache.waitUntilSynchronized()
        XCTAssert(cache.items.count == 3, "add more items")
        
        cache.addItems(items2)
        cache.loadCache()
        cache.waitUntilSynchronized()
        XCTAssert(cache.items.count == 6, "add more items")
    }
    
    func test_020_clearAllCaches() {
        let items1 : [TestItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
        var testCache: FeedCache<TestItem>? = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
        testCache!.addItems(items1)
        testCache = nil
        do {
           try deleteAllFeedKitCaches()
        } catch let error {
            print (error)
            XCTAssert(false)
        }
        testCache = FeedCache<TestItem>(name: TestFeedKitCachePreferences.CacheOn.cacheName)
        testCache!.loadCache()
        testCache!.waitUntilSynchronized()
        XCTAssert(testCache!.items.count == 0, "clear all caches")
    }
}