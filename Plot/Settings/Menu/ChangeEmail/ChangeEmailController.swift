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
    var emailForVerification = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        configureChangeEmailView()
    }
    
    func configureChangeEmailView() {
        view.addSubview(changeEmailView)
        changeEmailView.frame = view.bounds
        changeEmailView.email.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        changeEmailView.nextView.addTarget(self, action: #selector(didTapSendSignInLink), for: .touchUpInside)
        changeEmailView.nextView.isEnabled = false
        changeEmailView.instructions.text = "Please enter your email."
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        changeEmailView.email.attributedPlaceholder = NSAttributedString(string: "New Email", attributes: attributes)
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
        navigationItem.leftBarButtonItem = leftBarButton
        changeEmailView.email.delegate = self
    }

    @objc func leftBarButtonDidTap() {
        self.dismiss(animated: true)
    }
        
    @objc func textFieldDidChange(_ textField: UITextField) {
        setRightBarButtonStatus()
    }
    
    func setRightBarButtonStatus() {
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
                basicErrorAlertWithClose(title: "Error", message: error.localizedDescription, controller: self)
            } else {
                basicErrorAlertWithClose(title: "Verification email sent", message: "Check your inbox for the verification link.", controller: self)
            }
        }
    }
}

extension ChangeEmailController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 25
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        emailForVerification = textField.text ?? ""

        if !emailForVerification.isValidEmail {
            changeEmailView.nextView.setTitleColor(.systemBlue, for: .normal)
            changeEmailView.nextView.backgroundColor = .secondarySystemGroupedBackground
        } else {
            changeEmailView.nextView.setTitleColor(.white, for: .normal)
            changeEmailView.nextView.backgroundColor = .systemBlue
        }
    }
}
