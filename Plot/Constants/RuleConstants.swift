//
//  RuleConstants.swift
//  Plot
//
//  Created by Botond Magyarosi on 09/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

extension String  {

    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
