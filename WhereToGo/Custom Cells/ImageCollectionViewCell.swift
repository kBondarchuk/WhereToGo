//
//  ImageCollectionViewCell.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 19.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func prepareForReuse()
    {
        imageView.image = nil
    }
    

    
    // MARK: - Private Methods
    // -----------------------
    
    func configure(with image: UIImage)
    {
        self.imageView.image = image
    }
    
    func configure(for movie: Movie, photoNumber number: Int)
    {
        
        //1
        guard let urlString = movie.images?[number] else {
            return
        }
        
        //2
        if let image = movie.fetchedImages?[urlString] as? UIImage {
            self.imageView.image = image
            return
        }
        
        // Proceed download
        if let url = URL(string: movie.images?[number] ?? "") {
            
            //BKLog(url)
            
            BKLog("Run download thread...", prefix: ">")
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                if let imageData = try? Data(contentsOf: url){
                    // UI
                    DispatchQueue.main.async {
                        BKLog(imageData.debugDescription)
                        self.imageView.image = UIImage(data: imageData)
                        
                        // Cache
                        movie.fetchedImages?.setValue(self.imageView.image, forKey: urlString)
                    }
                    
                }
                
            }
        }
        
        
    }
}
