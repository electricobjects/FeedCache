//
//  FeedController.swift
//  FeedController
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import UIKit


public protocol FeedFetchRequest {
    associatedtype H: FeedItem

    /// If set to true, cache data will be cleared when new data is loaded. This is usually set to true on the first page of a feed.
    var clearStaleDataOnCompletion: Bool { get }

    /**
     Fetch items for the feed.

     This method is called by the FeedController. When overriding this function your should make your api calls inside this method.
     The success method will trigger the item processing and eventually the items added/deleted callback in FeedController delegate.
     Failure closure will trigger the `requestFailed` delegate method.

     - parameter success: <#success description#>
     - parameter failure: <#failure description#>
     */
    func fetchItems(success: @escaping (_ newItems: [H])->(), failure: (NSError)->())
}

/**
 *  Your item models should follow this protocol, impelmenting `Hashable` and `NSCoding`. The `FeedController`
 *  compares incoming items to the ones already present, integrating new ones while eliminating redundant ones. It must compare the
 *  items using the `hashValue` in order to determine what items are new and which ones are not.
 */
public protocol FeedItem: Hashable, NSCoding {

}

public protocol FeedControllerDelegate: class {
    /**
     The delegate method called when changes are made to the controller's items via a FeedFetchRequest

     - Parameter feedController:    The feed controller.
     - Parameter itemsCopy:         A copy of the feed controller's updated items array.
     - Parameter itemsAdded:        The index paths of items  that were added to the items array.
     - Parameter itemsDeleted:      The index paths of items that were deleted from the items array.
     */
    func feedController(_ feedController: FeedControllerGeneric, itemsCopy: [AnyObject], itemsAdded: [IndexPath], itemsDeleted: [IndexPath])

    /**
     The delegate method called if there is an error making a FeedFetchRequest

     - parameter feedController:    The feed controller.
     - parameter feedController:    The error that occured in the FeedFetchRequest.
     */
    func feedController(_ feedController: FeedControllerGeneric, requestFailed error: NSError)
}

/**
 *  `CachePreferences` tell the FeedController whether or not to cache the feed items, and if so, what the cache should be called.
 */
public protocol CachePreferences {
    /// The name of the cache. To be saved in Library/Caches/FeedCache
    var cacheName: String { get }
    /// Turn caching on or off
    var cacheOn: Bool { get }
}

/**
 Since Feed Controllers use generics to ensure type saftey, they inherit from this common class so we can compare different
 Feed Controllers with the '==' operator
 */
open class FeedControllerGeneric {

}

func == (lhs: FeedControllerGeneric, rhs: FeedControllerGeneric) -> Bool {
    return Unmanaged.passUnretained(lhs).toOpaque() == Unmanaged.passUnretained(rhs).toOpaque()
}

/// The FeedController keeps track of incoming feed items and caches them accordingly. It is designed to be controlled by a UITableViewController or
/// `UICollectionViewController`, and is modeled after the `NSFetchedResultsController`.
open class FeedController <T:FeedItem> : FeedControllerGeneric {

    ///The items in the feed.
    fileprivate(set) open var items: [T]! = []
    /// The FeedController delegate. Usually a `UITableViewController` or `UICollectionViewController`.
    open weak var delegate: FeedControllerDelegate?
    /// The `cachePreferences` tell the FeedController whether or not to cache the feed items, and if so, what the cache should be called.
    fileprivate(set) var cachePreferences: CachePreferences
    /// The cache object is responsible for saving and retrieving the feed items.
    open var cache: FeedCache<T>?

    ///The section in a UITableView or UICollectionView that the Feed Controller corresponds to.
    let section: Int!


    /**
     Initialize the Feed Controller

     - parameter cachePreferences: The cache preferences.
     - parameter section: The section of the tableview or collection view that the controller corresponds to.
     */
    public init(cachePreferences: CachePreferences, section: Int) {
        self.section = section
        self.cachePreferences = cachePreferences
        if self.cachePreferences.cacheOn {
            self.cache = FeedCache(name: cachePreferences.cacheName)
        }
    }

    /**
     Load the Feed Controller's cache and block until it finishes.
     */
    open func loadCacheSynchronously() {
        cache?.loadCache()
        cache?.waitUntilSynchronized()
        _processCacheLoad()
    }

