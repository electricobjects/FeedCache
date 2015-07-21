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

