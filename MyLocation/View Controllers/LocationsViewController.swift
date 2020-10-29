//
//  LocationsViewController.swift
//  MyLocation
//
//  Created by Naver on 2020/10/28.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationsViewController: UITableViewController {
    
    var managedObjectContext: NSManagedObjectContext!
//    var locations:[Location] = []
    //使用NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        let fetchRequest = NSFetchRequest<Location>()
        let entity = Location.entity()
        fetchRequest.entity = entity
        
        let sortDescriptor1 = NSSortDescriptor(key: "date", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "category", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor2, sortDescriptor1]
        fetchRequest.fetchBatchSize = 20
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem //添加进入编辑模式按钮
        performFetch()
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    //MARK:- Helper Method
    func performFetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch  {
            fatalCoreDataError(error)
        }
    }
    
    //MARK:- Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections?[section]{
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        let location = fetchedResultsController.object(at: indexPath)
        cell.configure(for: location)
        return cell
    }
    
    //MARK:- Table view delegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let location = fetchedResultsController.object(at: indexPath)
            managedObjectContext.delete(location)
            location.removeImage()
            do {
                try managedObjectContext.save()
            } catch {
                fatalCoreDataError(error)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation"{
            let controller = segue.destination as! LocationDetailsViewController
            if let cell = sender as? UITableViewCell{
                let indexPath = tableView.indexPath(for: cell)!
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
                controller.managedObjectContext = managedObjectContext
            }
        }
    }
}

extension LocationsViewController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerWillChangeContent")
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangeInsert (object)")
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            print("*** NSFetchedResultsChangeDelete (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            print("*** NSFetchedResultsChangeUpdate (object)")
            if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell{
                let location = controller.object(at: indexPath!) as! Location
                cell.configure(for: location)
            }
        case .move:
            print("*** NSFetchedResultsChangeMove (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [indexPath!], with: .fade)
        @unknown default:
            fatalError("Unhandled switch case of NSFetchedResultsChangeType")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
          print("*** NSFetchedResultsChangeInsert (section)")
          tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
          print("*** NSFetchedResultsChangeDelete (section)")
          tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update:
          print("*** NSFetchedResultsChangeUpdate (section)")
        case .move:
          print("*** NSFetchedResultsChangeMove (section)")
        @unknown default:
            fatalError("Unhandled switch case of NSFetchedResultsChangeType")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
    }
}
