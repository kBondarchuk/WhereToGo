//
//  MovieTableViewCell.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 12.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

class MovieTableViewCell: UITableViewCell {

    static let defaultHeight: CGFloat = 120.0
    
    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var director: UILabel!
    @IBOutlet weak var genres: UILabel!
    @IBOutlet weak var country: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var year: UILabel!
    
    
    
    // MARK: - Private Methods
    // -----------------------
    
    func configure(for object: Movie)
    {
        //BKLog("object.id: \(object.objectID)", prefix: "2")
        title.text = object.title
        country.text = object.country
        genres.text = object.genres
        director.text = object.director
        year.text = object.age_restriction
        
        // Image
        if object.poster_thumbnail != nil {
            posterImage?.image = UIImage(data: object.poster_thumbnail! as Data)
        }else{
            posterImage?.image = nil
        }
        
    }
    
}
