//
//  FeedKit.swift
//  FeedKit
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import Foundation


public protocol FeedKitDelegate {
    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath])
}

public class FeedController {
    public var items: [FeedItem]! = []
    public var delegate: FeedKitDelegate?
    private(set) var  feedType: FeedKitType!
    var cachingOn: Bool = true
    public var cache: Cache?
    var redundantItemsAllowed : Bool = false //TODO implement this
    let section: Int!
    
    
    public init(feedType: FeedKitType, cachingOn: Bool, section: Int){
        self.section = section
        self.feedType = feedType
        self.cachingOn = cachingOn
        if cachingOn {
            cache = Cache(name: feedType.cacheName)
        }
    }
    
    public func loadCacheSynchronously(){
        cache?.loadCache()
        cache?.waitUntilSynchronized()
        _processCacheLoad()
    }
    
    private func _addItems(items: [FeedItem]){
        self.items = self.items + items
    }
    
    public func fetchItems(pageNumber: Int, itemsPerPage: Int, parameters: [String: AnyObject]?){
        feedType.fetchItems(pageNumber, itemsPerPage: itemsPerPage, parameters: parameters, success: {
            [weak self](newItems) -> () in
            if pageNumber == 1 {
                self?._processNewItemsForPageOne(newItems)
            }
            else {
                self?._addNewItems(newItems)
            }
            }) { (error) -> () in
        }
    }
    
    private func _processCacheLoad(){
        if let cache = cache {
            items = cache.items
        }
    }
    
    private func _processNewItemsForPageOne(newItems: [FeedItem]){
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
    
    private func _addNewItems(newItems: [FeedItem]) {
        items = items + newItems
        cache?.addItems(newItems)
    }
    
    private func _indexesForItems(itemsToFind: Set<FeedItem>, inArray array: [FeedItem]) -> [NSIndexPath]{
        var returnPaths: [NSIndexPath] = []
        
        for item in itemsToFind {
            if let index = array.indexOf(item){
                returnPaths.append(NSIndexPath(forRow: index, inSection: section))
            }
        }
        
        return returnPaths
    }
}

public class FeedItem: NSObject {
    
//    var sortableReference: SortableReference {
//        assert(false, "This must be overridden")
//    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        assert(false, "This must be overridden")
        return false
    }
    
    public override var hashValue : Int{
        assert(false, "This must be overridden")
        return 0
    }
}

public protocol FeedKitType{
    var cacheName: String {get}
    
    func fetchItems(pageNumber: Int, itemsPerPage: Int, parameters: [String : AnyObject]?, success:(newItems:[FeedItem])->(), failure:(error: NSError)->())
    
}

//public struct SortableReference: Hashable, Equatable {
//    let reference: FeedItem
//
//    public init ( reference: FeedItem, hashValue: Int) {
//        self.reference = reference
//        self.hashValue = hashValue
//    }
//    
//    public var hashValue: Int
//}
//
//public func ==(lhs: SortableReference, rhs: SortableReference)->Bool {
//    return lhs.hashValue == rhs.hashValue
//}


