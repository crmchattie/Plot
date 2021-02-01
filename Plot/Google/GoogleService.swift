//
//  GoogleService.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GoogleService {
    func setupGoogle(completion: @escaping () -> Swift.Void) {
        GoogleSetupAssistant.setupGoogle {
            completion()
        }
    }
}
