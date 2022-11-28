//
//  ColorRow.swift
//  Plot
//
//  Created by Cory McHattie on 8/30/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import UIKit
import Eureka

final class ColorPushSelectorCell<T: Equatable> : Cell<T>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let colorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func setup() {
        super.setup()
        accessoryType = .disclosureIndicator
        editingAccessoryType = accessoryType
        selectionStyle = row.isDisabled ? .none : .default

        contentView.addSubview(colorButton)
        colorButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
        colorButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true
        colorButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        colorButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
    }
    
    override func update() {
        super.update()
        guard let color = row.value as? UIColor else { return }
        colorButton.tintColor = color
    }
}

open class _ColorPushRow<Cell: CellType>: SelectorRow<Cell> where Cell: BaseCell {
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return SelectorViewController<SelectorRow<Cell>> { _ in } }, onDismiss: { vc in
            let _ = vc.navigationController?.popViewController(animated: true) })
    }
}

/// A selector row where the user can pick an option from a pushed view controller
final class ColorPushRow<T: Equatable> : _ColorPushRow<ColorPushSelectorCell<T>>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
