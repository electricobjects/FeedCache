//
//  MockClasses.swift
//  FeedKit
//
//  Created by Rob Seward on 7/21/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import UIKit
import FeedKit

struct TestFeedKitRequest: FeedKitFetchRequest {
    var clearStaleDataOnCompletion: Bool
    var pageNumber: Int
    var itemsPerPage: Int
        
    init(clearStaleDataOnCompletion: Bool, pageNumber: Int, itemsPerPage: Int){
        self.clearStaleDataOnCompletion = clearStaleDataOnCompletion
        self.pageNumber = pageNumber
        self.itemsPerPage = itemsPerPage
    }
    
    func fetchItems(success success: (newItems: [TestItem]) -> (), failure: (NSError) -> ()) {
        MockService.fetchItems(pageNumber, itemsPerPage: itemsPerPage, parameters: nil, success: { (newItems) -> () in
            success(newItems: newItems)
        }) { (error) -> () in

        }
    }
}

enum TestFeedKitCachePreferences : CachePreferences{
    case CacheOn
    case CacheOff
    
    var cacheOn: Bool {
        switch self {
        case .CacheOn :
            return true
        default:
            return false
        }
    }
    
    var cacheName: String {
        return "test"
    }
}

class TestItem: NSObject, FeedItem{
    var name: String? = nil
    
    init(name: String){
        self.name = name
    }
    
    @objc required  init(coder aDecoder: NSCoder){
        name = aDecoder.decodeObjectForKey("name") as? String
    }
    
    @objc  func encodeWithCoder(aCoder: NSCoder){
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
        if let name = name { h ^= name.hash }
        return h
    }
    
     override var description: String { return name! }
}

class MockService {
    static var mockResponseItems: [TestItem]?
    
    class func fetchItems(page: Int, itemsPerPage: Int, parameters: [String: AnyObject]?, success:(newItems:[TestItem])->(), failure:(error: NSError)->()){
        success(newItems: MockService.mockResponseItems!)
    }
}

