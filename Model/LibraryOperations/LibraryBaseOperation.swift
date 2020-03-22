//
//  LibraryBaseOperation.swift
//  iOS
//
//  Created by Chris Li on 3/22/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class LibraryBaseOperation: Operation {
    internal func updateZimFile(_ zimFile: ZimFile, meta: ZimFileMetaData) {
        zimFile.pid = meta.name
        zimFile.title = meta.title
        zimFile.bookDescription = meta.fileDescription
        zimFile.languageCode = meta.languageCode
        zimFile.categoryRaw = meta.category
        
        zimFile.creator = meta.creator ?? ""
        zimFile.publisher = meta.publisher ?? ""
        zimFile.creationDate = meta.creationDate ?? Date()
        zimFile.remoteURL = meta.downloadURL?.absoluteString
        zimFile.fileSize = meta.size?.int64Value ?? 0
        zimFile.articleCount = meta.articleCount?.int64Value ?? 0
        zimFile.mediaCount = meta.mediaCount?.int64Value ?? 0
        
        zimFile.hasPicture = meta.hasPictures
        
    }
}
