//
//  LocationDetailsViewController.swift
//  MyLocation
//
//  Created by Naver on 2020/10/27.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

//创建该对象开销较大，定义为全局变量(默认为lazy loading模式,只加载一次，一直保存在内存中)
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}() //此处通过调用闭包函数来给它赋值



class LocationDetailsViewController: UITableViewController {
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark:CLPlacemark?
    var categoryName = "No Category"
    var date = Date()
    var descriptionText = ""
    
    var image: UIImage?
    var observer: Any!
    
    var locationToEdit: Location?{
        didSet{
            if let location = locationToEdit{
                coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                categoryName = location.category
                date = location.date
                descriptionText = location.locationDescription
                placemark = location.placemark
            }
        }
    }
    
    deinit {
        print("LocationsDetailViewController release")
        NotificationCenter.default.removeObserver(observer!)
    }
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    var managedObjectContext: NSManagedObjectContext!

    

    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = locationToEdit{
            title = "Edit Location"
            if location.hasPhoto{
                if let theImage = location.photoImage{
                    showImage(theImage)
                }
            }
        }
        listenForBackgroundNotification()
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        if let placemark = placemark{
            addressLabel.text = string(from: placemark)
        }else{
            addressLabel.text = "No Address Found"
        }
        dateLabel.text = format(date: date)
        
        print("add gesture")
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    //MARK:- Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory"{
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategory = categoryName
        }
    }
    
    
    // MARK:- Actions
    
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer){
        print("hide key board")
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0{
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    @IBAction func done() {
        let hudView = HudView.Hud(inView: tabBarController!.view, animated: true)
        let location: Location
        if let temp = locationToEdit{
            hudView.text = "Updated"
            location = temp
        }else{
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        location.locationDescription = descriptionTextView.text
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.category = categoryName
        location.placemark = placemark
        //只有在image picker view controller中选中了图片，此时image属性才有值
        if let image = image{
            if !location.hasPhoto{
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            if let data = image.jpegData(compressionQuality: 0.5){
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                }catch{
                    print("Error writing file: \(error)")
                }
            }
        }
        
        do {
            try managedObjectContext.save() //managedObjectContext是一个暂存器，掉save方法后才能真正持久化数据
            afterDelay(0.6, run: {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            })
        } catch  {
            fatalCoreDataError(error)
//            fatalError("Error: \(error)")
        }
        
        
      }

    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
      }
    
    //关联了unWind segue
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue){
        print("now LocationDetailViewController")
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategory
        categoryLabel.text = categoryName
    }
    
    //MARK:- Notification
    
    func listenForBackgroundNotification(){
       observer = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main, using: {
            [weak self] _ in
            if let weakSelf = self{
                if weakSelf.presentedViewController != nil{
                    weakSelf.dismiss(animated: true, completion: nil)
                }
                weakSelf.descriptionTextView.resignFirstResponder()
            }
        })
    }
    
    
    
    //MARK:- DataSource
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1{
            return indexPath
        }else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        }else if indexPath.section == 1 && indexPath.row == 0{
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
    }
    
    //MARK:- 打开 image picker
    func pickPhoto(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            showPhotoMenu()
        }else{
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu(){
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let librarySheet = UIAlertAction(title: "Choose from library", style: .default, handler: {
            _ in
            self.choosePhotoFromLibrary()
        })
        
        let cameraSheet = UIAlertAction(title: "Take photo with camera", style: .default, handler: {
            _ in
            self.takePhotoWithCamera()
        })
        
        let cancelSheet = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertSheet.addAction(librarySheet)
        alertSheet.addAction(cameraSheet)
        alertSheet.addAction(cancelSheet)
        
        present(alertSheet, animated: true, completion: nil)
    }
}




//MARK:- image picker delegate

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePicked = info[.editedImage] as? UIImage{
            image = imagePicked
            showImage(imagePicked)
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Helper Method
    func takePhotoWithCamera(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showImage(_ image: UIImage){
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        
        imageHeight.constant = 260
        tableView.reloadData()
    }
}



//MARK:- formate tool

extension LocationDetailsViewController{
    func string(from placemark: CLPlacemark) -> String{
      var text = ""

      if let s = placemark.subThoroughfare {
        text += s + " "
      }
      if let s = placemark.thoroughfare {
        text += s + ", "
      }
      if let s = placemark.locality {
        text += s + ", "
      }
      if let s = placemark.administrativeArea {
        text += s + " "
      }
      if let s = placemark.postalCode {
        text += s + ", "
      }
      if let s = placemark.country {
        text += s
      }
      return text
    }
    
    func format(date: Date) -> String{
        return dateFormatter.string(from: date)
    }
}

