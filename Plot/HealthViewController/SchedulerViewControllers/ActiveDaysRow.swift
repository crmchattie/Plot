//
//  ActiveDaysRow.swift
//  Plot
//
//  Created by Cory McHattie on 12/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Eureka

final class ActiveDaysCell: Cell<[Int]>, CellType {
    lazy var customSegmentControl = CustomMultiSegmentedControl(buttonImages: nil, buttonTitles: ["M", "T", "W", "T", "F", "S", "S"], selectedIndex: nil)
    
    override func setup() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        selectionStyle = .none
        backgroundColor = .clear
        
        let stackView = UIStackView(arrangedSubviews: [customSegmentControl])
        stackView.alignment = .center
        
        contentView.addSubview(stackView)
        stackView.fillSuperview()
                        
    }
    
    override func update() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        guard let selectedIndex = row.value else { return }
        customSegmentControl.setIndex(indexes: selectedIndex)
        
    }
}

protocol ActiveDaysDelegate {
    func updateIndexes(index: Int, indexes: [Int])
}

final class ActiveDaysRow: Row<ActiveDaysCell>, RowType, CustomMultiSegmentedControlDelegate {
    var delegate: ActiveDaysDelegate?
    
    required init(tag: String?) {
        super.init(tag: tag)
        cell.customSegmentControl.delegate = self
    }
    
    func changeToIndex(indexes: [Int]) {
        delegate?.updateIndexes(index: Int(tag ?? "0") ?? 0, indexes: indexes)
    }
    
}
