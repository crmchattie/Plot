//
//  HostedViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class HostedViewCell: BaseContainerCell {
        
    // MARK: - HostedView
    
    private weak var _hostedView: UIView? {
        didSet {
            if let oldValue = oldValue {
                if oldValue.isDescendant(of: self) { //Make sure that hostedView hasn't been added as a subview to a different cell
                    oldValue.removeFromSuperview()
                }
            }
            
            if let _hostedView = _hostedView {
                layer.cornerRadius = 16
                
                let stackView = VerticalStackView(arrangedSubviews: [
                    _hostedView
                    ], spacing: 0)
                
                addSubview(stackView)
                stackView.fillSuperview(padding: .init(top: 10, left: 5, bottom: 5, right: 10))
                
//                _hostedView.frame = contentView.bounds
//                contentView.addSubview(_hostedView)
            }
        }
    }
    
    weak var hostedView: UIView? {
        get {
            guard _hostedView?.isDescendant(of: self) ?? false else {
                _hostedView = nil
                return nil
            }
            
            return _hostedView
        }
        set {
            _hostedView = newValue
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        hostedView = nil
    }
}
