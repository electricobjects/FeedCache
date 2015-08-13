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
    private(set) public var items: [FeedItem]! = []
    public var delegate: FeedKitDelegate?
    private(set) var  feedType: FeedKitType!
    public var cache: Cache?
    var redundantItemsAllowed : Bool = false //TODO implement this
    let section: Int!
    
    var cacheOn: Bool {
        get {
            return cache == nil ? false : true
        }
        set (on) {
            cache = on ? Cache(name: feedType.cacheName) : nil
        }
    }

    
    
    public init(feedType: FeedKitType, cacheOn: Bool, section: Int){
        self.section = section
        self.feedType = feedType
        self.cacheOn = cacheOn
    }
    
    public func loadCacheSynchronously(){
        cache?.loadCache()
        cache?.waitUntilSynchronized()
        _processCacheLoad()
    }
    
    private func _addItems(items: [FeedItem]){
        self.items = self.items + items
    }
    
    public func fetchItems(
        isFirstPage isFirstPage: Bool,
        pageNumber: Int? = nil,
        itemsPerPage: Int? = nil,
        minId: Int? = nil,
        maxId: Int? = nil,
        maxTimeStamp: Int? = nil,
        minTimeStamp: Int? = nil)
    {
        feedType.fetchItems(
            isFirstPage,
            pageNumber: pageNumber,
            itemsPerPage: itemsPerPage,
            minId: minId,
            maxId: maxId,
            maxTimeStamp: maxTimeStamp,
            minTimeStamp: minTimeStamp,
            success: {
                [weak self](newItems) -> () in
                if let strongSelf = self {
                    if isFirstPage {
                        strongSelf._processNewItemsForPageOne(newItems)
                    }
                    else {
                        strongSelf._addNewItems(newItems)
                    }
                }
            },
            failure: {
                (error) -> () in
                
        })
//        feedType.fetchItems(pageNumber, itemsPerPage: itemsPerPage, parameters: parameters, success: {
//            [weak self](newItems) -> () in
//            if pageNumber == 1 {
//                self?._processNewItemsForPageOne(newItems)
//            }
//            else {
//                self?._addNewItems(newItems)
//            }
//            }) { (error) -> () in
//        }
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
        let itemsAdded = _indexesForItems(Set(newItems), inArray: items)
        delegate?.itemsUpdated(itemsAdded, itemsDeleted: [])
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
    
    func fetchItems(
        firstPage: Bool,
        pageNumber: Int?,
        itemsPerPage: Int?,
        minId: Int?,
        maxId: Int?,
        maxTimeStamp: Int?,
        minTimeStamp: Int?,
        success:(newItems:[FeedItem])->(),
        failure:(error: NSError)->()
    )
    
    
    
}

