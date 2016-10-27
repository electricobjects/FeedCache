//
//  TableViewController.swift
//  ExampleProject
//
//  Created by Rob Seward on 8/12/15.
//  Copyright © 2015 Electric Objects. All rights reserved.
//

import UIKit
import FeedCache

class TableViewController: UITableViewController, FeedControllerDelegate {

    //var refreshControl: UIRefreshControl!
    var feedController: FeedController<PeopleFeedItem>!
    let itemsPerPage = 25
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MockAPIService.sharedService.startFeedUdpateSimulation()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(TableViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        //self.tableView.addSubview(refreshControl)

        feedController = FeedController<PeopleFeedItem>(cachePreferences: ExampleCachePreferences.CacheOn, section: 0)
        feedController.delegate = self
        feedController?.loadCacheSynchronously()
        let request = PeopleFeedRequest(clearStaleDataOnCompletion: true, count: itemsPerPage, minId: 0)
        feedController?.fetchItems(request)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedController.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let item = feedController.items[indexPath.row]
        cell.textLabel?.text = item.name
        
        if (indexPath as NSIndexPath).row == itemsPerPage * currentPage - 1 {
            if let lastItem = feedController.items.last{
                let request = PeopleFeedRequest(clearStaleDataOnCompletion: false, count: itemsPerPage, minId: 0, maxId: lastItem.id)
                feedController?.fetchItems(request)
                
                currentPage += 1
            }
        }
        
        return cell
    }
    
    func refresh(_ sender: AnyObject){
        currentPage = 1
        let request = PeopleFeedRequest(clearStaleDataOnCompletion: true, count: itemsPerPage, minId: 0)
        feedController?.fetchItems(request)
    }

    //MARK: ====  FeedKitController delegate methods  ====
    
    func feedController(feedController: FeedControllerGeneric, itemsCopy: [AnyObject], itemsAdded: [IndexPath], itemsDeleted: [IndexPath]) {
        tableView.beginUpdates()
        tableView.insertRows(at: itemsAdded, with: UITableViewRowAnimation.automatic)
        tableView.deleteRows(at: itemsDeleted, with: UITableViewRowAnimation.automatic)
        tableView.endUpdates()
        if let refreshing = refreshControl?.isRefreshing , refreshing{
            refreshControl?.endRefreshing()
        }
    }
    
    func feedController(feedController: FeedControllerGeneric, requestFailed error: NSError) {
        print(error)
    }
}
