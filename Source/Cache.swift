//
//  Cache.swift
//  FeedKit
//
//  Created by Rob Seward on 7/17/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import Foundation

public class Cache {
    let name: String!
    let saveOperationQueue = NSOperationQueue()
    
    public init(name: String) {self.name = name}
    
    public var cachedItems: [FeedItem] = []
    
    public func addItems(items: [FeedItem], forPageNumber: Int){
        //cachedItems += items
        
    }
    
    public func removeAll() {
        cachedItems.removeAll()
    }
    
    func cacheData(pageNumber: Int, data : NSData){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            [weak self]() -> Void in
            
            if let
                strongSelf = self,
                folderName = strongSelf.name
            {
                let folderPath = strongSelf.folderPathFromFolderName(folderName, insideCacheFolder: true)
                do {
                    try strongSelf.createFolderIfNeeded(folderPath)
                }
                catch _ {
                    return
                }
                let filename = "\(pageNumber)"
                if let
                    filePath = folderPath.stringByAppendingPathComponent(filename).stringByAppendingPathExtension(".archived")
                {
                    data.writeToFile(filePath, atomically: true)
                }
            }
        })
    }
    
    func getCachedData(pageNumber: Int, completion: (NSData?)->()){
        let mainQueueCompletion : (NSData?) -> () = {
            (data) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            [weak self]() -> Void in

            if let
                folderName = self?.name,
                strongSelf = self
            {
                let folderPath = strongSelf.folderPathFromFolderName(folderName, insideCacheFolder: true)
                let filename = "\(pageNumber)"

                if let
                    filePath = folderPath.stringByAppendingPathComponent(filename).stringByAppendingPathExtension(".archived")
                {
                    let data = NSData(contentsOfFile: filePath)
                    mainQueueCompletion(data)
                }
                else {
                    mainQueueCompletion(nil)
                }
            }
            else {
                mainQueueCompletion(nil)
            }
        })
    }
    
    let apiCacheFolderName = "apiCache"
    
    func folderPathFromFolderName(folderName : String, insideCacheFolder: Bool) -> String{
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var documentsDirectory: AnyObject = paths[0]
        
        if insideCacheFolder {
            documentsDirectory = documentsDirectory.stringByAppendingPathComponent(apiCacheFolderName)
        }
        let folderPath = documentsDirectory.stringByAppendingPathComponent(folderName)
        return folderPath
        
    }
    
    func createFolderIfNeeded(folderPath: String) throws {
        if (!NSFileManager.defaultManager().fileExistsAtPath(folderPath)) {
            try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: false, attributes: nil)
        }
    }

}