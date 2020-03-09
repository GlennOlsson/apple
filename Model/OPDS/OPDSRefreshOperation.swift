//
//  OPDSRefreshOperation.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import os

class OPDSRefreshOperation: Operation {
    let progress = Progress(totalUnitCount: 10)
    private(set) var error: OPDSRefreshError?
    
    override func main() {
        do {
            let data = try fetchData()
            
            let parser = OPDSStreamParser(data: data)
            parser.parse()
            
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
        let url = URL(string: "http://library.kiwix.org/catalog/root.xml")!
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
}


enum OPDSRefreshError: LocalizedError {
    case retrieve(localizedDescription: String)
    case parse
}
