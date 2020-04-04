//
//  LibraryCategoryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class LibraryCategoryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    private let category: ZimFile.Category
    
    private var languageCodes = [String]()
    private var results = [String: Results<ZimFile>]()
    private var notificationTokens = [String: NotificationToken]()
    private var languageCodeObserver: DefaultsDisposable?
    
    // MARK: - Override
    
    init(category: ZimFile.Category) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
        title = category.description
        self.languageCodeObserver = Defaults.observe(
            key: .libraryFilterLanguageCodes, options: [.initial, .new]
        ) { [unowned self] update in
            guard let languageCodes = update.newValue else { return }
            self.configure(selectedLanguages: languageCodes)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tableView.separatorInset.left + 42, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNotificationTokens()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        notificationTokens.removeAll()
    }
    
    // MARK: - Configurations
    
    private func configure(selectedLanguages: [String]) {
        notificationTokens.removeAll()
        results.removeAll()
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            
            // select lanuages
            if selectedLanguages.count > 0 {
                languageCodes = selectedLanguages
            } else {
                let zimFiles = database.objects(ZimFile.self).filter("categoryRaw = %@", category.rawValue)
                languageCodes = zimFiles.distinct(by: ["languageCode"]).map({ $0.languageCode })
            }
            languageCodes.sort { (code0, code1) -> Bool in
                guard let name0 = Locale.current.localizedString(forLanguageCode: code0),
                    let name1 = Locale.current.localizedString(forLanguageCode: code1) else {return code0 < code1}
                return name0 < name1
            }
            
            // fetch results or show empty view
            if languageCodes.count > 0 {
                for languageCode in languageCodes {
                    let zimFiles = database.objects(ZimFile.self)
                        .filter("categoryRaw = %@ AND languageCode == %@", category.rawValue, languageCode)
                        .sorted(byKeyPath: "title")
                    results[languageCode] = zimFiles
                }
                configureNotificationTokens()
                
                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: #imageLiteral(resourceName: "Globe"), style: .plain, target: self, action: #selector(languageFilterBottonTapped(sender:)))
                tableView.backgroundView = nil
                tableView.separatorStyle = .singleLine
                showAdditionalLanguageAlertIfNeeded()
            } else {
                navigationItem.rightBarButtonItem = nil
                tableView.backgroundView = EmptyContentView(
                    image: #imageLiteral(resourceName: "shelf"),
                    title: "No Zim Files are Available",
                    subtitle: "Download the offline library catalog or add some zim files from your computer."
                )
                tableView.separatorStyle = .none
            }
            
            tableView.reloadData()
        } catch {}
    }
    
    private func configureNotificationTokens() {
        notificationTokens.removeAll()
        for (languageCode, result) in results {
            let notification = result.observe { [unowned self] changes in
                guard let sectionIndex = self.languageCodes.firstIndex(of: languageCode) else { return }
                switch changes {
                case .initial:
                    self.tableView.reloadSections([sectionIndex], with: .none)
                case .update(_, let deletions, let insertions, _):
                    self.tableView.performBatchUpdates({
                        let deletionIndexes = deletions.map({ IndexPath(row: $0, section: sectionIndex) })
                        let insertIndexes = insertions.map({ IndexPath(row: $0, section: sectionIndex) })
                        self.tableView.deleteRows(at: deletionIndexes, with: .fade)
                        self.tableView.insertRows(at: insertIndexes, with: .fade)
                    })
                default:
                    break
                }
            }
            notificationTokens[languageCode] = notification
        }
    }
    
    private func showAdditionalLanguageAlertIfNeeded() {
        guard !Defaults[.libraryHasShownLanguageFilterAlert] else { return }
        let title = NSLocalizedString("More Languages", comment: "Library: Additional Language Alert")
        let message = NSLocalizedString("Contents in other languages are also available. Visit language filter at the top of the screen to enable them.",
                                        comment: "Library: Additional Language Alert")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        Defaults[.libraryHasShownLanguageFilterAlert] = true
    }

    @objc func languageFilterBottonTapped(sender: UIBarButtonItem) {
        let navigation = UINavigationController(rootViewController: LibraryLanguageController())
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = sender
        present(navigation, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource & Delagates

    func numberOfSections(in tableView: UITableView) -> Int {
        return languageCodes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let result = results[languageCodes[section]] else { return 0 }
        return result.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }

    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        guard let result = results[languageCodes[indexPath.section]] else { return }
        let zimFile = result[indexPath.row]
        cell.titleLabel.text = zimFile.title
        cell.detailLabel.text = [
            zimFile.sizeDescription, zimFile.creationDateDescription, zimFile.articleCountDescription
        ].compactMap({ $0 }).joined(separator: ", ")
        cell.accessoryType = .disclosureIndicator
        cell.thumbImageView.contentMode = .scaleAspectFit
        
        let zimfileReference = ThreadSafeReference(to: zimFile)
        if let data = zimFile.faviconData, let image = UIImage(data: data) {
            cell.thumbImageView.image = image
        } else if let faviconURL = URL(string: zimFile.faviconURL ?? "") {
            cell.thumbImageView.image = #imageLiteral(resourceName: "GenericZimFile")
            let task = URLSession.shared.dataTask(with: faviconURL) { (data, _, _) in
                guard let data = data, let image = UIImage(data: data) else { return }
                do {
                    let database = try Realm(configuration: Realm.defaultConfig)
                    guard let zimFile = database.resolve(zimfileReference) else { return }
                    try database.write {
                        zimFile.faviconData = data
                    }
                } catch {}
                DispatchQueue.main.async {
                    guard let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
                    cell.thumbImageView.image = image
                }
            }
            task.resume()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Locale.current.localizedString(forLanguageCode: languageCodes[section])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let result = results[languageCodes[indexPath.section]] else { return }
        let zimFile = result[indexPath.row]
        let controller = LibraryZimFileDetailController(zimFile: zimFile)
        navigationController?.pushViewController(controller, animated: true)
    }
}
