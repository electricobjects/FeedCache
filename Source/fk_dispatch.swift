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

func fk_dispatch_after(_ time: TimeInterval, block: @escaping ()->() ) {
    fk_dispatch_after_on_queue(time, queue: DispatchQueue.main, block: block)
}

func fk_dispatch_after_on_queue(_ time: TimeInterval, queue: DispatchQueue, block: @escaping ()->()) {
    if FeedCachePerformWorkSynchronously {
        block()
    } else {
        let delay = DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        queue.asyncAfter(deadline: delay, execute: block)
    }
}

func fk_dispatch_async(_ block: @escaping ()->() ) {
    fk_dispatch_on_queue(DispatchQueue.global(qos: DispatchQoS.QoSClass.default), block: block)
}

func fk_dispatch_main_queue(_ block: @escaping ()->()) {
    fk_dispatch_on_queue(DispatchQueue.main, block: block)
}

func fk_dispatch_on_queue( _ queue: DispatchQueue, block: @escaping ()->()) {
    if (FeedCachePerformWorkSynchronously) {
        if Thread.isMainThread {
            block()
        } else {
            queue.sync(execute: block)
        }
    } else {
        queue.async(execute: block)
    }
}
