//
//  EnterPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SafariServices
import PhoneNumberKit

class EnterPhoneNumberController: UIViewController {    
    let phoneNumberKit = PhoneNumberKit()
    let phoneNumberContainerView = EnterPhoneNumberContainerView()
    let countries = Country().countries
    
    var phoneNumberForVerification = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        configurePhoneNumberContainerView()
        phoneNumberContainerView.selectCountry.addTarget(self, action: #selector(openCountryCodesList), for: .touchUpInside)
        setCountry()
        self.hideKeyboardWhenTappedAround()

    }
    
    func configurePhoneNumberContainerView() {
        view.addSubview(phoneNumberContainerView)
        phoneNumberContainerView.frame = view.bounds
        phoneNumberContainerView.nextView.addTarget(self, action: #selector(rightBarButtonDidTap), for: .touchUpInside)
        phoneNumberContainerView.phoneNumber.delegate = self
    }
    
    @objc func leftBarButtonDidTap() {
        phoneNumberContainerView.phoneNumber.resignFirstResponder()
        self.dismiss(animated: true)
    }
    
    fileprivate func setCountry() {
        for country in countries {
            if country["code"] == countryCode {
                phoneNumberContainerView.countryCode.text = country["dial_code"]
                phoneNumberContainerView.selectCountry.setTitle(country["name"], for: .normal)
            }
        }
    }
    
    
    @objc func openCountryCodesList() {
        let picker = SelectCountryCodeController()
        picker.delegate = self
        phoneNumberContainerView.phoneNumber.resignFirstResponder()
        navigationController?.pushViewController(picker, animated: true)
    }
    
    var isVerificationSent = false
    
    @objc func rightBarButtonDidTap () {
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
            return
        }
                
        if phoneNumberForVerification.isEmpty || phoneNumberForVerification.count < 4 || phoneNumberForVerification.count < 4 || phoneNumberContainerView.countryCode.text == " - " {
            phoneNumberContainerView.phoneNumber.shake()
        } else {
            if !isVerificationSent {
                sendSMSConfirmation()
            } else {
                print("verification has already been sent once")
            }            
        }
    }
    
    func sendSMSConfirmation () {
        do {
            let phoneNumber = try self.phoneNumberKit.parse(phoneNumberForVerification)
            phoneNumberForVerification = phoneNumberContainerView.countryCode.text! + String(phoneNumber.nationalNumber)
        } catch {
            phoneNumberForVerification = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberForVerification, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                basicErrorAlertWithClose(title: "Error", message: error.localizedDescription + "\nPlease try again later.", controller: self)
                return
            }

            self.isVerificationSent = true
            userDefaults.updateObject(for: userDefaults.authVerificationID, with: verificationID)
        }
    }
}

extension EnterPhoneNumberController: CountryPickerDelegate {
    func countryPicker(_ picker: SelectCountryCodeController, didSelectCountryWithName name: String, code: String, dialCode: String) {
        phoneNumberContainerView.selectCountry.setTitle(name, for: .normal)
        phoneNumberContainerView.countryCode.text = dialCode
        picker.navigationController?.popViewController(animated: true)
    }
}

extension EnterPhoneNumberController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        do {
            let phoneNumber = try self.phoneNumberKit.parse(textField.text ?? "")
            phoneNumberForVerification = String(phoneNumber.nationalNumber)
            textField.text = self.phoneNumberKit.format(phoneNumber, toType: .national)
        } catch {
            phoneNumberForVerification = phoneNumberContainerView.phoneNumber.text ?? ""
        }
        
        if phoneNumberForVerification.isEmpty || phoneNumberForVerification.count < 4 || phoneNumberForVerification.count < 4 || phoneNumberContainerView.countryCode.text == " - " {
            phoneNumberContainerView.nextView.setTitleColor(.systemBlue, for: .normal)
            phoneNumberContainerView.nextView.backgroundColor = .secondarySystemGroupedBackground
        } else {
            phoneNumberContainerView.nextView.setTitleColor(.white, for: .normal)
            phoneNumberContainerView.nextView.backgroundColor = .systemBlue
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 25
    }
}
