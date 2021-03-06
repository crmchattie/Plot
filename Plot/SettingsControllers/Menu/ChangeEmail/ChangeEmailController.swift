//
//  File.swift
//  Plot
//
//  Created by Cory McHattie on 2/20/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class ChangeEmailController: UIViewController {
    let changeEmailView = ChangeEmailView()
    var link: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        configureChangeEmailView()
    }
    
    func configureChangeEmailView() {
        view.addSubview(changeEmailView)
        changeEmailView.frame = view.bounds
        changeEmailView.nextView.addTarget(self, action: #selector(didTapSendSignInLink), for: .touchUpInside)
        changeEmailView.nextView.isEnabled = false
        
        changeEmailView.instructions.text = "Please enter your email."
        let attributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor]
        changeEmailView.email.attributedPlaceholder = NSAttributedString(string: "New Email", attributes: attributes)
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
        navigationItem.leftBarButtonItem = leftBarButton
    }
    

    @objc func leftBarButtonDidTap() {
        self.dismiss(animated: true)
    }
        
    @objc func textFieldDidChange(_ textField: UITextField) {
        setRightBarButtonStatus()
    }
    
    func setRightBarButtonStatus() {
        let emailForVerification = changeEmailView.email.text!
        if !isValidEmail(emailForVerification) {
            changeEmailView.nextView.isEnabled = false
        } else {
            changeEmailView.nextView.isEnabled = true
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

extension ChangeEmailController {
    func didTapSignInWithEmailLink(_ sender: AnyObject) {
        if let email = changeEmailView.email.text {
            Auth.auth().signIn(withEmail: email, link: self.link) { (user, error) in
                // [START_EXCLUDE]
                if error != nil {
                    basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Oops! Something happened, try again later.", controller: self)
                    return
                }
                self.navigationController!.popViewController(animated: true)
            }
            // [END signin_emaillink]
        }
    }
    
    @objc func didTapSendSignInLink(_ sender: AnyObject) {
        if let email = changeEmailView.email.text {
            // [START action_code_settings]
            let actionCodeSettings = ActionCodeSettings()
            actionCodeSettings.url = URL(string: "https://www.example.com")
            // The sign-in operation has to always be completed in the app.
            actionCodeSettings.handleCodeInApp = true
            actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
            // [END action_code_settings]
            // [START send_signin_link]
            Auth.auth().sendSignInLink(toEmail:email,
                                       actionCodeSettings: actionCodeSettings) { error in
                // [END_EXCLUDE]
                if error != nil {
                    basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Oops! Something happened, try again later.", controller: self)
                    return
                }
                // The link was successfully sent. Inform the user.
                // Save the email locally so you don't need to ask the user for it again
                // if they open the link on the same device.
                
                basicErrorAlertWith(title: "Sent Link", message: "Check your email for link", controller: self)
                // [START_EXCLUDE]
            }
            // [END send_signin_link]
        }
    }
}
