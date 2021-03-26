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
        if !emailForVerification.isValidEmail {
            changeEmailView.nextView.isEnabled = false
        } else {
            changeEmailView.nextView.isEnabled = true
        }
    }
}

extension ChangeEmailController {

    @objc func didTapSendSignInLink(_ sender: AnyObject) {
        guard let email = changeEmailView.email.text else { return }

        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://plotliving.page.link?email=\(email)")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
            if let error = error {
                basicErrorAlertWith(title: "Error", message: error.localizedDescription, controller: self)
            } else {
                basicErrorAlertWith(title: "Verification email sent", message: "Check your inbox for the verification link.", controller: self)
            }
        }
    }
}
