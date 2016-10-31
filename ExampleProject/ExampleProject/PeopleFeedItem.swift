//
//  FeedItem.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import UIKit
import FeedCache

class PeopleFeedItem : NSObject, FeedItem,  NSCoding {
    var name: String!
    var id: Int!
    
    init(name: String, id: Int){
        self.name = name
        self.id = id
    }
    
    @objc required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: "name") as? String
        id = aDecoder.decodeObject(forKey: "id") as? Int
    }
    
    @objc func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(id, forKey: "id")
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? PeopleFeedItem {
            return object.name == self.name && object.id == self.id
        }
        return false
    }
    
    override var hashValue : Int{
        let h: Int = name.hash ^ id.hashValue
        return h
    }
    
    override var description : String {
        return "\(id), \(name)"
    }
}
