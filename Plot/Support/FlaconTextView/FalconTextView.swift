//
//  FalconTextView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/11/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class FalconTextView: UITextView {

	convenience init() {
		self.init(frame: .zero)
		backgroundColor = .clear
		isEditable = false
		isScrollEnabled = false
		dataDetectorTypes = .all
	}

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard let pos = closestPosition(to: point) else { return false }
		guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: UITextDirection(rawValue: UITextLayoutDirection.left.rawValue)) else { return false }
    let startIndex = offset(from: beginningOfDocument, to: range.start)
    
		return attributedText.attribute(NSAttributedString.Key.link, at: startIndex, effectiveRange: nil) != nil
  }
}
