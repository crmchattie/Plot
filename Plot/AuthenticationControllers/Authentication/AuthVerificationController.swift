//
//  AuthVerificationController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

//see Support/PhoneAuth/EnterVerificationControllers for more detail
class AuthVerificationController: EnterVerificationCodeController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    setRightBarButton(with: "Next")
  }
  
  override func rightBarButtonDidTap() {
    super.rightBarButtonDidTap()
    authenticate()
  }
    
}
