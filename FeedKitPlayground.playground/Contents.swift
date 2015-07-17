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

class TestItem: FeedItem {
    var name: String?
    
    init(name: String){
        self.name = name
    }
    
    var sortableReference: SortableReference {
        return SortableReference(reference: self, hashValue: self.hashValue)
    }
    
    var hashValue : Int {
        if let name = name {
            return name.hashValue
        }
        else {
            return 0
        }
    }
}

let testCache = Cache()
testCache.addItems([TestItem(name: "Uno"), TestItem(name: "Dos"), TestItem(name: "Foo")])
let caches = ["test" : testCache]

var fk = FeedKit.FeedController(feedType: MyFeedTypes.Test as FeedKitType)
//fk.caches = caches
fk.loadCache()

//fk.fetchItems(1, itemsPerPage: 10)
//fk.items
