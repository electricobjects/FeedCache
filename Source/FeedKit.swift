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

public protocol FeedKitDelegate {
    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath])
}

public protocol CachePreferences {
    var cacheName: String { get }
    var cacheOn: Bool { get }
}

public class FeedController <T:FeedItem>{
    private(set) public var items: [T]! = []
    public var delegate: FeedKitDelegate?
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
                if let items =  newItems as Any as? [T]{
                    if request.clearStaleDataOnCompletion {
                        strongSelf._processNewItems(items, clearCacheIfNewItems: true)
                    }
                    else {
                        strongSelf._processNewItems(items, clearCacheIfNewItems: false)
                    }
                }
            }
        }) { (error) -> () in
                
        }
    }
    
    private func _processCacheLoad(){
        if let cache = cache {
            items = cache.items
        }
    }
    
    private func _processNewItems(newItems: [T], clearCacheIfNewItems: Bool) {
        if newItems == items {
            delegate?.itemsUpdated([], itemsDeleted: [])
            return
        }
        let newSet = Set(newItems)
        let oldSet = Set(items)
        
        let insertSet = newSet.subtract(oldSet)
        
        let indexPathsForInsertion = _indexesForItems(insertSet, inArray: newItems)
        
        var indexPathsForDeletion: [NSIndexPath] = []
        if clearCacheIfNewItems {
            let deleteSet = oldSet.subtract(newSet)
            indexPathsForDeletion = _indexesForItems(deleteSet, inArray: items)
            items = newItems
            cache?.clearCache()
            cache?.addItems(items)
        }
        else {
            let itemsToAdd = _orderSetWithArray(insertSet, array: newItems)
            _addItems(itemsToAdd)
            //TODO: Remove items with the same Identity as new ones
        }

        delegate?.itemsUpdated(indexPathsForInsertion, itemsDeleted: indexPathsForDeletion)
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

public protocol FeedItem : Hashable, NSCoding {

}

public protocol FeedKitType{
    var cacheName: String {get}
    
    func fetchItems<T>(success success:(newItems:[T])->(), failure:(error: NSError)->())
}

