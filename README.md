# FeedKit
A Swift framework for consuming and displaying feeds in your iOS app

FeedKit is an alternative to using CoreData to manage feed data. Architecturally, it replaces an NSFetchedResultsController, while caching data with NSCoding so the feed can load quickly from a cold start.

## To Use

First, you must make whatever items you want to view conform to the FeedItem protocol, which just ensures it conforms to NSCoding and is Hashable:

```
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
}
```

In a UITableViewController or UICollectionViewController,
