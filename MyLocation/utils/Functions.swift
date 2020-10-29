//
//  Functions.swift
//  MyLocation
//
//  Created by Naver on 2020/10/28.
//  Copyright © 2020 Johnny. All rights reserved.
//

import Foundation

//声明通知
let CoreDataSaveFailedNotification = Notification.Name("CoreDataSaveFailedNotification")
//发送通知
func fatalCoreDataError(_ error: Error){
    print("*** Fatal Error: \(error)")
    NotificationCenter.default.post(name: CoreDataSaveFailedNotification, object: nil)
}


func afterDelay(_ seconds: Double, run: @escaping () -> Void){
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
//    DispatchQueue.main.async(execute: run)
}

let applicationDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}()


