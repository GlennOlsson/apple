//
//  LibraryBaseOperation.swift
//  iOS
//
//  Created by Chris Li on 3/22/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class LibraryBaseOperation: Operation {
    internal func updateZimFile(_ zimFile: ZimFile, meta: ZimFileMetaData) {
        zimFile.name = meta.name
        zimFile.title = meta.title
        zimFile.fileDescription = meta.fileDescription
        zimFile.languageCode = meta.languageCode
        zimFile.categoryRaw = meta.category
        
        zimFile.creator = meta.creator ?? ""
        zimFile.publisher = meta.publisher ?? ""
        zimFile.creationDate = meta.creationDate ?? Date()
        zimFile.downloadURL = meta.downloadURL?.absoluteString
        zimFile.faviconURL = meta.downloadURL?.absoluteString
        zimFile.size.value = meta.size?.int64Value
        zimFile.articleCount.value = meta.articleCount?.int64Value
        zimFile.mediaCount.value = meta.mediaCount?.int64Value
        
        zimFile.hasDetails = meta.hasDetails
        zimFile.hasIndex = meta.hasIndex
        zimFile.hasPictures = meta.hasPictures
        zimFile.hasVideos = meta.hasVideos
    }
}
