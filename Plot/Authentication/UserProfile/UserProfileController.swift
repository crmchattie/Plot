//
//  UserProfileController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit

class UserProfileController: UIViewController {
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let networkController: NetworkController
    
    let userProfileContainerView = UserProfileContainerView()
    let avatarOpener = AvatarOpener()
    let userProfileDataDatabaseUpdater = UserProfileDataDatabaseUpdater()
    var newUser = true
    let phoneNumberKit = PhoneNumberKit()
    var surveyAnswers = [String: Bool]()
    
    // typealias allows you to rename a data type
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        
        configureNavigationBar()
        configureContainerView()
        configureColorsAccordingToTheme()
    }
    
    fileprivate func configureNavigationBar () {
        self.title = "Profile"
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    fileprivate func configureContainerView() {
        view.addSubview(userProfileContainerView)
        userProfileContainerView.frame = view.bounds
        userProfileContainerView.hideNextView = false
        userProfileContainerView.addPhotoLabel.isHidden = (userProfileContainerView.profileImageView.image == nil)
        userProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
        userProfileContainerView.email.addTarget(self, action: #selector(changeEmail), for: .editingDidBegin)
        userProfileContainerView.age.addTarget(self, action: #selector(changeAge), for: .editingDidBegin)
        userProfileContainerView.nextView.addTarget(self, action: #selector(rightBarButtonDidTap), for: .touchUpInside)
        userProfileContainerView.bio.delegate = self
        userProfileContainerView.name.delegate = self
        userProfileContainerView.email.delegate = self
        userProfileContainerView.age.delegate = self
        userProfileContainerView.phone.isUserInteractionEnabled = false
    }
    
    fileprivate func configureColorsAccordingToTheme() {
        userProfileContainerView.name.textColor = .label
        userProfileContainerView.age.textColor = .label
        userProfileContainerView.bio.textColor = .label
        userProfileContainerView.bio.keyboardAppearance = .default
        userProfileContainerView.name.keyboardAppearance = .default
        userProfileContainerView.age.textColor = .label
        userProfileContainerView.addPhotoLabel.isHidden = (userProfileContainerView.profileImageView.image != nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        userProfileContainerView.frame = view.bounds
        userProfileContainerView.layoutIfNeeded()
    }
    
    @objc fileprivate func openUserProfilePicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: userProfileContainerView.profileImageView, at: self,
                                         isEditButtonEnabled: true, title: .user)
    }
    
    @objc func changeEmail() {
        let controller = ChangeEmailController()
        let destination = UINavigationController(rootViewController: controller)
        destination.navigationBar.shadowImage = UIImage()
        destination.navigationBar.setBackgroundImage(UIImage(), for: .default)
        destination.hidesBottomBarWhenPushed = true
        destination.navigationBar.isTranslucent = false
        present(destination, animated: true, completion: nil)
    }
    
    @objc func changeAge() {
        let controller = ChangeBirthdayController()
        controller.delegate = self
        let destination = UINavigationController(rootViewController: controller)
        destination.navigationBar.shadowImage = UIImage()
        destination.navigationBar.setBackgroundImage(UIImage(), for: .default)
        destination.hidesBottomBarWhenPushed = true
        destination.navigationBar.isTranslucent = false
        present(destination, animated: true, completion: nil)
    }
}

extension UserProfileController {
    
    @objc func rightBarButtonDidTap () {
        userProfileContainerView.name.resignFirstResponder()
        userProfileContainerView.age.resignFirstResponder()
        if userProfileContainerView.name.text?.count == 0 ||
            userProfileContainerView.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            userProfileContainerView.name.shake()
        } else if userProfileContainerView.phone.text?.count == 0 ||
                    userProfileContainerView.phone.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            userProfileContainerView.phone.shake()
        } else {
            if currentReachabilityStatus == .notReachable {
                basicErrorAlertWithClose(title: "No internet connection", message: noInternetError, controller: self)
                return
            }
            updateUserData()
            setOnlineStatus()
        }
    }
    
    func checkIfUserDataExists(completionHandler: @escaping CompletionHandler) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let nameReference = Database.database().reference().child("users").child(currentUserID).child("name")
            nameReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    self.userProfileContainerView.name.text = snapshot.value as? String
                    self.newUser = false
                    NotificationCenter.default.post(name: .oldUserLoggedIn, object: nil)
                }
            })
            
            let bioReference = Database.database().reference().child("users").child(currentUserID).child("bio")
            bioReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    self.userProfileContainerView.bio.text = snapshot.value as? String
                }
            })
            
            let emailReference = Database.database().reference().child("users").child(currentUserID).child("email")
            emailReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    self.userProfileContainerView.email.text = snapshot.value as? String
                }
            })
            
            let ageReference = Database.database().reference().child("users").child(currentUserID).child("age")
            ageReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    if let age = snapshot.value as? Double {
                        let ageComponents = Calendar.current.dateComponents([.year], from: Date(timeIntervalSince1970: age), to: Date())
                        let birthdayString = "\(ageComponents.year ?? 0) years old"
                        self.userProfileContainerView.age.text = birthdayString
                    }
                }
            })
            
            let photoReference = Database.database().reference().child("users").child(currentUserID).child("photoURL")
            photoReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    guard let urlString = snapshot.value as? String else {
                        completionHandler(true)
                        return
                    }
                    self.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: urlString), placeholderImage: nil, options: [.scaleDownLargeImages , .continueInBackground], completed: { (_, _, _, _) in
                        self.userProfileContainerView.addPhotoLabel.isHidden = true
                        completionHandler(true)
                    })
                } else {
                    self.userProfileContainerView.addPhotoLabel.isHidden = false
                    completionHandler(true)
                }
            })
            
            let surveyReference = Database.database().reference().child("users").child(currentUserID).child("survey")
            surveyReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    if let surveyAnswers = snapshot.value as? [String: Bool] {
                        self.surveyAnswers = surveyAnswers
                    }
                }
            })
        }
    }
    
    func updateUserData() {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let userReference = Database.database().reference().child("users").child(currentUserID)
            
            var phoneNumberForFB = String()
            
            do {
                let phoneNumber = try self.phoneNumberKit.parse(userProfileContainerView.phone.text!)
                phoneNumberForFB = self.phoneNumberKit.format(phoneNumber, toType: .e164)
            } catch {
                phoneNumberForFB = userProfileContainerView.phone.text!
            }
            
            userReference.updateChildValues(["name": userProfileContainerView.name.text!,
                                             "phoneNumber": phoneNumberForFB,
                                             "bio": userProfileContainerView.bio.text!]) { (_, _) in
                Analytics.logEvent(AnalyticsEventSignUp, parameters: [
                    AnalyticsParameterMethod: self.method
                ])
                let destination = FirstSurveyController(survey: Survey.hearAboutPlot, networkController: self.networkController)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
}

extension UserProfileController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        userProfileContainerView.bioPlaceholderLabel.isHidden = true
        userProfileContainerView.countLabel.text = "\(userProfileContainerView.bioMaxCharactersCount - userProfileContainerView.bio.text.count)"
        userProfileContainerView.countLabel.isHidden = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        userProfileContainerView.bioPlaceholderLabel.isHidden = !textView.text.isEmpty
        userProfileContainerView.countLabel.isHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.isFirstResponder && textView.text == "" {
            userProfileContainerView.bioPlaceholderLabel.isHidden = true
        } else {
            userProfileContainerView.bioPlaceholderLabel.isHidden = !textView.text.isEmpty
        }
        userProfileContainerView.countLabel.text = "\(userProfileContainerView.bioMaxCharactersCount - textView.text.count)"
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.count + (text.count - range.length) <= userProfileContainerView.bioMaxCharactersCount
    }
}

extension UserProfileController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UserProfileController: ChangeBirthdayDelegate {
    func update(birthday: Date) {
        let ageComponents = Calendar.current.dateComponents([.year], from: birthday, to: Date())
        let birthdayString = "\(ageComponents.year ?? 0) years old"
        self.userProfileContainerView.age.text = birthdayString
    }
}
