//
//  LocationCell.swift
//  MyLocation
//
//  Created by Naver on 2020/10/28.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

    @IBOutlet weak var locationDescriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    func configure(for location: Location){
        if !location.locationDescription.isEmpty{
            locationDescriptionLabel.text = location.locationDescription
        }else{
            locationDescriptionLabel.text = "(No Description)"
        }
        
        if let placemark = location.placemark {
            var text = ""
            if let s = placemark.subThoroughfare {
              text += s + " "
            }
            if let s = placemark.thoroughfare {
              text += s + ", "
            }
            if let s = placemark.locality {
              text += s
            }
            addressLabel.text = text
          } else {
            addressLabel.text = String(format:
              "Lat: %.8f, Long: %.8f", location.latitude,
                                       location.longitude)
          }
        photoImageView.image = thumbnail(for: location)
    }
    
    func thumbnail(for location: Location) -> UIImage{
        if location.hasPhoto, let image = location.photoImage{
            return image.resized(withBounds: CGSize(width: 52, height: 52))
        }
        return UIImage()
    }
}
