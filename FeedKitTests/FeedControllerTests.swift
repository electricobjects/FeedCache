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
    
    func fetchItems(page: Int, itemsPerPage: Int, parameters: [String: AnyObject], success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
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
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? TestItem {
            return name == object.name
        }
        return false
    }
}



class FeedControllerTests: XCTestCase, FeedKitDelegate {
    
    let testItems : [FeedItem] = [TestItem(name: "test1"), TestItem(name: "test2"), TestItem(name: "test3")]
    var delegateResponseExpectation: XCTestExpectation?
    var feedController: FeedController?
    
    override func setUp() {
        super.setUp()
        feedController = FeedController(feedType: TestFeedKitType.TestFeedType, cachingOn: true, section: 0)
        feedController?.cache?.addItems(testItems)
    }
    
    override func tearDown() {
        feedController?.cache?.clearCache()
        feedController?.cache?.waitUntilSynchronized()
        super.tearDown()
    }

    
    func test_feedKitCacheLoad() {
        if let feedController = feedController {
            feedController.loadCacheSynchronously()
            XCTAssert(feedController.items.count > 0)
        }
        else {
            XCTAssert(false)
        }
    }


    
    //MARK: FeedKit Delegate methods
    
    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]){
        
    }
}
