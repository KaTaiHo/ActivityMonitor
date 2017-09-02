//
//  DataViewController.swift
//  ActivityMonitor
//
//  Created by Ka Tai Ho on 8/29/17.
//  Copyright © 2017 SDLtest. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class DataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var postData = [String]()
    var ref:FIRDatabaseReference?
    var databaseHandle:FIRDatabaseHandle?
    
    struct activityData {
        var activity:String
        var datetime:String
    }
    
    var postDataWrapper = [activityData]()
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self;
        tableView.dataSource = self;
        ref = FIRDatabase.database().reference()
        let userId = FIRAuth.auth()?.currentUser?.uid
        
        ref?.child("users").child(userId!).child("Posts").observeSingleEvent(of: .value, with: { snapshot in
            print(snapshot.childrenCount) // I got the expected number of items
            for rest in snapshot.children.allObjects as! [FIRDataSnapshot] {
                guard let restDict = rest.value as? [String: Any] else { continue }
                let message = restDict["message"] as? String
                self.postData.insert(message!, at: 0)
            }
            self.tableView.reloadData()
        })
        
        ref?.child("users").child(userId!).child("Posts").queryLimited(toLast: 1)
            .observe(.childAdded, with: { snapshot in
                guard let temp = snapshot.value as? [String: Any] else { return }
                let message = temp["message"] as? String
                self.postData.insert(message!, at: 0)
                print(snapshot.value!)
                self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = postData[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return postData.count
    }
}
