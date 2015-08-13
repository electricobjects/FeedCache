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
    case PeopleFeedType
    
    var cacheName : String {
        return "people"
    }
    
    func fetchItems(firstPage: Bool, pageNumber: Int?, itemsPerPage: Int?, minId: Int?, maxId: Int?, maxTimeStamp: Int?, minTimeStamp: Int?, success: (newItems: [FeedItem]) -> (), failure: (error: NSError) -> ()) {
        
        assert(maxId != nil && minId != nil && itemsPerPage != nil, "did not define necessary parameters")
        if let maxId = maxId, minId = minId, itemsPerPage = itemsPerPage {
            MockAPIService.sharedService.fetchFeed(minId, maxID: maxId, count: itemsPerPage) {
                (people) -> () in
            }
        }
    }
    

}
