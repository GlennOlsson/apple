//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

/**
 Library controller.
 
 The master controller lists zim files that are on device or being downloaded, along with all available zim files grouped by categories.
 The detail controller could be detail of a zim file or all zim files belong to one category.
 */
class LibraryController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        // set at least one view controller in viewControllers to supress a warning produced by split view controller
        viewControllers = [UIViewController()]
        
        preferredDisplayMode = .allVisible
        delegate = self
        
        let master = LibraryMasterController()
        let detail = UIViewController()
        detail.view.backgroundColor = .groupTableViewBackground
        viewControllers = [
            UINavigationController(rootViewController: master),
            UINavigationController(rootViewController: detail)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
