//
//  FeedTypes.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/13/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import Foundation
import FeedCache

struct PeopleFeedRequest: FeedFetchRequest {
    var clearStaleDataOnCompletion: Bool
    var maxId: Int?
    var minId: Int!
    var count: Int!
    
    init(clearStaleDataOnCompletion: Bool, count: Int, minId: Int, maxId: Int? = nil){
        self.clearStaleDataOnCompletion = clearStaleDataOnCompletion
        self.count = count
        self.minId = minId
        self.maxId = maxId
    }
    
    
    func fetchItems(success: @escaping (_ newItems: [PeopleFeedItem]) -> (), failure: (NSError) -> ()) {
        MockAPIService.sharedService.fetchFeed(minId, maxId: maxId, count: count) { (items) -> () in
            success(items)
        }
    }
}


enum ExampleCachePreferences : CachePreferences{
    case CacheOn
    case cacheOff
    
    var cacheOn: Bool {
        switch self {
        case .CacheOn :
            return true
        default:
            return false
        }
    }
    
    var cacheName: String {
        return "people"
    }
}
