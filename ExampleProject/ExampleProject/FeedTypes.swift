//
//  FeedTypes.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/13/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import Foundation
import FeedKit

struct PeopleFeedRequest: FeedKitFetchRequest {
    var clearCacheOnCompletion: Bool
    var maxId: Int?
    var minId: Int!
    var count: Int!
    
    init(clearCacheOnCompletion: Bool, count: Int, minId: Int, maxId: Int? = nil){
        self.clearCacheOnCompletion = clearCacheOnCompletion
        self.count = count
        self.minId = minId
        self.maxId = maxId
    }
    
    
    func fetchItems(success success: (newItems: [PeopleFeedItem]) -> (), failure: (NSError) -> ()) {
        MockAPIService.sharedService.fetchFeed(minId, maxId: maxId, count: count) { (items) -> () in
            success(newItems: items)
        }
    }
}


enum ExampleCachePreferences : CachePreferences{
    case CacheOn
    case CacheOff
    
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