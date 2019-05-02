//
//  UIKit+.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 10.02.18.
//  Copyright © 2018 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

extension UIRefreshControl {
    
    func refresh()
    {
        if let scrollView = self.superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - self.frame.size.height), animated: true)
            self.beginRefreshing()
            self.sendActions(for: UIControlEvents.valueChanged)
        }
    }
    
}

func showAlert(with controller: UIViewController, title: String, message: String)
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .default)
    alert.addAction(cancelAction)
    controller.present(alert, animated: true)
}
