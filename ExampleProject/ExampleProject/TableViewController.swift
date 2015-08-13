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

    var feedController: FeedKit.FeedController!
    let itemsPerPage = 25
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        feedController = FeedController(feedType: FeedTypes.PeopleFeed, cacheOn: true, section: 0)
        feedController.delegate = self
        feedController?.loadCacheSynchronously()
        feedController?.fetchItems(isFirstPage: true, minId: 0, itemsPerPage: itemsPerPage)
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
                    feedController?.fetchItems(isFirstPage: false, minId: 0, maxId: lastItem.id, itemsPerPage: itemsPerPage)
                }
                currentPage++
            }
        }

        
        
        return cell
    }

    func itemsUpdated(itemsAdded: [NSIndexPath], itemsDeleted: [NSIndexPath]){
        tableView.insertRowsAtIndexPaths(itemsAdded, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.deleteRowsAtIndexPaths(itemsDeleted, withRowAnimation: UITableViewRowAnimation.Automatic)
    }


}
