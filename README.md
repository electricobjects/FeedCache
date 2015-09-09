# FeedKit
A Swift framework for consuming and displaying feeds in your iOS app

FeedKit is an alternative to using CoreData to manage feed data. Architecturally, it replaces an NSFetchedResultsController, while caching data with NSCoding so the feed can load quickly from a cold start.

####Featuress####

FeedKit handles:

* Insertions
* Deletions
* Caching

## To Use

**Define your model**

First, you must make whatever items you want to view conform to the FeedItem protocol, which ensures it conforms to NSCoding and is Hashable:

```swift
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

**Define your fetch request**

The FeedKitFetchRequest protocol requires you to implement the `fetchItems` method.

```swift
struct TestFeedKitRequest: FeedKitFetchRequest {
    var isFirstPage: Bool
    var pageNumber: Int
    var itemsPerPage: Int

    init(isFirstPage: Bool, pageNumber: Int, itemsPerPage: Int){
        self.isFirstPage = isFirstPage
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
```

**Create a FeedKitController**

Now create a `FeedKitController` in your UITableViewController or UICollectionViewController, specifying the type of feedItem it will handle.

```swift
self.feedController = FeedController<PeopleFeedItem>(cachePreferences: ExampleCachePreferences.CacheOn, section: 0)
```
