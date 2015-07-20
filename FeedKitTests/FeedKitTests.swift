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
        let items: [FeedItem] = [TestItem(name: "Foo"), TestItem(name: "Bar"), TestItem(name: "Baz")]
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
    
    /*var hashValue : Int {
        if let name = name {
            return name.hashValue
        }
        else {
            return 0
        }
    }*/
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
    
    func testAddItemsToCache() {
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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
