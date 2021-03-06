//
//  AppDelegate.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryMonitorDelegate {
    var window: UIWindow?
    let fileMonitor = DirectoryMonitor(url: URL.documentDirectory)
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        if #available(iOS 13.0, *) {} else {
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = RootSplitViewController()
            window?.makeKeyAndVisible()
        }
        
        print("Document Directory URL: \(URL.documentDirectory)")
        
        DownloadManager.shared.restorePreviousState()
        application.setMinimumBackgroundFetchInterval(3600 * 24)
        
        fileMonitor.delegate = self
        fileMonitor.start()
        
        let operation = LibraryScanOperation(url: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(operation)
        
        application.shortcutItems = [
            UIApplicationShortcutItem(type: Shortcut.bookmark.rawValue, localizedTitle: NSLocalizedString("Bookmark", comment: "3D Touch Menu Title")),
            UIApplicationShortcutItem(type: Shortcut.search.rawValue, localizedTitle: NSLocalizedString("Search", comment: "3D Touch Menu Title"))
        ]
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        fileMonitor.stop()
    }
    
    // MARK: - URL Handling
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let rootViewController = window?.rootViewController as? RootSplitViewController else {return false}
        if url.isKiwixURL {
            rootViewController.openKiwixURL(url)
            return true
        } else if url.isFileURL {
            let canOpenInPlace = options[.openInPlace] as? Bool ?? false
            rootViewController.openFileURL(url, canOpenInPlace: canOpenInPlace)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Directory Monitoring
    
    func directoryContentDidChange(url: URL) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    // MARK: - Background
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        DownloadManager.shared.backgroundEventsCompleteProcessing = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let operation = LibraryRefreshOperation(updateExisting: false)
        operation.completionBlock = {
            if operation.error != nil {
                completionHandler(operation.hasUpdates ? .newData : .noData)
            } else {
                completionHandler(.failed)
            }
        }
        LibraryOperationQueue.shared.addOperation(operation)
    }
    
    // MARK: - Home Screen Quick Actions
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let rootViewController = window?.rootViewController as? RootSplitViewController,
            let shortcut = Shortcut(rawValue: shortcutItem.type) else { completionHandler(false); return }
        rootViewController.openShortcut(shortcut)
        completionHandler(true)
    }
}

// MARK: - Type Definition

enum Shortcut: String {
    case search, bookmark
}

extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
}
