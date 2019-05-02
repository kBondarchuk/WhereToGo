//
//  BKSegmentedViewController.swift
//  SegmentControlTest
//
//  Created by Konstantin Bondarchuk on 20.01.18.
//  Copyright © 2018 Konstantin Bondarchuk. All rights reserved.
//

import UIKit


class KBSegmentedViewController: UIViewController {

    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    
    // MARK: - Public Properties
    // -------------------------
    
    @IBInspectable
    var viewControllersStoryboardNames: [String]?
    
    @IBInspectable var firstViewControllerStoryboardName: String? = "firstViewController"
    @IBInspectable var secondViewControllerStoryboardName: String? = "secondViewController"
    
    lazy var firstViewController: UIViewController? = {
        //let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let newViewController = self.storyboard?.instantiateViewController(withIdentifier: firstViewControllerStoryboardName ?? ""){
        
            addNewChildViewController(newViewController, segment: 0)
            
            return newViewController
        }
        
        return nil
    }()
    
    lazy var secondViewController: UIViewController? = {
        //let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let newViewController = self.storyboard?.instantiateViewController(withIdentifier: secondViewControllerStoryboardName ?? ""){
            
            addNewChildViewController(newViewController, segment: 1)
            
            return newViewController
        }
        
        return nil
    }()
    
    
    
    // MARK: - Private Properties
    // --------------------------
    
    private var hairLine: UIImageView?
    
    
    
    // MARK: - Actions
    // ---------------
    
    @IBAction func segmentDidChange(_ sender: UISegmentedControl)
    {
        BKLog("segmentDidChange: <\(sender.selectedSegmentIndex)>")
        
        updatePage()
    }

    
    
    // MARK: - Private Methods
    // -----------------------
    
    private func updatePage()
    {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            addChildViewOfController(firstViewController!)
            
            if secondViewController?.isViewLoaded == true {
                removeChildViewOfController(secondViewController!)
            }
            
        case 1:
            addChildViewOfController(secondViewController!)
            
            if firstViewController?.isViewLoaded == true {
                removeChildViewOfController(firstViewController!)
            }
            
        default:
            break
        }
        
    }
    
    private func addNewChildViewController(_ childController: UIViewController, segment: Int)
    {
        BKLog(childController.debugDescription)
        
        addChildViewController(childController)
        childController.didMove(toParentViewController: self)
        
        // Set segment title
        if let title = childController.title {
            segmentedControl.setTitle(title, forSegmentAt: segment)
        }
        
    }
    
    private func addChildViewOfController(_ childController: UIViewController)
    {
        self.view.insertSubview(childController.view, belowSubview: toolbar)
        
        childController.view.frame = self.view.bounds
        childController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func removeChildViewOfController(_ childController: UIViewController)
    {
        childController.view.removeFromSuperview()
    }
    
    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hairLine = findHairLine()
        
        //addChildViewOfController(firstViewController!)
//        print("Tile: ", secondViewController?.title ?? "-")
//        print("isViewLoaded: ", secondViewController?.isViewLoaded ?? "-")
//
//        addChildViewOfController(firstViewController!)
//        print("isViewLoaded: ", secondViewController?.isViewLoaded ?? "-")

        updatePage()
        
        
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        hairLine?.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        hairLine?.isHidden = false
    }


}



// MARK: -
extension KBSegmentedViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        //print("UIToolbarDelegate.position")
        return .top
    }
    
}



// MARK: -
extension KBSegmentedViewController {
    
    private func findHairLine() -> UIImageView?
    {
        
        for view in (navigationController?.navigationBar.subviews)! {
            
            for subView in view.subviews {
                
                if let imageView = subView as? UIImageView {
                   //print(imageView)
                    return imageView
                }
                
            }
            
            
        }
        
        return nil
    }
    
}
