//
//  CategoryPickerViewController.swift
//  MyLocation
//
//  Created by Naver on 2020/10/27.
//  Copyright © 2020 Johnny. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    
    var selectedCategory = ""
    var selectedIndexPath = IndexPath()
    
    var categoryNames = ["No Category","Apple Store","Bar","Bookstore","Club","Grocery Store","Historic Building","House","Icecream Vendor","Landmark","Park"]

    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<categoryNames.count{
            if categoryNames[i] == selectedCategory{
                selectedIndexPath = IndexPath(row: i, section: 0)
                return
            }
        }
    }
    
    //MARK:- Navigation
    
    //在unWind segue中该方法先执行
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("picker category")
        if segue.identifier == "PickedCategory"{
            if let cell = sender as? UITableViewCell{
                if let indexPath = tableView.indexPath(for: cell){
                    selectedCategory = categoryNames[indexPath.row]
                }
            }
        }
    }
    
    //MARK:- Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let categoryName = categoryNames[indexPath.row]
        cell.textLabel!.text = categoryName
        if categoryName == selectedCategory{
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath != selectedIndexPath{
            if let newCell = tableView.cellForRow(at: indexPath){
                newCell.accessoryType = .checkmark
            }
            if let oldCell = tableView.cellForRow(at: selectedIndexPath){
                oldCell.accessoryType = .none
            }
            selectedIndexPath = indexPath
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
