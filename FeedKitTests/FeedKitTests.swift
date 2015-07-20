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


enum TestFeedKitType: FeedKitType {
    case TestFeedType
    
    var cacheName : String {
        return "test"
    }
    
    func fetchItems(page: Int, itemsPerPage: Int, success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
        var items: [FeedItem] = []
        if page == 1 {
            items = [TestItem(name: "Foo"), TestItem(name: "Bar"), TestItem(name: "Baz")]
        }
        else if page == 2 {
            items = [TestItem(name: "Baz"), TestItem(name: "Bing"), TestItem(name: "Boo")]
        }
    
        success(newItems: items)
    }
}

@objc
class TestItem: FeedItem, NSCoding {
    var name: String?
    
    init(name: String){
        super.init()
        self.name = name
    }
    
    @objc required init(coder aDecoder: NSCoder){
        name = aDecoder.decodeObjectForKey("name") as? String
    }
    
    @objc func encodeWithCoder(aCoder: NSCoder){
        aCoder.encodeObject(name, forKey: "name")
    }
    
    var sortableReference: SortableReference {
        return SortableReference(reference: self, hashValue: self.hashValue)
    }
}

class FeedKitTests: XCTestCase {
    
    let testItems : [FeedItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_001_addItemsToCache() {
        let cache = Cache(name: TestFeedKitType.TestFeedType.cacheName)
  
        let expectation = self.expectationWithDescription("Save cache expectation")
        
        cache.addItems(testItems, forPageNumber: 1)
        
        let delay = 1.0
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(5) { (error) -> Void in
            XCTAssert(cache.saved, "Is Cache saved")
        }
    }
    
    func test_005_fetchItemsFromCache() {
        
        //Test success is dependent on there already being items in the cache
        
        let cache = Cache(name: TestFeedKitType.TestFeedType.cacheName)
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
        
        let cache = Cache(name: TestFeedKitType.TestFeedType.cacheName)
        cache.loadCache { (success) -> () in
           print(success)
        }
        cache.synchronize()
        cache.clearCache()
        cache.synchronize()

        XCTAssert(cache.items.count == 0, "Cache is Empty")
    }
    

    
}
