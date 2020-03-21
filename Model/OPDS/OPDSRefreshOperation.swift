//
//  OPDSRefreshOperation.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import os
import RealmSwift
import SwiftyUserDefaults

class OPDSRefreshOperation: Operation {
    let progress = Progress(totalUnitCount: 10)
    private let updateExisting: Bool
    
    private(set) var hasUpdates = false
    private(set) var error: OPDSRefreshError?
    
    override init() {
        self.updateExisting = false
        super.init()
    }
    
    override func main() {
        do {
            os_log("OPDSRefreshOperation started.", log: Log.OPDS, type: .debug)
            
            // refresh the library
            let data = try fetchData()
            let parser = parseData(data: data)
            try processData(parser: parser)
            
            // apply language filter if library has never been refreshed
            if Defaults[.libraryLastRefreshTime] == nil, let code = Locale.current.languageCode {
                Defaults[.libraryFilterLanguageCodes] = [code]
            }

            // update last library refresh time
            Defaults[.libraryLastRefreshTime] = Date()
            
            os_log("OPDSRefreshOperation success, zim files count: %d",
                   log: Log.OPDS,
                   type: .default,
                   parser.zimFileIDs.count)
            
        } catch let error as OPDSRefreshError {
            self.error = error
        } catch {
            os_log("OPDSRefreshOperation unknown error: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        }
    }
    
    /// Retrieve the whole OPDS stream from library.kiwix.org
    /// - Throws: OPDSRefreshError, the error happened during OPDS stream retrieval
    /// - Returns: Data, a data object containing the OPDS stream
    private func fetchData() throws -> Data {
        var data: Data?
        var error: Swift.Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        let url = URL(string: "https://library.kiwix.org/catalog/root.xml")!
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        let dataTask = URLSession.shared.dataTask(with: request) {
            data = $0
            error = $2
            semaphore.signal()
        }
        progress.addChild(dataTask.progress, withPendingUnitCount: 8)
        
        dataTask.resume()
        semaphore.wait()
        
        if let data = data {
            os_log("Retrieve OPDS Stream, length: %llu", log: Log.OPDS, type: .info, data.count)
            return data
        } else {
            let description = error?.localizedDescription ??
                NSLocalizedString("Unable to fetch data", comment: "Library Refresh Error")
            os_log("Retrieve OPDS Stream, error: %s", log: Log.OPDS, type: .error, description)
            throw OPDSRefreshError.retrieve(localizedDescription: description)
        }
    }
    
    private func parseData(data: Data) -> OPDSStreamParser {
        let parser = OPDSStreamParser(data: data)
        parser.parse()
        return parser
    }
    
    /// Process the parsed OPDS stream
    /// - Throws: OPDSRefreshError, the error happened during OPDS stream processing
    private func processData(parser: OPDSStreamParser) throws {
        let zimFileIDs = Set(parser.zimFileIDs)
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            try database.write {
                // remove old zimFiles
                let predicate = NSPredicate(format: "NOT id IN %@ AND stateRaw == %@",
                                            zimFileIDs, ZimFile.State.cloud.rawValue)
                database.objects(ZimFile.self).filter(predicate).forEach({
                    database.delete($0)
                    self.hasUpdates = true
                })

                // upsert new and existing zimFiles
                for zimFileID in zimFileIDs {
                    guard let meta = parser.getZimFileMetaData(id: zimFileID) else { continue }
                    if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                        if updateExisting { update(zimFile: zimFile, meta: meta) }
                    } else {
                        let zimFile = ZimFile()
                        update(zimFile: zimFile, meta: meta)
                        zimFile.state = .cloud
                        database.add(zimFile)
                        self.hasUpdates = true
                    }
                }
            }
        } catch {
            throw OPDSRefreshError.process
        }
    }
    
    private func update(zimFile: ZimFile, meta: ZimFileMetaData) {
        zimFile.id = meta.identifier
        zimFile.title = meta.title
        zimFile.pid = meta.name
        zimFile.bookDescription = meta.fileDescription
        
//        zimFile.category = meta.category
        zimFile.languageCode = meta.languageCode
//        zimFile.creationDate =
        zimFile.creator = meta.creator
        zimFile.publisher = meta.publisher
        
        zimFile.remoteURL = meta.url
        // icon url
        
//        zimFile.fileSize = meta.size
//        zimFile.articleCount = meta.articleCount
//        zimFile.mediaCount = meta.mediaCount
        
    }
}


enum OPDSRefreshError: LocalizedError {
    case retrieve(localizedDescription: String)
    case parse
    case process
}
