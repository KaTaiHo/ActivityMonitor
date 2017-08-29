//
//  ComposeViewController.swift
//  ActivityMonitor
//
//  Created by Ka Tai Ho on 8/29/17.
//  Copyright © 2017 SDLtest. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ComposeViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    var ref: FIRDatabaseReference?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPost(_ sender: Any) {
        ref?.child("Posts").childByAutoId().setValue(textView.text)
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelPost(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
