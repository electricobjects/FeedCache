//
//  MockClasses.swift
//  FeedKit
//
//  Created by Rob Seward on 7/21/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import UIKit
import FeedKit

enum TestFeedKitType: FeedKitType {
    case TestFeedType
    
    var cacheName : String {
        return "test"
    }
    
    func fetchItems(page: Int, itemsPerPage: Int, parameters: [String: AnyObject]?, success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
        MockService.fetchItems(page, itemsPerPage: itemsPerPage, parameters: parameters, success: success, failure: failure)
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
    
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? TestItem {
            return hashValue == object.hashValue
        }
        return false
    }
    
    override var hashValue : Int{
        var h: Int = 0
        if let name = name {
            h ^= name.hash
        }
        return h
    }
    
    override var description: String { return name! }
}

class MockService {
    static var mockResponseItems: [TestItem]?
    
    class func fetchItems(page: Int, itemsPerPage: Int, parameters: [String: AnyObject]?, success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
        success(newItems: MockService.mockResponseItems!)
    }
}

