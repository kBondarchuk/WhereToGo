//
//  KBImageViewController.swift
//  KBObjects
//
//  Created by Костя on 07.05.17.
//  Copyright © 2017 hyphy. All rights reserved.
//

import UIKit
import AVKit

@IBDesignable
class KBImageViewController: UIViewController {

    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            //print("[\(self.typeName)] scrollView: didSet")
            scrollView.delegate = self
            scrollView.addSubview(imageView)
            scrollView.contentSize = imageView.frame.size
            scrollView.minimumZoomScale = minimumZoomScale
            scrollView.maximumZoomScale = maximumZoomScale
            scrollView.zoomScale = 1.0
            
            self.setNeedsStatusBarAppearanceUpdate()
            //print(self.prefersStatusBarHidden)
            
            // Double Tap -- Zoom to max
            imageView.isUserInteractionEnabled = true
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
            doubleTapGesture.numberOfTapsRequired = 2
            imageView.addGestureRecognizer(doubleTapGesture)
        }
    }
    
    
    
    // MARK: - Actions
    // ---------------
    
    @IBAction func dismissImageView(_ sender: Any)
    {
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc private func handleTap(sender: UITapGestureRecognizer)
    {
        if sender.state == .ended {
            
            var zoomToValue: CGFloat = 1.0
            
            BKLog("min: \(scrollView.minimumZoomScale) max: \(scrollView.maximumZoomScale) cur: \(scrollView.zoomScale)")
            
            let avarage = (scrollView.maximumZoomScale+scrollView.minimumZoomScale)/2
            
            if scrollView.zoomScale<avarage {
                zoomToValue = scrollView.maximumZoomScale
            }else if scrollView.zoomScale >= avarage {
                zoomToValue = scrollView.minimumZoomScale
            }
            
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [],
                           animations: { self.scrollView.zoomScale = zoomToValue })
            
        }
    }
    
    
    
    // MARK: - Public Properties
    // -------------------------
    
    @IBInspectable
    var statusBarHidden: Bool = false
    
    override var prefersStatusBarHidden: Bool { return statusBarHidden }
    
    @IBInspectable
    var minimumZoomScale: CGFloat = 0.03
    
    @IBInspectable
    var maximumZoomScale: CGFloat = 10.0
    
    var imageURL: URL? {
        didSet{
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    var image: UIImage?{
        get{
            return imageView.image
        }
        
        set{
            imageView.image = newValue
            imageView.contentMode = .center
            imageView.sizeToFit()

        
            scrollView?.contentSize = imageView.frame.size
            activityIndicator?.stopAnimating()
            
            if newValue == nil { return }
            print("Size of image: ", imageView.image?.size ?? "???", "Size of view : ", self.view.frame.size)
            

            // Zoom to Fit
            let aspectH = self.view.frame.size.height / imageView.image!.size.height
            let aspectW = self.view.frame.size.width / imageView.image!.size.width

            scrollView?.zoomScale = min(aspectH, aspectW)
            scrollView?.minimumZoomScale = min(aspectH, aspectW)
            scrollView?.maximumZoomScale = max(aspectH, aspectW)
            
        }
    }
    
    let transition = KBImageViewAnimatedTransitioning()
    
    
    
    // MARK: - Private Properties
    // --------------------------
    
    fileprivate var imageView = UIImageView()
    
    
    
    // MARK: - Private Functions
    // -------------------------
    
    private func fetchImage()
    {
        if let url = imageURL{
            
            activityIndicator.startAnimating()
            print("[>] Run thread...")
            
            DispatchQueue.global(qos: .userInitiated).async {[weak self] in
                
                let urlContents = try? Data(contentsOf: url)
                
                if let imageData = urlContents, url == self?.imageURL{
                    // UI
                    DispatchQueue.main.async {
                        print(urlContents?.debugDescription ?? "-no data-")
                        self?.image = UIImage(data: imageData)
                    }
                    
                }
            
            }
        }
        
    }

    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        BKLog()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        BKLog()
        
        if image == nil {
            fetchImage()
        }
        
        if scrollView == nil {
            print("[\(type(of:self))]: Warning! ScrollView has not been set!")
        }
        
    }
}



// MARK: - UIScrollViewDelegate
// ----------------------------

extension KBImageViewController : UIScrollViewDelegate
{
    
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return imageView
    }
    
   
}

extension KBImageViewController
{
    var typeName: String {
        get {
            return String(describing: type(of: self.self))
        }
    }
}


  
// MARK: - KBImageViewAnimatedTransitioning
// ----------------------------------------

class KBImageViewAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate
{
    // MARK: - Setup
    // ---------------
    
    var transitionDuration = 0.6
    var transitionSourceFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    let usingSpringWithDamping: CGFloat = 0.6
    let initialSpringVelocity: CGFloat = 0.5
    let targetAlpha: CGFloat = 0.9
    
    
    // MARK: - UIViewControllerTransitioningDelegate
    // ---------------------------------------------
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return nil
    }
    
    
    
    // MARK: - UIViewControllerAnimatedTransitioning
    // ---------------------------------------------
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        //let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        
        //print("transitionSourceFrame ", transitionSourceFrame)
        
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
            BKLog("toView == nil", prefix: "!")
            return
        }
        
        guard let imageVC = toViewController as? KBImageViewController else {
            BKLog("toViewController != KBImageViewController", prefix: "!")
            return
        }
        
        
        // Create a visual effect view and animate the effect in the transition animator
        //let effect: UIVisualEffect? = nil
        //let targetEffect: UIVisualEffect? = UIBlurEffect(style: .dark)
        let visualEffectView = UIView() //UIVisualEffectView(effect: effect)
        visualEffectView.backgroundColor = UIColor.black
        visualEffectView.alpha = 0.0
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)
        
        
        // ImageView
        let initialImageFrame = transitionSourceFrame
        
        let imageView = UIImageView(frame: containerView.convert(initialImageFrame, from: nil))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = imageVC.image
  
        // Calculate target frame
        let aspectRatio = CGSize(width: imageVC.image?.size.width ?? 1, height: imageVC.image?.size.height ?? 1)
        let targetImageFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: finalFrameForVC)
        
        BKLog("targetImageFrame: \(targetImageFrame)")
        
        // Add imageView
        containerView.addSubview(imageView)
        
        // Add target view
        toView.alpha = 0.0
        toView.frame = finalFrameForVC
        containerView.addSubview(toView)
        
        
        // Animate here
        UIView.animate(withDuration: transitionDuration, delay: 0,
                       usingSpringWithDamping: usingSpringWithDamping,
                       initialSpringVelocity: initialSpringVelocity, options: [],
                       
                       animations: { [unowned self] in
                        imageView.frame = targetImageFrame
                        visualEffectView.alpha = self.targetAlpha
        },
                       completion: { success in
                        toView.alpha = 1
                        visualEffectView.removeFromSuperview()
                        imageView.removeFromSuperview()
                        transitionContext.completeTransition(true)
        } )
        
        
        
        
    }
    
    /*
     func animationEnded(_ transitionCompleted: Bool) {
     
     }
     */
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return transitionDuration
    }
    
}


