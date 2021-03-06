//
//  ViewController.swift
//  TableViewLiaison
//
//  Created by [01;31m[Kacct[m[K<blob>=dylanshine on 01/31/2019.
//  Copyright (c) 2019 [01;31m[Kacct[m[K<blob>=dylanshine. All rights reserved.
//

import UIKit
import TableViewLiaison

final class ViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    private let liaison = TableViewLiaison()
    private let refreshControl = UIRefreshControl()
    
    private var initialSections: [TableViewSection] {
        return Post.initialPosts()
            .map { PostTableViewSectionFactory.section(for: $0, tableView: tableView) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshSections), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        liaison.paginationDelegate = self
        liaison.liaise(tableView: tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        liaison.append(sections: initialSections, animated: false)
    }
    
    @objc private func refreshSections() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.liaison.clearSections(replacedBy: self.initialSections, animated: false)
            self.refreshControl.endRefreshing()
        }
    }
    
}

extension ViewController: TableViewLiaisonPaginationDelegate {
    
    func isPaginationEnabled() -> Bool {
        return liaison.sections.count < 8
    }
    
    func paginationStarted(indexPath: IndexPath) {
        
        liaison.scroll(to: indexPath)
        
        let sections = Post.paginatedPosts()
            .map { PostTableViewSectionFactory.section(for: $0, tableView: tableView) }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.liaison.append(sections: sections, animated: false)
        }
    }
    
    func paginationEnded(indexPath: IndexPath) {
        
    }

}

