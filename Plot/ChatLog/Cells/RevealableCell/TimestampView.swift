//
//  TimestampView.swift
//  RevealableCell
//
//  Created by Shaps Mohsenin on 03/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class TimestampView: RevealableView {

  @IBOutlet var titleLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)

    titleLabel.textColor = .secondaryLabel
    titleLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
