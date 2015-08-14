//
//  TableViewController.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import UIKit
import FeedKit

class TableViewController: UITableViewController, FeedKitDelegate {

    //var refreshControl: UIRefreshControl!
    var feedController: FeedKit.FeedController!
    let itemsPerPage = 25
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MockAPIService.sharedService.startFeedUdpateSimulation()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        //self.tableView.addSubview(refreshControl)

        feedController = FeedController(cachePreferences: ExampleCachePreferences.CacheOn, section: 0)
        feedController.delegate = self
        feedController?.loadCacheSynchronously()
        let request = PeopleFeedRequest(isFirstPage: true, count: itemsPerPage, minId: 0)
        feedController?.fetchItems(request)
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedController.items.count
    }

  
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        if let item = feedController.items[indexPath.row] as? PeopleFeedItem{
            cell.textLabel?.text = item.name
            
            if indexPath.row == itemsPerPage * currentPage - 1 {
                if let lastItem = feedController.items.last as? PeopleFeedItem{
                    let request = PeopleFeedRequest(isFirstPage: false, count: itemsPerPage, minId: 0, maxId: lastItem.id)
                    feedController?.fetchItems(request)
                }
                currentPage++
            }
        }
        return cell
    }
    
    func refresh(sender: AnyObject){
        currentPage = 1
        let request = PeopleFeedRequest(isFirstPage: true, count: itemsPerPage, minId: 0)
        feedController?.fetchItems(request)
    }

    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]){
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths(itemsAdded, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.deleteRowsAtIndexPaths(itemsDeleted, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
        if let refreshing = refreshControl?.refreshing where refreshing{
            refreshControl?.endRefreshing()
        }
    }


}
