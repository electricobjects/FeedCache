//
//  Cache.swift
//  FeedCache
//
//  Created by Rob Seward on 7/17/15.
//  Copyright © 2015 Rob Seward. All rights reserved.
//

import Foundation

struct FeedCacheFileNames {
    static let apiCacheFolderName = "FeedCache"
    static let genericArchiveName = "feed_cache.archive"
}

/**
 Delete all cached items in the FeedCache directory. It is recommended that you clear this each time the app is upgraded, which will prevent
 issues caused by trying to unarchive feed items with outdated schema.

 - throws: `ErrorType` from NSFileManager
 */
public func deleteAllFeedCaches() throws {
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    let libraryCachesDirectory: AnyObject = paths[0]
    let cacheDirectory = libraryCachesDirectory.stringByAppendingPathComponent(FeedCacheFileNames.apiCacheFolderName)
    try NSFileManager.defaultManager().removeItemAtPath(cacheDirectory)
}

/// FeedCache is responsible for saving and retreiving feed items from disk. It should be operated by the FeedController.
public class FeedCache<T:FeedItem> {

    /// The name of the cache, used to create the filename for the on-disk archive.
    let name: String!
    var diskOperationQueue = NSOperationQueue()
    /// Items that have been loaded from disk.
    public var items: [T] = []
    /// Saved is set to false when a save operation is in progress.
    public var saved = false

    /**
     Initialize a FeedCache

     - parameter name: The name of the cache written to `Library/Caches/FeedCache`.

     - returns: The FeedCache object
     */
    public init(name: String) {
        if FeedCachePerformWorkSynchronously {
            diskOperationQueue = NSOperationQueue.mainQueue()
        }
        diskOperationQueue.maxConcurrentOperationCount = 1
        self.name = name
    }

    /**
     Add items to the Cache. This is not performed asynchonously, so threading should be handled by the caller.

     - parameter items: FeedItems to add to the cache.
     */
    public func addItems(items: [T]) {
        self.saved = false
        self.items = self.items + items
        let data = NSKeyedArchiver.archivedDataWithRootObject(self.items)
        _saveData(data)
    }

    /**
     Load the cache asynchronously. Completion will fire on the main queue.

     - parameter completion: Success is true if the operation is a success.
     */
    public func loadCache(completion: ( (success: Bool)->() )? = nil) {

        // Once background queue is exited, synchronize will unblock
        // thus completion will fire **after** synchronize unblocks
        let mainQueueCompletion : (success: Bool) -> () = {
            (success: Bool) -> () in
            if NSThread.isMainThread() == false {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion?(success: success)
                })
            } else {
                completion?(success: success)
            }
        }

        _getCachedData (completion: {(data) -> () in
            if let data = data {
                let unarchivedItems = NSKeyedUnarchiver.unarchiveObjectWithData(data)
                if let unarchivedItems = unarchivedItems as? [T] {
                    self.items = unarchivedItems
                    mainQueueCompletion(success: true)
                    return
                }
            }
            mainQueueCompletion(success: false)
        })
    }

    /**
     Clear cache from disk synchronously.
     */
    public func clearCache() {
        self.saved = false
        self.items = []
        _deleteCache()
        self.saved = true
    }

    /**
     Cache operations are performed on an operation queue. Calling this method will block until the queue is empty.
     */
    public func waitUntilSynchronized() {
        if diskOperationQueue != NSOperationQueue.mainQueue() {
            diskOperationQueue.waitUntilAllOperationsAreFinished()
        }
    }

    private func _deleteCache() {
        let folderName = name
        let folderPath = _folderPathFromFolderName(folderName, insideCacheFolder: true)
        let filePath = (folderPath as NSString).stringByAppendingPathComponent(FeedCacheFileNames.genericArchiveName)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
        } catch let error as NSError {
            print(error)
        }
    }

    private func _saveData(data: NSData) {
        diskOperationQueue.addOperationWithBlock {
            [weak self]() -> Void in

            if let
                strongSelf = self,
                folderName = strongSelf.name
            {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)
                strongSelf._createFolderIfNeeded(folderPath)

                let filePath = (folderPath as NSString).stringByAppendingPathComponent(FeedCacheFileNames.genericArchiveName)

                data.writeToFile(filePath, atomically: true)
                if strongSelf.diskOperationQueue.operationCount == 1 {
                    strongSelf.saved = true
                }
            }
        }
    }

    private func _getCachedData(completion completion: (NSData?)->()) {
        diskOperationQueue.addOperationWithBlock {
            [weak self]() -> Void in

            if let
                folderName = self?.name,
                strongSelf = self {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)

                let filePath = (folderPath as NSString).stringByAppendingPathComponent(FeedCacheFileNames.genericArchiveName)
                let data = NSData(contentsOfFile: filePath)
                completion(data)
            } else {
                completion(nil)
            }
        }
    }


    private func _folderPathFromFolderName(folderName: String, insideCacheFolder: Bool) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var libraryCachesDirectory: AnyObject = paths[0]

        if insideCacheFolder {
            libraryCachesDirectory = libraryCachesDirectory.stringByAppendingPathComponent(FeedCacheFileNames.apiCacheFolderName)
        }

        let folderPath = libraryCachesDirectory.stringByAppendingPathComponent(folderName)
        return folderPath
    }

    private func _createFolderIfNeeded(folderPath: String) {
        if (!NSFileManager.defaultManager().fileExistsAtPath(folderPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error)
            }
        }
    }

}
