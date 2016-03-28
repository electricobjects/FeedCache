# FeedKit
A Swift framework for consuming and displaying feeds in iOS

FeedKit is an alternative to using CoreData to manage paginated feed data. Architecturally, it replaces an NSFetchedResultsController, while caching data with NSCoding so the feed can load quickly from a cold start.

####Features####

FeedKit handles:

* Insertions
* Deletions (through first-page cache deletion)
* Caching

![pull to refresh](https://github.com/electricobjects/FeedKit/raw/master/ReadMe_Images/pull_to_refresh.gif)

## First-page cache deletion ##

When you first load your table view or collection view, FeedKit loads the first page of your feed. If the first page has changed from the last time it was loaded, the cache is cleared and replaced with the new items. This handles deletions and keeps the data on your phone from getting stale.



## To Use

**Define your model**

First, you must make whatever items you want to view conform to the FeedItem protocol, which ensures it conforms to NSCoding and is Hashable. It is important to override `isEqual()`, as this is what FeedKit uses to determine which items should be inserted or deleted. By default `isEqual()` returns the object's memory address, but we want it to return a value that is computed from its properties:

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

    // It's important to override isEqual so it compares properties
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? TestItem {
            return hashValue == object.hashValue
        }
        return false
    }

    // Override hashValue to compute a value from the object's properties
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
            failure(error)
        }
    }
}
```
**CachePreferences**

Create your own cache preferences as an enum.

```swift
enum MyCachePreferences : CachePreferences{
    case TestItems
    case Friends
    case Photos
    case PhotosNoCache

    var cacheOn: Bool {
        switch self {
        case .TestItems
            return true
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
        case .TestItem
            return "TestItems"
        case .Friends:
            return "Friends"
        case .Photos:
            return "Photos"
        default:
          return ""
        }
    }
}
```

**Create a FeedKitController**

Now create a `FeedKitController` in your UITableViewController or UICollectionViewController, specifying the type of FeedItem it will handle.

```swift

class MyTableViewController: UITableViewController, FeedKitControllerDelegate {

    var feedController: FeedController<PeopleFeedItem>!
    var items = [TestItem]()

    override func viewDidLoad() {
      feedController = FeedController<PeopleFeedItem>(cachePreferences: MyCachePreferences.TestItems, section: 0)
      feedController.delegate = self
      feedController.loadCacheSynchronously()
      //Defensively copy items to prevent race conditions
      items = feedController.items

      self.currentPage = 1
      let request = PeopleFeedRequest(currentPage, clearStaleDataOnCompletion: true, count: itemsPerPage)
      feedController?.fetchItems(request)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        let item = items[indexPath.row]
        cell.textLabel?.text = item.name

        if indexPath.row == (itemsPerPage * currentPage) - 1 {
            loadMoreItems()
        }
        return cell
    }

    func loadMoreItems() {
        currentPage++
        let request = PeopleFeedRequest(currentPage, clearStaleDataOnCompletion: false, count: itemsPerPage)
        feedController?.fetchItems(request)
    }

    //MARK: ***** FeedKitControllerDelegate Methods *****

    func feedController(feedController: FeedControllerGeneric, itemsCopy: [AnyObject], itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]) {
        //Defensively copy items to prevent race conditions
        items = itemsCopy  

        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths(itemsAdded, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.deleteRowsAtIndexPaths(itemsDeleted, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
    }
}
```


##Installation##

TODO: Cocoapods/carthage stuff goes here

##Example App##

TODO: Link to release download here.
