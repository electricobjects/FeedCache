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
    var feedController: FeedController?
    
    override func setUp() {
        super.setUp()
        feedController = FeedController(feedType: TestFeedKitType.TestFeedType, cachingOn: true, section: 0)
        feedController?.cache?.addItems(testItems)
        feedController?.cache?.waitUntilSynchronized()
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
