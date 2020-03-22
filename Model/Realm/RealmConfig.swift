//
//  RealmConfig.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

extension Realm {
    static func resetDatabase() {
        guard let url = Realm.defaultConfig.fileURL else {return}
        try? FileManager.default.removeItem(at: url)
    }
    
    static let defaultConfig: Realm.Configuration = {
        let library = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let applicationSupport = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let oldDatabaseURL = library.appendingPathComponent("realm")
        let newDatabaseURL = applicationSupport.appendingPathComponent("kiwix.realm")
        
        // move database to application support
        if FileManager.default.fileExists(atPath: oldDatabaseURL.path) {
            try? FileManager.default.moveItem(at: oldDatabaseURL, to: newDatabaseURL)
        }
        
        var config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 2) {
                    migration.enumerateObjects(ofType: ZimFile.className()) { oldObject, newObject in
                        newObject?["name"] = oldObject?["pid"] ?? ""
                        newObject?["fileDescription"] = oldObject?["bookDescription"] ?? ""
                        newObject?["hasPictures"] = oldObject?["hasPicture"] ?? false
                        newObject?["hasIndex"] = oldObject?["hasEmbeddedIndex"] ?? false
                        newObject?["faviconData"] = oldObject?["icon"]
                        if let categoryRaw = oldObject?["categoryRaw"] as? String {
                            if categoryRaw == "stackExchange" { newObject?["categoryRaw"] = "stack_exchange" }
                            if categoryRaw == "ted" { newObject?["categoryRaw"] = "other" }
                        }
                    }
                }
            }
        )
        config.fileURL = newDatabaseURL
        return config
    }()
}
