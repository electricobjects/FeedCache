# FeedKit
A Swift framework for consuming and displaying feeds in iOS

FeedKit is an alternative to using CoreData to manage paginated feed data. Architecturally, it replaces an NSFetchedResultsController, while caching data with NSCoding so the feed can load quickly from a cold start.

####Features####

FeedKit handles:

* Insertions
* Deletions
* Caching

![pull to refresh](https://github.com/electricobjects/FeedKit/raw/master/ReadMe_Images/pull_to_refresh.gif)

## First-page cache deletion ##

When you first load your table view or collection view, FeedKit loads the first page of your feed. If the first page has changed from the last time it was loaded, the cache is cleared and replaced with the new items. This handles deletions and keeps the data on your phone from getting stale.



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

Now create a `FeedKitController` in your UITableViewController or UICollectionViewController, specifying the type of FeedItem it will handle.

```swift
self.feedController = FeedController<PeopleFeedItem>(cachePreferences: MyCachePreferences.Photos, section: 0)
self.feedController.delegate = self
```

Implement the `FeedKitControllerDelegate` methods

```swift
func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]){
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths(itemsAdded, withRowAnimation: UITableViewRowAnimation.Automatic)
    tableView.deleteRowsAtIndexPaths(itemsDeleted, withRowAnimation: UITableViewRowAnimation.Automatic)
    tableView.endUpdates()
}
```
**CachePreferences**

Create your own cache preferences as an enum.

```swift
enum MyCachePreferences : CachePreferences{
    case Friends
    case Photos
    case PhotosNoCache

    var cacheOn: Bool {
        switch self {
        case .Friends:
            return true
        case Photos:
            return true
        default:
            return false
        }
    }

    var cacheName: String {
        switch self {
        case .Friends:
            return "friends"
        case .Photos:
            return "photos"
        default:
          return ""
        }
    }
}
```

##Installation##

TODO: Cocoapods/carthage stuff goes here

##Example App##

TODO: Link to release download here.
