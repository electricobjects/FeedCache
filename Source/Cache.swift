//
//  Cache.swift
//  FeedKit
//
//  Created by Rob Seward on 7/17/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import Foundation

public class Cache<T:FeedItem>{
    
    let name: String!
    let saveOperationQueue = NSOperationQueue()
    let apiCacheFolderName = "FeedKitCache"
    let archiveName = "feed_kit_cache.archive"
    var semaphore: dispatch_semaphore_t?
    public var items : [T] = []
    public var saved = false
    
    public init(name: String) {
        saveOperationQueue.maxConcurrentOperationCount = 1
        self.name = name
    }
    
    //public var cachedItems: [FeedItems] = []
    
    public func addItems(items: [T]){
        self.saved = false
        self.items = self.items + items
        let data = NSKeyedArchiver.archivedDataWithRootObject(self.items)
        _saveData(data)
    }
    
    // Completion will fire on main queue
    public func loadCache(completion: ( (success: Bool)->() )? = nil){
        
        // Once background queue is exited, synchronize will unblock
        // thus completion will fire **after** synchronize unblocks
        let mainQueueCompletion : (success: Bool) -> () = {
            (success: Bool) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?(success: success)
            })
        }
        
        _getCachedData { (data) -> () in
            if let data = data {
                let unarchivedItems = NSKeyedUnarchiver.unarchiveObjectWithData(data)
                if let unarchivedItems = unarchivedItems as? [T] {
                    objc_sync_enter(self.items)
                    self.items = unarchivedItems
                    objc_sync_exit(self.items)
                    mainQueueCompletion(success: true)
                    return
                }
            }
            mainQueueCompletion(success: false)
        }
    }
    
    public func clearCache() {
        self.saved = false
        self.items = []
        _deleteCache()
        self.saved = true
    }
    
    // Wait until operation queue is empty
    public func waitUntilSynchronized(){
        print(saveOperationQueue.operationCount)
        saveOperationQueue.waitUntilAllOperationsAreFinished()
        print(saveOperationQueue.operationCount)
    }
    
    private func _deleteCache() {
        let folderName = name
        let folderPath = _folderPathFromFolderName(folderName, insideCacheFolder: true)
        let filePath = (folderPath as NSString).stringByAppendingPathComponent(archiveName)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
        }
        catch let error as NSError {
            print(error)
        }
    }
    
    private func _saveData(data : NSData){
        saveOperationQueue.addOperationWithBlock {
            [weak self]() -> Void in
            
            if let
                strongSelf = self,
                folderName = strongSelf.name
            {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)
                print(folderPath)
                strongSelf._createFolderIfNeeded(folderPath)
                
                let filePath = (folderPath as NSString).stringByAppendingPathComponent(strongSelf.archiveName)
                
                data.writeToFile(filePath, atomically: true)
                if strongSelf.saveOperationQueue.operationCount == 1 {
                    strongSelf.saved = true
                }
            }
        }
    }
    
    private func _getCachedData(completion: (NSData?)->()){
        saveOperationQueue.addOperationWithBlock {
            [weak self]() -> Void in

            if let
                folderName = self?.name,
                strongSelf = self
            {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)

                let filePath = (folderPath as NSString).stringByAppendingPathComponent(strongSelf.archiveName)
                let data = NSData(contentsOfFile: filePath)
                completion(data)
            }
            else {
                completion(nil)
            }
        }
        print(saveOperationQueue.operationCount)
    }
    
    
    private func _folderPathFromFolderName(folderName : String, insideCacheFolder: Bool) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var documentsDirectory: AnyObject = paths[0]
        
        if insideCacheFolder {
            documentsDirectory = documentsDirectory.stringByAppendingPathComponent(apiCacheFolderName)
        }
        
        let folderPath = documentsDirectory.stringByAppendingPathComponent(folderName)
        return folderPath
    }
    
    private func _createFolderIfNeeded(folderPath: String)  {
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