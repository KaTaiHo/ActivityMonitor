//
//  HomeViewController.swift
//  ActivityMonitor
//
//  Created by Ka Tai Ho on 8/25/17.
//  Copyright © 2017 SDLtest. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController {

    @IBOutlet weak var _username: UITextField!
    
    @IBOutlet weak var _password: UITextField!
    
    @IBOutlet weak var _login_button: UIButton!
    
    @IBOutlet weak var signInSelector: UISegmentedControl!
    
    var ref: FIRDatabaseReference?
    
    var isSignIn:Bool = true
    
    override func loadView() {
        super.loadView()
        _login_button.backgroundColor = UIColor(hex: "27B4FF")
        _login_button.layer.cornerRadius = 10;
        _login_button.clipsToBounds = true;
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signInSelectorChanged(_ sender: UISegmentedControl) {
        isSignIn = !isSignIn
        
        if isSignIn {
            _login_button.setTitle("Sign In", for: .normal)
        }
        else {
            _login_button.setTitle("Register", for: .normal)
        }
    }

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // TODO: form validation
        if let email = _username.text, let pass = _password.text {
            if isSignIn {
                FIRAuth.auth()?.signIn(withEmail: email, password: pass, completion: {(user, error) in
                    if user != nil {
                        self.performSegue(withIdentifier: "goToData", sender: self)
                    }
                    else {
                        print("error trying to login")
                    }
                })
            }
            else {
                FIRAuth.auth()?.createUser(withEmail: email, password: pass, completion: {
                    (user, error) in
                    if user != nil {
                        if error != nil {
                            print(error!.localizedDescription)
                            return
                        }
                        let userReference = self.ref?.child("users")
                        let uid = user?.uid
                        let newUserReference = userReference?.child(uid!)
                        let emptyString: [String] = []
                        newUserReference?.setValue(["email": self._username.text!, "Posts": emptyString])
                        
                        //go to home screen
                        self.performSegue(withIdentifier: "goToData", sender: self)
                    }
                    else {
                        //error
                        print("error trying to register")
                    }
                })
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _username.resignFirstResponder()
        _password.resignFirstResponder()
    }
}
