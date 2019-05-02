//
//  TabBarViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 25.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    var modelController: ModelController!
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if modelController.filter.currentCity == nil {
            performSegue(withIdentifier: IBConstants.Segues.selectCity, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.selectCity,
            let navigationVC = segue.destination as? UINavigationController,
            let destinationVC = navigationVC.topViewController as? LocationsTableViewController {
                        
                destinationVC.modelController = self.modelController
        }
        
    }
    

}
