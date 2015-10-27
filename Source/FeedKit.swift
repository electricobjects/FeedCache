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
    //typealias T
    func feedController(feedController: FeedControllerGeneric, itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath])
    func feedController(feedController: FeedControllerGeneric, requestFailed error: NSError)
}

public protocol CachePreferences {
    var cacheName: String { get }
    var cacheOn: Bool { get }
}

public class FeedControllerGeneric {
    
}

func == (lhs: FeedControllerGeneric, rhs: FeedControllerGeneric) -> Bool{
    return unsafeAddressOf(lhs) == unsafeAddressOf(rhs)
}

public class FeedController <T:FeedItem> : FeedControllerGeneric{
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
            if let delegate = self?.delegate, strongSelf = self {
                delegate.feedController(strongSelf, requestFailed: error)
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
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.feedController(self, itemsAdded: [], itemsDeleted: [])
            }
            return
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
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.cache?.addItems(self.items)
            }
        }
        else {
            
            let itemsToAdd = _orderSetWithArray(insertSet, array: newItems)
            _addItems(itemsToAdd)
            indexPathsForInsertion = _indexesForItems(insertSet, inArray: items)
            
            //TODO: Remove items with the same Identity as new ones
        }

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.feedController(self, itemsAdded: indexPathsForInsertion, itemsDeleted: indexPathsForDeletion)
        }
    }
    
    private func _addNewItems(newItems: [T]) {
        items = items + newItems
        cache?.addItems(newItems)
        let itemsAdded = _indexesForItems(Set(newItems), inArray: items)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.feedController(self, itemsAdded: itemsAdded, itemsDeleted: [])
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
}



