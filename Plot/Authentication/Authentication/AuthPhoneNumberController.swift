//
//  AuthPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

//see Support/PhoneAuth/EnterPhoneControllers for more detail
class AuthPhoneNumberController: EnterPhoneNumberController {
    override func configurePhoneNumberContainerView() {
        super.configurePhoneNumberContainerView()
        phoneNumberContainerView.instructions.text = "Please confirm your country code\nand enter your phone number."
        phoneNumberContainerView.phoneNumber.placeholder = "Phone Number"
    }
    
    override func rightBarButtonDidTap() {
        super.rightBarButtonDidTap()
        
        let destination = AuthVerificationController(networkController: networkController)
        destination.enterVerificationContainerView.titleNumber.text = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
