//
//  FeedKit.swift
//  FeedKit
//
//  Created by Rob Seward on 7/16/15.
//  Copyright (c) 2015 Rob Seward. All rights reserved.
//

import Foundation

protocol FeedKitDelegate {
    func fetchItemsComplete()
}

public class Controller {
    var items: [FeedItem]! = []
    var delegate: FeedKitDelegate?
    var feedType: FeedKitType!
    var caches: [String : Cache]?
    var cache: Cache? {
        return caches?[feedType.cacheName]
    }
    
    init(feedType: FeedKitType){ self.feedType = feedType }
    
    func loadCache(){
        if let cache = cache {
            items = cache.cachedItems
        }
    }
    
    private func _addItems(items: [FeedItem]){
        self.items = self.items + items
    }
    
    func fetchItems(pageNumber: Int, itemsPerPage: Int){
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

protocol FeedItem {
    var sortableReference: SortableReference { get }
}


protocol FeedKitType{
    var cacheName: String {get}
    
    func fetchItems(page: Int, itemsPerPage: Int, success:(newItems:[FeedItem])->(), failure:(error: NSError)->())
    
}

struct SortableReference: Hashable, Equatable {
    let reference: FeedItem
    init ( reference: FeedItem, hashValue: Int) {
        self.reference = reference
        self.hashValue = hashValue
    }
    
    var hashValue: Int
}
func ==(lhs: SortableReference, rhs: SortableReference)->Bool {
    return lhs.hashValue == rhs.hashValue
}


enum MyFeedTypes: FeedKitType {
    case Test
    
    var cacheName : String {
        switch self {
        case Test:
            return "test"
        }
    }
    
    func fetchItems(page: Int, itemsPerPage: Int, success:(newItems:[FeedItem])->(), failure:(error: NSError)->()){
        switch self {
        case Test:
            let items: [FeedItem] = [TestItem(name: "Foo"), TestItem(name: "Bar"), TestItem(name: "Baz")]
            success(newItems: items)
        }
    }
}

struct TestItem: FeedItem {
    var name: String?
    
    init(name: String){
        self.name = name
    }
    
    var sortableReference: SortableReference {
        return SortableReference(reference: self, hashValue: self.hashValue)
    }
    
    var hashValue : Int {
        if let name = name {
            return name.hashValue
        }
        else {
            return 0
        }
    }
}

public class Cache {
    
    public init() {}
    
    var cachedItems: [FeedItem] = []
    
    func addItems(items: [FeedItem]){
        cachedItems += items
    }
    
    func clearCache() {
        cachedItems.removeAll()
    }
}
