//
//  TableViewHeader.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 28.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

protocol TableViewHeaderDelegate {
    func headerDidSelect(sender: UITableViewHeaderFooterView)
}


class TableViewHeader: UITableViewHeaderFooterView {
    
    // MARK: - Public Properties
    // -------------------------
    
    var delegate: TableViewHeaderDelegate?
    
    
    
    // MARK: - UITableViewHeaderFooterView
    // -----------------------------------
    
    override init(reuseIdentifier: String?)
    {
        super.init(reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    
    // MARK: - Private Methods
    // -----------------------
    
    private func commonInit()
    {
        //BKLog("Header init with \(self.reuseIdentifier ?? "n/a")", prefix: "0")
        self.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                         action: #selector(headerDidSelect(recognizer:))) )
    }
    
    @objc private func headerDidSelect(recognizer: UITapGestureRecognizer)
    {
        //BKLog("tag: \(self.tag)", prefix: "!")
        delegate?.headerDidSelect(sender: self)
    }
    

}
