# FeedKit
A Swift framework for consuming and displaying feeds in your iOS app

FeedKit is an alternative to using CoreData to manage feed data. Architectually, it replaces an NSFetchedResultsController, while caching data with NSCoding so the feed can load quickly from a cold start.