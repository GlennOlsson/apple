//
//  ZimFile.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif
import RealmSwift

class ZimFile: Object {
    
    // MARK: -  non-optional properties
    
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var fileDescription: String = ""
    @objc dynamic var languageCode: String = ""
    @objc dynamic var categoryRaw: String = Category.other.rawValue
    
    // MARK: -  optional properties
    
    @objc dynamic var creator: String?
    @objc dynamic var publisher: String?
    @objc dynamic var creationDate: Date?
    @objc dynamic var downloadURL: String?
    @objc dynamic var faviconURL: String?
    @objc dynamic var faviconData: Data?
    let size = RealmOptional<Int64>()
    let articleCount = RealmOptional<Int64>()
    let mediaCount = RealmOptional<Int64>()
    
    // MARK: -  additional Properties
    
    @objc dynamic var hasDetails = false
    @objc dynamic var hasIndex = false
    @objc dynamic var hasPictures = false
    @objc dynamic var hasVideos = false
    @objc dynamic var includeInSearch = true
    
    @objc dynamic var openInPlaceURLBookmark: Data?
    @objc dynamic var stateRaw = State.cloud.rawValue
    @objc dynamic var downloadTotalBytesWritten: Int64 = 0
    @objc dynamic var downloadResumeData: Data?
    @objc dynamic var downloadErrorDescription: String?
  
//    old definition
//    @objc dynamic var id = ""
//    @objc dynamic var pid: String? -> name: String
//
//    @objc dynamic var title = ""
//    @objc dynamic var bookDescription = "" -> fileDescription
//    @objc dynamic var languageCode: String = ""
//    @objc dynamic var creationDate = Date()
//
//    @objc dynamic var creator = ""
//    @objc dynamic var publisher = ""
//
//    @objc dynamic var articleCount: Int64 = 0 -> RealmOptional<Int64>
//    @objc dynamic var mediaCount: Int64 = 0 -> RealmOptional<Int64>
//    @objc dynamic var fileSize: Int64 = 0 -> size
//
//    @objc dynamic var hasPicture = false -> hasPictures
//    @objc dynamic var hasEmbeddedIndex = false -> hasIndex
//    @objc dynamic var includeInSearch = true
//
//    @objc dynamic var icon = Data() -> faviconData
//
//    @objc dynamic var remoteURL: String? -> downloadURL
//    @objc dynamic var openInPlaceURLBookmark: Data?
//
//    @objc dynamic var stateRaw = State.cloud.rawValue
//    @objc dynamic var categoryRaw = Category.other.rawValue
//
//    @objc dynamic var downloadTotalBytesWritten: Int64 = 0
//    @objc dynamic var downloadResumeData: Data?
//    @objc dynamic var downloadErrorDescription: String?
    
    // MARK: -  read only properties
    
    var state: State {
        get { return State(rawValue:stateRaw) ?? .cloud }
        set { stateRaw = newValue.rawValue }
    }
    
    var category: Category {
        get { return Category(rawValue:stateRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var isInDocumentDirectory: Bool {
        get {
            if let fileName = ZimMultiReader.shared.getFileURL(zimFileID: self.id)?.lastPathComponent,
                let documentDirectoryURL = try? FileManager.default.url(
                    for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                let fileURL = documentDirectoryURL.appendingPathComponent(fileName)
                return FileManager.default.fileExists(atPath: fileURL.path)
            } else {
                return false
            }
        }
    }
    
    // MARK: - Overrides
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["name", "title", "languageCode", "categoryRaw", "creationDate", "includeInSearch", "stateRaw"]
    }
    
    // MARK: - Descriptions
    
    var creationDateDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        if let date = creationDate {
            return formatter.string(from: date)
        } else {
            return ""
        }
    }
    
    var fileSizeDescription: String {
        return ByteCountFormatter.string(fromByteCount: size.value ?? 0, countStyle: .file)
    }
    
    var articleCountDescription: String {
        let articleCount = self.articleCount.value ?? 0
        return NumberAbbrevationFormatter.string(from: Int(articleCount)) + (articleCount > 1 ? " articles" : " article")
    }
    
    // MARK: - Type Definition
    
    enum State: String {
        case cloud, local, retained, downloadQueued, downloadInProgress, downloadPaused, downloadError
    }
    
    enum Category: String, CustomStringConvertible {
        case wikibooks
        case wikinews
        case wikipedia
        case wikiquote
        case wikisource
        case wikiversity
        case wikivoyage
        case wiktionary
        
        case ted
        case vikidia
        case stackExchange = "stack_exchange"
        
        case other
        
        var description: String {
            switch self {
            case .wikibooks:
                return NSLocalizedString("Wikibooks", comment: "Zim File Category")
            case .wikinews:
                return NSLocalizedString("Wikinews", comment: "Zim File Category")
            case .wikipedia:
                return NSLocalizedString("Wikipedia", comment: "Zim File Category")
            case .wikiquote:
                return NSLocalizedString("Wikiquote", comment: "Zim File Category")
            case .wikisource:
                return NSLocalizedString("Wikisource", comment: "Zim File Category")
            case .wikiversity:
                return NSLocalizedString("Wikiversity", comment: "Zim File Category")
            case .wikivoyage:
                return NSLocalizedString("Wikivoyage", comment: "Zim File Category")
            case .wiktionary:
                return NSLocalizedString("Wiktionary", comment: "Zim File Category")
            case .ted:
                return NSLocalizedString("TED", comment: "Zim File Category")
            case .vikidia:
                return NSLocalizedString("Vikidia", comment: "Zim File Category")
            case .stackExchange:
                return NSLocalizedString("StackExchange", comment: "Zim File Category")
            case .other:
                return NSLocalizedString("Other", comment: "Zim File Category")
            }
        }
        
        var icon: UIImage {
            switch self {
            case .wikibooks:
                return #imageLiteral(resourceName: "Wikibooks")
            case .wikinews:
                return #imageLiteral(resourceName: "Wikinews")
            case .wikipedia:
                return #imageLiteral(resourceName: "Wikipedia")
            case .wikiquote:
                return #imageLiteral(resourceName: "Wikiquote")
            case .wikisource:
                return #imageLiteral(resourceName: "Wikisource")
            case .wikiversity:
                return #imageLiteral(resourceName: "Wikiversity")
            case .wikivoyage:
                return #imageLiteral(resourceName: "Wikivoyage")
            case .wiktionary:
                return #imageLiteral(resourceName: "Wiktionary")
            case .ted:
                return #imageLiteral(resourceName: "TED")
            case .vikidia:
                return #imageLiteral(resourceName: "Vikidia")
            case .stackExchange:
                return #imageLiteral(resourceName: "StackExchange")
            case .other:
                return #imageLiteral(resourceName: "Book")
            }
        }
    }
    
    class NumberAbbrevationFormatter {
        static func string(from value: Int) -> String {
            let sign = ((value < 0) ? "-" : "" )
            let abs = Swift.abs(value)
            guard abs >= 1000 else {return "\(sign)\(abs)"}
            let exp = Int(log10(Double(abs)) / log10(1000))
            let units = ["K","M","G","T","P","E"]
            let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
            return "\(sign)\(rounded)\(units[exp-1])"
        }
    }
}