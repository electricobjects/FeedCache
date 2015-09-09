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
    var isFirstPage: Bool { get }
    
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
    public var cache: Cache<T>?
    var redundantItemsAllowed : Bool = false //TODO implement this
    let section: Int!
    
    public init(cachePreferences: CachePreferences, section: Int){
        self.section = section
        self.cachePreferences = cachePreferences
        if self.cachePreferences.cacheOn {
            self.cache = Cache(name: cachePreferences.cacheName)
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
                    if request.isFirstPage {
                        strongSelf._processNewItemsForPageOne(items)
                    }
                    else {
                        strongSelf._addNewItems(items)
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
    
    private func _processNewItemsForPageOne(newItems: [T]){
        if newItems == items {
            return
        }
        let newSet = Set(newItems)
        let oldSet = Set(items)
        
        let insertSet = newSet.subtract(oldSet)
        let deleteSet = oldSet.subtract(newSet)
        
        let indexPathsForInsertion = _indexesForItems(insertSet, inArray: newItems)
        let indexPathsForDeletion = _indexesForItems(deleteSet, inArray: items)
        
        items = newItems
        
        cache?.clearCache()
        cache?.addItems(items)
        
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
}

public protocol FeedItem : Hashable, NSCoding {

}

public protocol FeedKitType{
    var cacheName: String {get}
    
    func fetchItems<T>(success success:(newItems:[T])->(), failure:(error: NSError)->())
}

