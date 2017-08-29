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
    
    var isSignIn:Bool = true
    
    override func loadView() {
        super.loadView()
        _login_button.backgroundColor = UIColor(hex: "27B4FF")
        _login_button.layer.cornerRadius = 10;
        _login_button.clipsToBounds = true;
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                FIRAuth.auth()?.signIn(withEmail: email, password: pass,
                                       completion: {(user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "goToData", sender: self)
                        
                    }
                    else {
                        
                    }
                    
                })
                
            }
            else {
                FIRAuth.auth()?.createUser(withEmail: email, password: pass, completion: {
                    (user, error) in
                    if let u = user {
                        //go to home screen
                        self.performSegue(withIdentifier: "goToData", sender: self)
                    }
                    else {
                        //error
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
