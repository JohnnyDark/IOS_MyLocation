//
//  SceneDelegate.swift
//  MyLocation
//
//  Created by Naver on 2020/10/27.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores{
            storeDescription, error in
            if let error = error{
                fatalError("could not load data store: \(error)")
            }
        }
        return container
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = persistentContainer.viewContext
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        //依赖注入将context 传递给其他view controller
        let tabController = window?.rootViewController as? UITabBarController
        if let tabController = tabController{
            if let controllers = tabController.viewControllers{
                // tab 1
                var naviController = controllers[0] as! UINavigationController
                let controller1 = naviController.viewControllers.first as! CurrentLocationViewController
                controller1.managedObjectContext = managedObjectContext
                //tab 2
                naviController = controllers[1] as! UINavigationController
                let controller2 = naviController.viewControllers.first as! LocationsViewController
                controller2.managedObjectContext = managedObjectContext
                //tab 3
                naviController = controllers[2] as! UINavigationController
                let controller3 = naviController.viewControllers.first as! MapViewController
                controller3.managedObjectContext = managedObjectContext
            }
        }
        listenForFatalCoreDataNotifications() //开始监听Notification
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func listenForFatalCoreDataNotifications(){
        NotificationCenter.default.addObserver(forName: CoreDataSaveFailedNotification, object: nil, queue: OperationQueue.main){
            notification in
            let message = """
            There was a fatal error in the app and it cannot continue.

            Press OK to terminate the app. Sorry for the inconvenience.
            """
            
            let alert = UIAlertController(title: "Internal Error", message: message, preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default, handler: {
                _ in
                let exception = NSException(
                          name: NSExceptionName.internalInconsistencyException,
                          reason: "Fatal Core Data error", userInfo: nil)
                exception.raise()
            })
            
            alert.addAction(action)
            
            let tabController = self.window!.rootViewController!
            tabController.present(alert, animated: true, completion: nil)
        }
    }
}

