//
//  ChooseEmailController.swift
//  Plot
//
//  Created by Cory McHattie on 2/20/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class ChooseEmailController: UIViewController {
    let chooseEmailView = ChooseEmailView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        configureChangeEmailView()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    func configureChangeEmailView() {
        view.addSubview(chooseEmailView)
        chooseEmailView.frame = view.bounds
        chooseEmailView.emailView.addTarget(self, action: #selector(goToChangeEmailController), for: .touchUpInside)
        chooseEmailView.googleView.addTarget(self, action: #selector(signInToGoogle), for: .touchUpInside)
        
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
        navigationItem.leftBarButtonItem = leftBarButton
        chooseEmailView.instructions.text = "Please choose your email provider."
    }
    
    @objc func leftBarButtonDidTap() {
        self.dismiss(animated: true)
    }
    
    var isVerificationSent = false
    
    @objc func goToChangeEmailController() {
        let destination = ChangeEmailController()
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func signInToGoogle() {
        GIDSignIn.sharedInstance()?.signIn()
    }
}

extension ChooseEmailController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if error != nil {
            basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Oops! Something happened, try again later.", controller: self)
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Oops! Something happened, try again later.", controller: self)
                return
            }
            if let email = user.profile.email {
                let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
                userReference.updateChildValues(["email" : email]) { (error, reference) in
                    if error != nil {
                        basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Number changing process failed. Please try again later.", controller: self)
                        return
                    }
                    
                    self.dismiss(animated: true)
                }
            }
        }
    }
}
