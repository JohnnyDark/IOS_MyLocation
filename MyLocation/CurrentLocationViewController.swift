//
//  FirstViewController.swift
//  MyLocation
//
//  Created by Naver on 2020/10/27.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData



class CurrentLocationViewController: UIViewController{
    //坐标获取
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    //坐标转码
    let geoCoder = CLGeocoder()
    var placemark:CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    var timer: Timer?
    
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    var managedObjectContext: NSManagedObjectContext!

    
    override func viewDidLoad() {
        updateLabels()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    //MARK:- Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation"{
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    // MARK:- Actions
    
    @IBAction func getLocation() {
        //请求位置获取权限
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        //权限判断为没有权限
        if authStatus == .denied || authStatus == .restricted{
            showLocationServicesDeniedAlert()
            return
        }
        //设置location manager, 进行位置获取
//        startLocationManager()
        //根据不同的搜索状态实现getButton的点击效果及显示效果
        if updatingLocation{
            stopLocationManager()
        }else{
            startLocationManager()
        }
        updateLabels()//开始后立即进行UI数据更新
    }
}

//MARK:- LocationManager Delegate

extension CurrentLocationViewController: CLLocationManagerDelegate {
    //处理位置获取过程中的error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
        if (error as NSError).code == CLError.locationUnknown.rawValue{ //向下转型
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations: \(newLocation)")
//        location = newLocation
//        lastLocationError = nil //当真正获取到数据后立即清除之前保存的error对象，才能正确更新label数据
//        updateLabels()
        if newLocation.timestamp.timeIntervalSinceNow < -5{
            return
        }
        
        if newLocation.horizontalAccuracy < 0{
            return
        }
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location{
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            lastLocationError = nil
            location = newLocation
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("*** we're done!")
                stopLocationManager()
                if distance > 0{
                    performingReverseGeocoding = false
                }
            }
            updateLabels()
            
            //坐标转码
            if !performingReverseGeocoding{
                print("starting reverse")
                performingReverseGeocoding = true
                geoCoder.reverseGeocodeLocation(newLocation){
                    (placemarks, error) in
                    self.lastGeocodingError = error
                    if error == nil, let placemarks = placemarks, !placemarks.isEmpty{
                        self.placemark = placemarks.last!
                    }else{
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                }
            }else if distance < 1{
                let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
                if timeInterval > 10{
                    print("*** Force done!")
                    stopLocationManager()
                    updateLabels()
                }
            }
        }
    }
}

//MARK:- 控制location Manager开始/停止

extension CurrentLocationViewController{
    func stopLocationManager(){
        if updatingLocation{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            //停止后，移除timer
            if let timer = timer{
                timer.invalidate()
            }
        }
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            //清除上一次的坐标数据
            lastLocationError = nil
            location = nil
            
            //重新开始时，移除上一次的地址转码内容
            placemark = nil
            lastGeocodingError = nil
            
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeout), userInfo: nil, repeats: false)
        }
    }
    
    @objc func didTimeout(){
        print("*** Time Out")
        stopLocationManager()
        lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
        updateLabels()
    }
}

//MARK:- Helper Methods

extension CurrentLocationViewController{
    
    //处理权限相关error
    func showLocationServicesDeniedAlert(){ //无位置访问权限 error
        let alert = UIAlertController(title: "Location service denied", message: "Please enable location service in setting", preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    //view的数据更新
    func updateLabels(){
        if let location = location{ //有位置数据时
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            if let placemark = placemark{
                addressLabel.text = string(from: placemark)
            }else if performingReverseGeocoding{
                addressLabel.text = "Searching for Address..."
            }else if lastGeocodingError != nil{
                addressLabel.text = "Error Finding Address..."
            }else{
                addressLabel.text = "No Address Founded..."
            }
        }else{ //没有获取位置数据,场景判断
            let statusMessage:String
            if let error = lastLocationError as NSError?{
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue{//没有权限
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error geting location" //位置获取出错
                }
            }else if !CLLocationManager.locationServicesEnabled(){ //手机系统的位置权限被禁止
                statusMessage = "Location Services Disabled"
            }else if updatingLocation{ //正在获取位置中
                statusMessage = "Searching..."
            }else{//进入该界面，但为进行任何操作
                statusMessage = "Tap 'Get My Location' to start"
            }
            messageLabel.text = statusMessage
        }
        configureGetButton() //设置getButton的状态
    }
    
    func configureGetButton(){
        if updatingLocation{
            getButton.setTitle("Stop", for: .normal)
        }else{
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func string(from placemark: CLPlacemark) -> String{
        var line1 = ""
        if let s = placemark.subThoroughfare {
        line1 += s + " "
        }
        if let s = placemark.thoroughfare {
            line1 += s
        }

     
        var line2 = ""
        if let s = placemark.locality {
            line2 += s + " "
        }
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
    }
}

