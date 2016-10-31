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
    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    let libraryCachesDirectory: URL = URL(fileURLWithPath: paths[0])
    let cacheDirectory = libraryCachesDirectory.appendingPathComponent(FeedCacheFileNames.apiCacheFolderName)
    try FileManager.default.removeItem(atPath: cacheDirectory.relativePath)
}

/// FeedCache is responsible for saving and retreiving feed items from disk. It should be operated by the FeedController.
open class FeedCache<T:FeedItem> {

    /// The name of the cache, used to create the filename for the on-disk archive.
    let name: String!
    var diskOperationQueue = OperationQueue()
    /// Items that have been loaded from disk.
    open var items: [T] = []
    /// Saved is set to false when a save operation is in progress.
    open var saved = false

    /**
     Initialize a FeedCache

     - parameter name: The name of the cache written to `Library/Caches/FeedCache`.

     - returns: The FeedCache object
     */
    public init(name: String) {
        if FeedCachePerformWorkSynchronously {
            diskOperationQueue = OperationQueue.main
        }
        diskOperationQueue.maxConcurrentOperationCount = 1
        self.name = name
    }

    /**
     Add items to the Cache. This is not performed asynchonously, so threading should be handled by the caller.

     - parameter items: FeedItems to add to the cache.
     */
    open func addItems(_ items: [T]) {
        self.saved = false
        self.items = self.items + items
        let data = NSKeyedArchiver.archivedData(withRootObject: self.items)
        _saveData(data)
    }

    /**
     Load the cache asynchronously. Completion will fire on the main queue.

     - parameter completion: Success is true if the operation is a success.
     */
    open func loadCache(_ completion: ( (_ success: Bool)->() )? = nil) {

        // Once background queue is exited, synchronize will unblock
        // thus completion will fire **after** synchronize unblocks
        let mainQueueCompletion : (_ success: Bool) -> () = {
            (success: Bool) -> () in
            if Thread.isMainThread == false {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion?(success)
                })
            } else {
                completion?(success)
            }
        }

        _getCachedData (completion: {(data) -> () in
            if let data = data {
                let unarchivedItems = NSKeyedUnarchiver.unarchiveObject(with: data)
                if let unarchivedItems = unarchivedItems as? [T] {
                    self.items = unarchivedItems
                    mainQueueCompletion(true)
                    return
                }
            }
            mainQueueCompletion(false)
        })
    }

    /**
     Clear cache from disk synchronously.
     */
    open func clearCache() {
        self.saved = false
        self.items = []
        _deleteCache()
        self.saved = true
    }

    /**
     Cache operations are performed on an operation queue. Calling this method will block until the queue is empty.
     */
    open func waitUntilSynchronized() {
        if diskOperationQueue != OperationQueue.main {
            diskOperationQueue.waitUntilAllOperationsAreFinished()
        }
    }

    fileprivate func _deleteCache() {
        let folderName = name
        let folderPath = _folderPathFromFolderName(folderName!, insideCacheFolder: true)
        let filePath = (folderPath as NSString).appendingPathComponent(FeedCacheFileNames.genericArchiveName)
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch let error as NSError {
            print(error)
        }
    }

    fileprivate func _saveData(_ data: Data) {
        diskOperationQueue.addOperation {
            [weak self]() -> Void in

            if let
                strongSelf = self,
                let folderName = strongSelf.name
            {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)
                strongSelf._createFolderIfNeeded(folderPath)

                let filePath = (folderPath as NSString).appendingPathComponent(FeedCacheFileNames.genericArchiveName)

                try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                if strongSelf.diskOperationQueue.operationCount == 1 {
                    strongSelf.saved = true
                }
            }
        }
    }

    fileprivate func _getCachedData(completion: @escaping (Data?)->()) {
        diskOperationQueue.addOperation {
            [weak self]() -> Void in

            if let
                folderName = self?.name,
                let strongSelf = self {
                let folderPath = strongSelf._folderPathFromFolderName(folderName, insideCacheFolder: true)

                let filePath = (folderPath as NSString).appendingPathComponent(FeedCacheFileNames.genericArchiveName)
                let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                completion(data)
            } else {
                completion(nil)
            }
        }
    }


    fileprivate func _folderPathFromFolderName(_ folderName: String, insideCacheFolder: Bool) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        var libraryCachesDirectory: URL = URL(fileURLWithPath: paths[0])
        if insideCacheFolder {
            libraryCachesDirectory.appendPathComponent(FeedCacheFileNames.apiCacheFolderName)
        }

        let folderPath = libraryCachesDirectory.appendingPathComponent(folderName)
        return folderPath.relativePath
    }

    fileprivate func _createFolderIfNeeded(_ folderPath: String) {
        if (!FileManager.default.fileExists(atPath: folderPath)) {
            do {
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error)
            }
        }
    }

}
