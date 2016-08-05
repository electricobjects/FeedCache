//
//  fk_dispatch.swift
//  FeedCache
//
//  Created by Rob Seward on 7/8/16.
//  Copyright © 2016 Rob Seward. All rights reserved.
//

import Foundation

/// Setting this to true will make item processing and cache writing/reading occur synchronously on the main thread. This can be useful for testing.
public var FeedCachePerformWorkSynchronously = false

func fk_dispatch_after(time: NSTimeInterval, block: dispatch_block_t ) {
    fk_dispatch_after_on_queue(time, queue: dispatch_get_main_queue(), block: block)
}

func fk_dispatch_after_on_queue(time: NSTimeInterval, queue: dispatch_queue_t, block: dispatch_block_t) {
    if FeedCachePerformWorkSynchronously {
        block()
    } else {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
        dispatch_after(delay, queue, block)
    }
}

func fk_dispatch_async(block: dispatch_block_t ) {
    fk_dispatch_on_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block: block)
}

func fk_dispatch_main_queue(block: dispatch_block_t) {
    fk_dispatch_on_queue(dispatch_get_main_queue(), block: block)
}

func fk_dispatch_on_queue( queue: dispatch_queue_t, block: dispatch_block_t) {
    if (FeedCachePerformWorkSynchronously) {
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_sync(queue, block)
        }
    } else {
        dispatch_async(queue, block)
    }
}
