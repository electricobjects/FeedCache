//
//  FeedKit.swift
//  FeedKit
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import Foundation

public protocol FeedKitDelegate {
    func fetchItemsComplete()
}

public class FeedController {
    public var items: [FeedItem]! = []
    public var delegate: FeedKitDelegate?
    private(set) var  feedType: FeedKitType!
    var cacheData: Bool = true
    var caches: [String : Cache]?
    public var cache: Cache? {
        return caches?[feedType.cacheName]
    }
    
    public init(feedType: FeedKitType){ self.feedType = feedType }
    
    public func loadCache(){
        if let cache = cache {
            items = cache.cachedItems
        }
    }
    
    private func _addItems(items: [FeedItem]){
        self.items = self.items + items
    }
    
    public func fetchItems(pageNumber: Int, itemsPerPage: Int){
        feedType.fetchItems(pageNumber, itemsPerPage: itemsPerPage, success: {
            [weak self](newItems) -> () in
            self?._processNewItems(newItems, pageNumber: pageNumber)
            
            }) { (error) -> () in
        }
    }
    
    private func _processNewItems(newItems: [FeedItem], pageNumber: Int){
        let currentReferences = self.items.map({$0.sortableReference})
        let newReferences = newItems.map({$0.sortableReference})
        if pageNumber == 1{
            if currentReferences != newReferences {
                self.items = newItems
            }
            else{
                
            }
        }
    }
}

public protocol FeedItem {
     var sortableReference: SortableReference { get }
}

public protocol FeedKitType{
    var cacheName: String {get}
    
    func fetchItems(page: Int, itemsPerPage: Int, success:(newItems:[FeedItem])->(), failure:(error: NSError)->())
    
}

public struct SortableReference: Hashable, Equatable {
    let reference: FeedItem

    public init ( reference: FeedItem, hashValue: Int) {
        self.reference = reference
        self.hashValue = hashValue
    }
    
    public var hashValue: Int
}

public func ==(lhs: SortableReference, rhs: SortableReference)->Bool {
    return lhs.hashValue == rhs.hashValue
}


