//
//  FeedKit.swift
//  FeedKit
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import Foundation

public protocol FeedKitFetchRequest {
    associatedtype H: FeedItem
    var clearStaleDataOnCompletion: Bool { get }
    
    func fetchItems(success success: (newItems: [H])->(), failure:(NSError)->())
}

public protocol FeedItem : Hashable, NSCoding {
    
}

public protocol FeedKitControllerDelegate: class {
    /**
     The delegate method called when changes are made to the controller's items via a FeedKitFetchRequest
     
     - Parameter feedController:    The feed controller.
     - Parameter itemsCopy:         A copy of the feed controller's updated items array.
     - Parameter itemsAdded:        The index paths of items that were added to the items array.
     - Parameter itemsDeleted:      The index paths of items that were deleted from the items array.
     */
    func feedController(feedController: FeedControllerGeneric, itemsCopy: [AnyObject], itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath])
    
    /**
     The delegate method called if there is an error making a FeedKitFetchRequest
     
     - parameter feedController:    The feed controller.
     - parameter feedController:    The error that occured in the FeedKitFetchRequest.
     */
    func feedController(feedController: FeedControllerGeneric, requestFailed error: NSError)
}

public protocol CachePreferences {
    var cacheName: String { get }
    var cacheOn: Bool { get }
}

/**
 Since Feed Controllers use generics to ensure type saftey, they inherit from this common class so we can compare different
 Feed Controllers with the '==' operator
 */
public class FeedControllerGeneric {
    
}

func == (lhs: FeedControllerGeneric, rhs: FeedControllerGeneric) -> Bool{
    return unsafeAddressOf(lhs) == unsafeAddressOf(rhs)
}

public class FeedController <T:FeedItem> : FeedControllerGeneric{
    
    ///The items in the feed.
    private(set) public var items: [T]! = []
    public weak var delegate: FeedKitControllerDelegate?
    private(set) var cachePreferences: CachePreferences
    public var cache: FeedCache<T>?
    
    ///The section in a UITableView or UICollectionView that the Feed Controller corresponds to.
    let section: Int!

    
    /**
     Initialize the Feed Controller
     
     parameter cachePreferences: The cache preferences.
     parameter section: The section of the tableview or collection view that the controller corresponds to.
     */
    public init(cachePreferences: CachePreferences, section: Int){
        self.section = section
        self.cachePreferences = cachePreferences
        if self.cachePreferences.cacheOn {
            self.cache = FeedCache(name: cachePreferences.cacheName)
        }
    }
    
    /**
     Load the Feed Controller's cache and block until it finishes.
     */
    public func loadCacheSynchronously(){
        cache?.loadCache()
        cache?.waitUntilSynchronized()
        _processCacheLoad()
    }
    
    private func _addItems(items: [T]){
        self.items = self.items + items
    }
    
    /// Fetch items with a FeedKitFetchRequest
    public func fetchItems<G:FeedKitFetchRequest>(request: G)
    {
        request.fetchItems(success: { [weak self](newItems) -> () in
            if let strongSelf = self {
                fk_dispatch_on_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block: { () -> Void in
                    if let items =  newItems as Any as? [T]{
                        strongSelf._processNewItems(items, clearCacheIfNewItemsAreDifferent: request.clearStaleDataOnCompletion)
                    }
                })
            }
        }) { [weak self](error) -> () in
            if let delegate = self?.delegate, strongSelf = self {
                delegate.feedController(strongSelf, requestFailed: error)
            }
        }
    }
    
    /**
     Remove an item. This can be useful when rearranging items, e.g. if the user is manually arranging items in a tableview, we can use these to keep
     the FeedKit items in the correct position.
     
     - parameter index: the index of the item to be removed.
    */
    public func removeItemAtIndex(index: Int) {
        items.removeAtIndex(index)
        if let cache = cache {
            cache.clearCache()
            cache.addItems(items)
        }
    }
    
    /**
     Insert an item. This can be useful when rearranging items, e.g. if the user is manually arranging items in a tableview, we can use these to keep
     the FeedKit items in the correct position.
     
     - parameter item: The item to be inserted.
     - parameter atIndex: The index at which to insert the item.
    */
    public func insertItem(item: T, atIndex index : Int) {
        items.insert(item, atIndex: index)
        if let cache = cache {
            cache.clearCache()
            cache.addItems(items)
        }
    }
    
    private func _processCacheLoad(){
        if let cache = cache {
            items = _unique(cache.items)
        }
    }
    
    private func _processNewItems(newItems: [T], clearCacheIfNewItemsAreDifferent: Bool) {
        
        //prevent calls of this method on other threads from mutating items array while we are working with it.
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        let uniqueNewItems = _unique(newItems)
        
        if uniqueNewItems == items {
            fk_dispatch_on_queue(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.feedController(self, itemsCopy: self.items, itemsAdded: [], itemsDeleted: [])
            }
            return
        }
        let newSet = Set(uniqueNewItems)
        let oldSet = Set(items)
        
        let insertSet = newSet.subtract(oldSet)
        
        var indexPathsForInsertion: [NSIndexPath] = []
        var indexPathsForDeletion: [NSIndexPath] = []
        
        if clearCacheIfNewItemsAreDifferent {
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: uniqueNewItems)
            let deleteSet = oldSet.subtract(newSet)
            indexPathsForDeletion = _indexesForItems(deleteSet, inArray: items)
            items = uniqueNewItems

            cache?.clearCache()
            fk_dispatch_on_queue(dispatch_get_main_queue()) { () -> Void in
                self.cache?.addItems(self.items)
            }
        }
        else {
            
            let itemsToAdd = _orderSetWithArray(insertSet, array: uniqueNewItems)
            _addItems(itemsToAdd)
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: items)
        }

        fk_dispatch_on_queue(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.feedController(self, itemsCopy: self.items, itemsAdded: indexPathsForInsertion, itemsDeleted: indexPathsForDeletion)
        }
    }
    
    private func _indexesForItems(itemsToFind: Set<T>, inArray array: [T]) -> [NSIndexPath]{
        var returnPaths: [NSIndexPath] = []
        
        for item in itemsToFind {
            if let index = array.indexOf(item){
                returnPaths.append(NSIndexPath(forRow: index, inSection: section))
            }
        }
        
        return returnPaths
    }
    
    private func _orderSetWithArray(set : Set<T>, array: [T]) -> [T] {
        let forDeletion = Set(array).subtract(set)
        var returnArray = [T](array)
        for item in forDeletion {
            let removeIndex = returnArray.indexOf(item)!
            returnArray.removeAtIndex(removeIndex)
        }
        return returnArray
    }
    
    /**
     Remove duplicates
     
     - parameter source: The original sequence.
     - returns: A sequence of unique items.
    */
    private func _unique<S: SequenceType, E: Hashable where E == S.Generator.Element>(source: S) -> [E] {
        var seen = [E: Bool]()
        return source.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}



