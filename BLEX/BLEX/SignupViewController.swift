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
//  SignupViewController.swift
//  BLEX
//
//  Created by Ashu Joshi on 6/30/21.
//

import UIKit
import Amplify
import AmplifyPlugins

class SignupViewController: UIViewController {

   
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.createAccountButton.isEnabled = false

    }
   

    @IBAction func onCreateAccount(_ sender: Any) {
        
        guard let username = self.usernameField.text,
            let password = self.passwordField.text,
            let emailAddress = self.emailField.text,
            let name = self.nameField.text
    
            else {
                return
        }
        
        print(name, username, password, emailAddress)
        
        self.signUp(username: username, password: password, email: emailAddress)

    }

    
    @IBAction func usernameDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    @IBAction func passwordDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    @IBAction func emailDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
    
    @IBAction func nameDidEndOnExit(_ sender: Any) {
        dismissKeyboard()
    }
}

extension SignupViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if let username = self.usernameField.text,
            let password = self.passwordField.text,
            let emailAddress = self.emailField.text,
            let name = self.nameField.text {
            
            if ((username.count > 0) &&
                (password.count > 0) &&
                (emailAddress.count > 0) &&
                (name.count > 0)) {
                self.createAccountButton.isEnabled = true
            }
        }
        
        return true
    }
}


extension SignupViewController {
    
    func signUp(username: String, password: String, email: String) {
        let userAttributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        Amplify.Auth.signUp(username: username, password: password, options: options) { result in
            switch result {
            case .success(let signUpResult):
                if case let .confirmUser(deliveryDetails, _) = signUpResult.nextStep {
                    print("Delivery details \(String(describing: deliveryDetails))")
                    self.requestConfirmationCode(username: username)
                } else {
                    print("SignUp Complete")
                }

            case .failure(let error):
                print("An error occurred while registering a user \(error)")
            }
        }
    }
    
    func confirmSignUp(for username: String, with confirmationCode: String) {
        Amplify.Auth.confirmSignUp(for: username, confirmationCode: confirmationCode) { result in
            switch result {
            case .success:
                print("Confirm signUp succeeded")
                self.displaySuccessMessage()
            case .failure(let error):
                print("An error occurred while confirming sign up \(error)")
            }
        }
    }
}


extension SignupViewController {
    
    fileprivate func dismissKeyboard() {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        emailField.resignFirstResponder()
        nameField.resignFirstResponder()
    }
    
    fileprivate func displaySignupError(error:NSError, completion:(() -> Void)?) {
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                    message: error.userInfo["message"] as? String,
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                if let completion = completion {
                    completion()
                }
            }

            alertController.addAction(okAction)
        
        
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func requestConfirmationCode(username: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Confirmation.",
                                                    message: "Please type the 6-digit confirmation code that has been sent to your email address.",
                                                    preferredStyle: .alert)
            
            alertController.addTextField { (textField) in
                textField.placeholder = "######"
            }
        
            let okAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                if let firstTextField = alertController.textFields?.first,
                    let confirmationCode = firstTextField.text {
                    
                    self.confirmSignUp(for: username, with: confirmationCode)

                }
            })
        
        
            alertController.addAction(okAction)
      
        
            self.present(alertController, animated: true, completion:  nil)
        }
    }
    
    
    fileprivate func displaySuccessMessage() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Success.",
                                                    message: "Your account has been created!.",
                                                    preferredStyle: .alert)
            
            let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(withIdentifier: "LoginScreen")
                viewController.modalPresentationStyle = .fullScreen
                self.present(viewController, animated: true, completion: nil)
            })
            
            alertController.addAction(action)
        
        
            self.present(alertController, animated: true, completion:  nil)
        }
    }
    
}
