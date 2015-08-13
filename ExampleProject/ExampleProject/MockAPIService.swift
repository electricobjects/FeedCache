//
//  MockAPIService.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import Foundation

class MockAPIService {
    static let sharedService = MockAPIService()
    var mockFeed = [PeopleFeedItem]()
    var refreshItems = [PeopleFeedItem]()
    
    init(){
        _initializeMockFeed()
        startFeedUdpateSimulation()
    }
    
    private func _initializeMockFeed(){

        if let path = NSBundle.mainBundle().pathForResource("name_list", ofType: "txt")
        {
            let url = NSURL(fileURLWithPath: path)
            do {
                var feedItems = [PeopleFeedItem]()
                let fileContents = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding)
                let list = fileContents.componentsSeparatedByString("\n")
                var count = 1
                for name in list {
                    let item = PeopleFeedItem(name: name, id: count)
                    feedItems.append(item)
                    count++
                }
                feedItems = feedItems.reverse()
                
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
    
    private func _updateFeed(){
        if refreshItems.count > 0 {
            let item = refreshItems.removeLast()
            mockFeed.insert(item, atIndex: 0)
            _delay(4, closure: { self._updateFeed() })
        }
    }
    
    func fetchFeed(minId: Int?, maxId: Int?, count: Int, success:([PeopleFeedItem])->()) {
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
    
    
    private func _delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
}
