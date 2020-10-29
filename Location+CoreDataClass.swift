//
//  Location+CoreDataClass.swift
//  MyLocation
//
//  Created by Naver on 2020/10/28.
//  Copyright © 2020 Johnny. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D{
        CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public var title: String?{
        if locationDescription.isEmpty{
            return "(No Description)"
        }else{
            return locationDescription
        }
    }

    public var subtitle: String?{
        return category
    }
    
    var hasPhoto: Bool{
        return photoID != nil
    }
    
    var photoURL: URL{
        assert(photoID != nil, "No photo id set")
        let fileName = "Photo-\(photoID!.intValue).jpg"
        return applicationDocumentsDirectory.appendingPathComponent(fileName)
    }
    
    var photoImage: UIImage?{
        return UIImage(contentsOfFile: photoURL.path)
    }
    
    func removeImage(){
        if hasPhoto{
            do{
                try FileManager.default.removeItem(at: photoURL)
            }catch{
                print("error removing file:\(error)")
            }
        }
    }
    
    class func nextPhotoID() -> Int{
        let userDefaults = UserDefaults.standard
        let currentID = userDefaults.integer(forKey: "photoID") + 1
        userDefaults.set(currentID, forKey: "photoID")
        userDefaults.synchronize()
        return currentID
    }
}
