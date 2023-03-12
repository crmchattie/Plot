//
//  EnterVerificationCodeController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit

class EnterVerificationCodeController: UIViewController {
    let enterVerificationContainerView = EnterVerificationContainerView()
    
    let phoneNumberKit = PhoneNumberKit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(enterVerificationContainerView)
        enterVerificationContainerView.frame = view.bounds
        enterVerificationContainerView.resend.addTarget(self, action: #selector(sendSMSConfirmation), for: .touchUpInside)
        enterVerificationContainerView.nextView.addTarget(self, action: #selector(rightBarButtonDidTap), for: .touchUpInside)
        enterVerificationContainerView.enterVerificationCodeController = self
        enterVerificationContainerView.verificationCode.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        if let text = enterVerificationContainerView.titleNumber.text {
            do {
                let phoneNumber = try self.phoneNumberKit.parse(text)
                enterVerificationContainerView.titleNumber.text = self.phoneNumberKit.format(phoneNumber, toType: .international)
            } catch {
                return
            }
        }
        
    }
    
    fileprivate func configureNavigationBar () {
        self.navigationItem.hidesBackButton = true
    }
    
    func setRightBarButton(with title: String) {
        let rightBarButton = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(rightBarButtonDidTap))
        self.navigationItem.rightBarButtonItem = rightBarButton
        
    }
    
    @objc fileprivate func sendSMSConfirmation () {
        
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
            return
        }
        
        enterVerificationContainerView.resend.isEnabled = false
        print("tapped sms confirmation")
                
        var phoneNumberForVerification = String()
        
        do {
            let phoneNumber = try self.phoneNumberKit.parse(enterVerificationContainerView.titleNumber.text!)
            phoneNumberForVerification = self.phoneNumberKit.format(phoneNumber, toType: .e164)
        } catch {
            phoneNumberForVerification = enterVerificationContainerView.titleNumber.text!
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberForVerification, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print("confirmation error")
                basicErrorAlertWithClose(title: "Error", message: error.localizedDescription + "\nPlease try again later.", controller: self)
                return
            }
            
            print("verification sent")
            self.enterVerificationContainerView.resend.isEnabled = false
            
            userDefaults.updateObject(for: userDefaults.authVerificationID, with: verificationID)
            self.enterVerificationContainerView.runTimer()
        }
    }
    
    @objc func leftBarButtonDidTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func rightBarButtonDidTap () {}
    
    func changeNumber() {
        enterVerificationContainerView.verificationCode.resignFirstResponder()
        
        let verificationID = userDefaults.currentStringObjectState(for: userDefaults.changeNumberAuthVerificationID)
        let verificationCode = enterVerificationContainerView.verificationCode.text
        
        if verificationID == nil {
            self.enterVerificationContainerView.verificationCode.shake()
            return
        }
        
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
            return
        }
        
        //    ARSLineProgress.ars_showOnView(self.view)
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        
        let credential = PhoneAuthProvider.provider().credential (withVerificationID: verificationID!, verificationCode: verificationCode!)
        
        Auth.auth().currentUser?.updatePhoneNumber(credential, completion: { (error) in
            if error != nil {
                self.removeSpinner()
                basicErrorAlertWithClose(title: "Error", message: error?.localizedDescription ?? "Number changing process failed. Please try again later.", controller: self)
                return
            }
            
            var phoneNumberForFB = String()
            
            do {
                let phoneNumber = try self.phoneNumberKit.parse(self.enterVerificationContainerView.titleNumber.text!)
                phoneNumberForFB = self.phoneNumberKit.format(phoneNumber, toType: .e164)
            } catch {
                phoneNumberForFB = self.enterVerificationContainerView.titleNumber.text!
            }
            
            let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
            userReference.updateChildValues(["phoneNumber" : phoneNumberForFB]) { (error, reference) in
                if error != nil {
                    self.removeSpinner()
                    basicErrorAlertWithClose(title: "Error", message: error?.localizedDescription ?? "Number changing process failed. Please try again later.", controller: self)
                    return
                }
                
                self.removeSpinner()
                self.dismiss(animated: true)
            }
        })
    }
    
    func authenticate() {
        enterVerificationContainerView.verificationCode.resignFirstResponder()
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
            return
        }
        
        let verificationID = userDefaults.currentStringObjectState(for: userDefaults.authVerificationID)
        let verificationCode = enterVerificationContainerView.verificationCode.text
        
        guard let unwrappedVerificationID = verificationID, let unwrappedVerificationCode = verificationCode, !unwrappedVerificationCode.isEmpty else {
            self.removeSpinner()
            self.enterVerificationContainerView.verificationCode.shake()
            return
        }
        
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
        }
        
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        
        let credential = PhoneAuthProvider.provider().credential (
            withVerificationID: unwrappedVerificationID,
            verificationCode: unwrappedVerificationCode)
        
        Auth.auth().signIn(with: credential) { (authDataResult, error) in
            if error != nil {
                self.removeSpinner()
                basicErrorAlertWithClose(title: "Error", message: error?.localizedDescription ?? "Oops! Something happened, try again later.", controller: self)
                return
            }
            
            let destination = UserProfileController()
            do {
                let phoneNumber = try self.phoneNumberKit.parse(self.enterVerificationContainerView.titleNumber.text ?? "")
                destination.userProfileContainerView.phone.text = self.phoneNumberKit.format(phoneNumber, toType: .international)
            } catch {
                destination.userProfileContainerView.phone.text = self.enterVerificationContainerView.titleNumber.text
            }
            
            destination.checkIfUserDataExists(completionHandler: { _ in
                self.removeSpinner()
                guard self.navigationController != nil else { return }
                if !(self.navigationController!.topViewController!.isKind(of: UserProfileController.self)) {
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            })
        }
    }
}

extension EnterVerificationCodeController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let verificationCode = textField.text, !verificationCode.isEmpty else {
            enterVerificationContainerView.nextView.setTitleColor(.systemBlue, for: .normal)
            enterVerificationContainerView.nextView.backgroundColor = .secondarySystemGroupedBackground
            return
        }
        enterVerificationContainerView.nextView.setTitleColor(.white, for: .normal)
        enterVerificationContainerView.nextView.backgroundColor = .systemBlue
    }
}
