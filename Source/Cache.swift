//
//  Cache.swift
//  FeedKit
//
//  Created by Rob Seward on 7/17/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import Foundation

public class Cache{
    
    let name: String!
    let saveOperationQueue = NSOperationQueue()
    let apiCacheFolderName = "FeedKitCache"
    public var saved = false
    
    public init(name: String) {
        self.name = name
        
        
    }
    
    //public var cachedItems: [FeedItems] = []
    
    public func addItems(items: [FeedItem], forPageNumber pageNumber: Int){
        
        self.saved = false
        let data = NSKeyedArchiver.archivedDataWithRootObject(items)
        saveData(pageNumber, data: data)
    }
    
    public func removeAll() {
//        cachedItems.removeAll()
    }
    
    func saveData(pageNumber: Int, data : NSData){
        saveOperationQueue.addOperationWithBlock {
            [weak self]() -> Void in
            
            if let
                strongSelf = self,
                folderName = strongSelf.name
            {
                let folderPath = strongSelf.folderPathFromFolderName(folderName, insideCacheFolder: true)
                print(folderPath)
                strongSelf.createFolderIfNeeded(folderPath)
                
                let filename = "\(pageNumber)"
                if let
                    filePath = folderPath.stringByAppendingPathComponent(filename).stringByAppendingPathExtension(".archived")
                {
                    data.writeToFile(filePath, atomically: true)
                    if strongSelf.saveOperationQueue.operationCount == 1 {
                        strongSelf.saved = true
                    }
                }
            }
        }
    }
    
    func getCachedData(pageNumber: Int, completion: (NSData?)->()){
        let mainQueueCompletion : (NSData?) -> () = {
            (data) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data)
            })
        }
        
        saveOperationQueue.addOperationWithBlock {
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
        }
    }
    
    
    func folderPathFromFolderName(folderName : String, insideCacheFolder: Bool) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var documentsDirectory: AnyObject = paths[0]
        
        if insideCacheFolder {
            documentsDirectory = documentsDirectory.stringByAppendingPathComponent(apiCacheFolderName)
        }
        
        let folderPath = documentsDirectory.stringByAppendingPathComponent(folderName)
        return folderPath
    }
    
    func createFolderIfNeeded(folderPath: String)  {
        if (!NSFileManager.defaultManager().fileExistsAtPath(folderPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print(error)
            }
        }
    }

}