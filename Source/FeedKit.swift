//
//  FeedKit.swift
//  FeedKit
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import Foundation

public protocol FeedKitFetchRequest {
    typealias H: FeedItem
    var clearStaleDataOnCompletion: Bool { get }
    
    func fetchItems(success success: (newItems: [H])->(), failure:(NSError)->())
}

public protocol FeedItem : Hashable, NSCoding {
    
}

public protocol FeedKitControllerDelegate: class {
    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath])
    func fetchRequestFailed(error: NSError)
}

public protocol CachePreferences {
    var cacheName: String { get }
    var cacheOn: Bool { get }
}

public class FeedController <T:FeedItem>{
    private(set) public var items: [T]! = []
    public weak var delegate: FeedKitControllerDelegate?
    //private(set) var  feedType: FeedKitType!
    private(set) var cachePreferences: CachePreferences
    public var cache: FeedCache<T>?
    var redundantItemsAllowed : Bool = false //TODO implement this
    let section: Int!
    
    public init(cachePreferences: CachePreferences, section: Int){
        self.section = section
        self.cachePreferences = cachePreferences
        if self.cachePreferences.cacheOn {
            self.cache = FeedCache(name: cachePreferences.cacheName)
        }
    }
    
    public func loadCacheSynchronously(){
        cache?.loadCache()
        cache?.waitUntilSynchronized()
        _processCacheLoad()
    }
    
    private func _addItems(items: [T]){
        self.items = self.items + items
    }
    
    public func fetchItems<G:FeedKitFetchRequest>(request: G)
    {
        request.fetchItems(success: { [weak self](newItems) -> () in
            if let strongSelf = self {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    if let items =  newItems as Any as? [T]{
                        strongSelf._processNewItems(items, clearCacheIfNewItemsAreDifferent: request.clearStaleDataOnCompletion)
                    }
                })
            }
        }) { [weak self](error) -> () in
            if let delegate = self?.delegate {
                delegate.fetchRequestFailed(error)
            }
        }
    }
    
    private func _processCacheLoad(){
        if let cache = cache {
            items = cache.items
        }
    }
    
    private func _processNewItems(newItems: [T], clearCacheIfNewItemsAreDifferent: Bool) {
        if newItems == items {
            delegate?.itemsUpdated([], itemsDeleted: [])
            return
        }
        else if clearCacheIfNewItemsAreDifferent && items.count >= newItems.count {
            let oldSlice = items[0..<newItems.count]
            if newItems[0..<newItems.count] == oldSlice {
                delegate?.itemsUpdated([], itemsDeleted: [])
                return
            }
        }
        let newSet = Set(newItems)
        let oldSet = Set(items)
        
        let insertSet = newSet.subtract(oldSet)
        
        var indexPathsForInsertion: [NSIndexPath] = []
        var indexPathsForDeletion: [NSIndexPath] = []
        
        if clearCacheIfNewItemsAreDifferent {
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: newItems)
            let deleteSet = oldSet.subtract(newSet)
            indexPathsForDeletion = _indexesForItems(deleteSet, inArray: items)
            items = newItems

            cache?.clearCache()
            cache?.addItems(items)
        }
        else {
            
            let itemsToAdd = _orderSetWithArray(insertSet, array: newItems)
            _addItems(itemsToAdd)
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: items)
            
            //TODO: Remove items with the same Identity as new ones
        }

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            delegate?.itemsUpdated(indexPathsForInsertion, itemsDeleted: indexPathsForDeletion)
        }
    }
    
    private func _addNewItems(newItems: [T]) {
        items = items + newItems
        cache?.addItems(newItems)
        let itemsAdded = _indexesForItems(Set(newItems), inArray: items)
        delegate?.itemsUpdated(itemsAdded, itemsDeleted: [])
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
}



