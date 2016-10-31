//
//  MockAPIService.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class MockAPIService {
    static let sharedService = MockAPIService()
    var mockFeed = [PeopleFeedItem]()
    var refreshItems = [PeopleFeedItem]()
    
    init(){
        _initializeMockFeed()
        startFeedUdpateSimulation()
    }
    
    fileprivate func _initializeMockFeed(){

        if let path = Bundle.main.path(forResource: "name_list", ofType: "txt")
        {
            let url = URL(fileURLWithPath: path)
            do {
                var feedItems = [PeopleFeedItem]()
                let fileContents = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
                let list = fileContents.components(separatedBy: "\n")
                var count = 1
                for name in list {
                    let item = PeopleFeedItem(name: name, id: count)
                    feedItems.append(item)
                    count += 1
                }
                feedItems = feedItems.reversed()
                
                let numRefreshItems = 100
                refreshItems = Array(feedItems[0...numRefreshItems-1])
                mockFeed = Array(feedItems[numRefreshItems...feedItems.count-1])
                
            } catch let error as NSError {
                assert(false, "There was a problem initializing the mock feed:\n\n \(error)")
            }
        }
    }
    
    func startFeedUdpateSimulation(){
        _delay(2, closure: { [weak self]()->() in self?._updateFeed() })
    }
    
    fileprivate func _updateFeed(){
        if refreshItems.count > 0 {
            let item = refreshItems.removeLast()
            mockFeed.insert(item, at: 0)
            _delay(4, closure: { self._updateFeed() })
        }
    }
    
    func fetchFeed(_ minId: Int?, maxId: Int?, count: Int, success:@escaping ([PeopleFeedItem])->()) {
        if let minId = minId {
            let maxId = maxId != nil ? maxId! : Int.max
            let filteredResults = mockFeed.filter({$0.id < maxId && $0.id > minId})
            let limit = min(filteredResults.count-1, count-1)
            var truncatedResults = [PeopleFeedItem]()
            if limit > 0 {
                truncatedResults = Array(filteredResults[0...limit])
            }
            let delayTime = Double(arc4random_uniform(100)) / 100.0
            _delay(delayTime, closure: { () -> () in
                success(truncatedResults)
            })
        }
    }
    
    
    fileprivate func _delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
}
