//
//  PlacesSegmentedViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.01.18.
//  Copyright © 2018 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

class PlacesSegmentedViewController: KBSegmentedViewController, ModelControllerDependent {
    
    // MARK: - Public Preperties
    // -------------------------
    
    var modelController: ModelController!
    

    override func viewDidLoad()
    {
        if let page1 = firstViewController as? ModelControllerDependent {
            page1.modelController = modelController
        }
        
        if let page2 = secondViewController as? ModelControllerDependent {
            page2.modelController = modelController
        }
        
        super.viewDidLoad()
        
    }
    

}
