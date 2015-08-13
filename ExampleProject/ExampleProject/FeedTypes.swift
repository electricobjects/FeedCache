//
//  FeedTypes.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/13/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import Foundation
import FeedKit

enum FeedTypes: FeedKitType {
    case PeopleFeed
    
    var cacheName : String {
        return "people"
    }
    
    func fetchItems(firstPage: Bool, pageNumber: Int?, itemsPerPage: Int?, minId: Int?, maxId: Int?, maxTimeStamp: Int?, minTimeStamp: Int?, success: (newItems: [FeedItem]) -> (), failure: (error: NSError) -> ()) {
        
        assert(minId != nil && itemsPerPage != nil, "did not define necessary parameters")
        if let itemsPerPage = itemsPerPage {
            MockAPIService.sharedService.fetchFeed(minId, maxId: maxId, count: itemsPerPage) { (items) -> () in
                success(newItems: items)
            }
        }
    }
    

}