    fileprivate func _addItems(_ items: [T]) {
        self.items = self.items + items
    }

    /// Fetch items with a FeedFetchRequest.
    open func fetchItems<G: FeedFetchRequest>(_ request: G) {
        request.fetchItems(success: { [weak self](newItems) -> () in
            if let strongSelf = self {
                fk_dispatch_on_queue(DispatchQueue.global(qos: DispatchQoS.QoSClass.default), block: { () -> Void in
                    if let items =  newItems as Any as? [T] {
                        strongSelf._processNewItems(items, clearCacheIfNewItemsAreDifferent: request.clearStaleDataOnCompletion)
                    }
                })
            }
        }) { [weak self](error) -> () in
            if let delegate = self?.delegate, let strongSelf = self {
                delegate.feedController(strongSelf, requestFailed: error)
            }
        }
    }

    /**
     Remove an item. This can be useful when rearranging items, e.g. if the user is manually arranging items in a tableview, we can use these to keep
     the FeedCache items in the correct position.

     - parameter index: the index of the item to be removed.
    */
    open func removeItemAtIndex(_ index: Int) {
        items.remove(at: index)
        if let cache = cache {
            cache.clearCache()
            cache.addItems(items)
        }
    }

    /**
     Insert an item. This can be useful when rearranging items, e.g. if the user is manually arranging items in a tableview, we can use these to keep
     the FeedCache items in the correct position.

     - parameter item: The item to be inserted.
     - parameter atIndex: The index at which to insert the item.
    */
    open func insertItem(_ item: T, atIndex index: Int) {
        items.insert(item, at: index)
        if let cache = cache {
            cache.clearCache()
            cache.addItems(items)
        }
    }

    fileprivate func _processCacheLoad() {
        if let cache = cache {
            items = _unique(cache.items)
        }
    }

    fileprivate func _processNewItems(_ newItems: [T], clearCacheIfNewItemsAreDifferent: Bool) {

        //prevent calls of this method on other threads from mutating items array while we are working with it.
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        let uniqueNewItems = _unique(newItems)

        if uniqueNewItems == items {
            fk_dispatch_on_queue(DispatchQueue.main) { () -> Void in
                self.delegate?.feedController(self, itemsCopy: self.items, itemsAdded: [], itemsDeleted: [])
            }
            return
        }
        let newSet = Set(uniqueNewItems)
        let oldSet = Set(items)

        let insertSet = newSet.subtracting(oldSet)

        var indexPathsForInsertion: [IndexPath] = []
        var indexPathsForDeletion: [IndexPath] = []

        if clearCacheIfNewItemsAreDifferent {
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: uniqueNewItems)
            let deleteSet = oldSet.subtracting(newSet)
            indexPathsForDeletion = _indexesForItems(deleteSet, inArray: items)
            items = uniqueNewItems

            cache?.clearCache()
            fk_dispatch_on_queue(DispatchQueue.main) { () -> Void in
                self.cache?.addItems(self.items)
            }
        } else {

            let itemsToAdd = _orderSetWithArray(insertSet, array: uniqueNewItems)
            _addItems(itemsToAdd)
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: items)
        }

        fk_dispatch_on_queue(DispatchQueue.main) { () -> Void in
            self.delegate?.feedController(self, itemsCopy: self.items, itemsAdded: indexPathsForInsertion, itemsDeleted: indexPathsForDeletion)
        }
    }

    fileprivate func _indexesForItems(_ itemsToFind: Set<T>, inArray array: [T]) -> [IndexPath] {
        var returnPaths: [IndexPath] = []

        for item in itemsToFind {
            if let index = array.index(of: item) {
                returnPaths.append(IndexPath(row: index, section: section))
            }
        }

        return returnPaths
    }

    fileprivate func _orderSetWithArray(_ set: Set<T>, array: [T]) -> [T] {
        let forDeletion = Set(array).subtracting(set)
        var returnArray = [T](array)
        for item in forDeletion {
            let removeIndex = returnArray.index(of: item)!
            returnArray.remove(at: removeIndex)
        }
        return returnArray
    }

    /**
     Remove duplicates

     - parameter source: The original sequence.
     - returns: A sequence of unique items.
    */
    fileprivate func _unique<S: Sequence, E: Hashable>(_ source: S) -> [E] where E == S.Iterator.Element {
        var seen = [E: Bool]()
        return source.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}
