//
//  FeedItem.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import UIKit
import FeedKit

class PeopleFeedItem : FeedKit.FeedItem {
    var name: String!
    var id: Int!
    
    init(name: String, id: Int){
        self.name = name
        self.id = id
    }
}