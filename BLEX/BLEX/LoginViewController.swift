// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//  LoginViewController.swift
//  BLEX
//
//  Created by Ashu Joshi on 4/17/21.
//

import UIKit
import Amplify
import AmplifyPlugins

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.signOutLocally()
        self.signOutGlobally()

        // Do any additional setup after loading the view.
        self.loginButton.isEnabled = false
    }
    
    @IBAction func onLogin(_ sender: Any) {
        guard
            let username = self.usernameField.text,
            let password = self.passwordField.text
            else {
                return
        }
        self.signIn(username: username, password: password)
    }
  
    @IBAction func usernameDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
    
    @IBAction func passwordDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if let username = self.usernameField.text,
            let password = self.passwordField.text {
            
            if ((username.count > 0) &&
                (password.count > 0)) {
                self.loginButton.isEnabled = true
            }
        }
        
        return true
    }
    
}

extension LoginViewController {
    
    fileprivate func dismissKeyboard() {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
    };
    
    fileprivate func signIn(username: String, password: String) {
        Amplify.Auth.signIn(username: username, password: password) { result in
            switch result {
            case .success:
                print("Sign in succeeded")
                let currentUser = Amplify.Auth.getCurrentUser()
                print(currentUser as Any)
                print(currentUser?.userId as Any)
                self.displaySuccessMessage()
            case .failure(let error):
                print("Sign in failed \(error)")
                self.displayLoginError(error: error as NSError)
            }
        }
    }
    
    func signInWithWebUI() {
        Amplify.Auth.signInWithWebUI(presentationAnchor: self.view.window!) { result in
            switch result {
            case .success:
                print("Sign in succeeded")
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
    fileprivate func signOutLocally() {
        Amplify.Auth.signOut() { result in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }
    
    fileprivate func signOutGlobally() {
        Amplify.Auth.signOut(options: .init(globalSignOut: true)) { result in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }
    
    fileprivate func displayLoginError(error:NSError) {
        DispatchQueue.main.async {
            let alertController =
                UIAlertController(title: error.userInfo["__type"] as? String,
                                      message: error.userInfo["message"] as? String,
                                  preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok",style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    fileprivate func displaySuccessMessage() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Success.",
                                                    message: "Login succesful!",
                                                    preferredStyle: .alert)
            
            let action = UIAlertAction(title: "Ok", style:.default,
                                       handler: { action in
                                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                        let viewController = storyboard.instantiateViewController(withIdentifier: "BLEDevices")
                                        viewController.modalPresentationStyle = .fullScreen
                                        self.present(viewController, animated: true, completion: nil)
                                        
            }
            )
            
            alertController.addAction(action)
            
            self.present(alertController, animated: true, completion:  nil)
            
        }
        
    }

}
