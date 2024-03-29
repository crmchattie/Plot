//
//  AccountSettingsController+nameEditing.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension AccountSettingsController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateBarButtonPressed()
        textField.resignFirstResponder()
        return true
    }
}

extension AccountSettingsController: UITextViewDelegate {
    
    func estimateFrameForText(_ text: String, width: CGFloat) -> CGRect {
        let size = CGSize(width: width, height: 10000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)], context: nil).integral
    }
    
    func tableHeaderHeight() -> CGFloat {
        return 240 + estimateFrameForText(userProfileContainerView.bio.text, width: userProfileContainerView.bio.textContainer.size.width - 10).height
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        setEditingBarButtons()
        userProfileContainerView.bioPlaceholderLabel.isHidden = true
        userProfileContainerView.countLabel.text = "\(userProfileContainerView.bioMaxCharactersCount - userProfileContainerView.bio.text.count)"
        userProfileContainerView.countLabel.isHidden = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        userProfileContainerView.bioPlaceholderLabel.isHidden = !textView.text.isEmpty
        userProfileContainerView.countLabel.isHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        view.setNeedsLayout()
        if textView.isFirstResponder && textView.text == "" {
            userProfileContainerView.bioPlaceholderLabel.isHidden = true
        } else {
            userProfileContainerView.bioPlaceholderLabel.isHidden = !textView.text.isEmpty
        }
        userProfileContainerView.countLabel.text = "\(userProfileContainerView.bioMaxCharactersCount - textView.text.count)"
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.resignFirstResponder()
            updateBarButtonPressed()
            return false
        }
        
        return textView.text.count + (text.count - range.length) <= userProfileContainerView.bioMaxCharactersCount
    }
}

extension AccountSettingsController { /* user name editing */
    
    @objc func nameDidBeginEditing() {
        setEditingBarButtons()
    }
    
    @objc func nameEditingChanged() {
        if userProfileContainerView.name.text!.count == 0 ||
            userProfileContainerView.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            updateBarButton.isEnabled = false
        } else {
            updateBarButton.isEnabled = true
        }
    }
    
    @objc func ageDidBeginEditing() {
        setEditingBarButtons()
    }
    
    @objc func ageEditingChanged() {
        if userProfileContainerView.age.text!.count == 0 ||
            userProfileContainerView.age.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            updateBarButton.isEnabled = false
        } else {
            updateBarButton.isEnabled = true
        }
    }
    
    func setEditingBarButtons() {
        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = updateBarButton
    }
    
    @objc func cancelBarButtonPressed() {
        userProfileContainerView.name.text = currentName
        userProfileContainerView.bio.text = currentBio
        userProfileContainerView.age.text = currentAge
        userProfileContainerView.name.endEditing(true)
        userProfileContainerView.age.endEditing(true)
        userProfileContainerView.bio.endEditing(true)
        userProfileContainerView.name.resignFirstResponder()
        userProfileContainerView.age.resignFirstResponder()
        userProfileContainerView.bio.resignFirstResponder()
        userProfileContainerView.phone.resignFirstResponder()
        userProfileContainerView.email.resignFirstResponder()
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = doneBarButton
        view.setNeedsLayout()
    }
    
    @objc func updateBarButtonPressed() {
        if currentReachabilityStatus == .notReachable {
            basicErrorAlertWithClose(title: "No internet", message: noInternetError, controller: self)
            return
        }
        
        self.view.isUserInteractionEnabled = false
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = doneBarButton
        userProfileContainerView.name.resignFirstResponder()
        userProfileContainerView.age.resignFirstResponder()
        userProfileContainerView.bio.resignFirstResponder()
        
        let userNameReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        userNameReference.updateChildValues(["name": userProfileContainerView.name.text!,
                                             "bio": userProfileContainerView.bio.text!]) { (error, reference) in
                                                if error != nil {
                                                    self.view.isUserInteractionEnabled = true
                                                }
                                                self.view.isUserInteractionEnabled = true
        }
    }
}
