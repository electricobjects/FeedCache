//: Playground - noun: a place where people can play

import UIKit
import FeedKit

var str = "Hello, playground"


enum MyFeedTypes: FeedKitType {
    case Test
    
    var cacheName : String {
        switch self {
        case Test:
            return "test"
        }
    }
    
    func fetchItems(page: Int, itemsPerPage: Int, success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
        switch self {
        case Test:
            let items: [FeedItem] = [TestItem(name: "Foo"), TestItem(name: "Bar"), TestItem(name: "Baz")]
            success(newItems: items)
        }
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

let testCache = Cache(name: "Foo")
let items = [TestItem(name: "Uno"), TestItem(name: "Dos"), TestItem(name: "Foo")]
testCache.addItems(items, forPageNumber: 1)
let caches = ["test" : testCache]

var fk = FeedKit.FeedController(feedType: MyFeedTypes.Test as FeedKitType)
//fk.caches = caches
fk.loadCache()

//fk.fetchItems(1, itemsPerPage: 10)
//fk.items
