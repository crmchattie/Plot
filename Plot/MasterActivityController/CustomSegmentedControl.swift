//
//  CustomSegmentedControl.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol CustomSegmentedControlDelegate:class {
    func changeToIndex(index:Int)
}

class CustomSegmentedControl: UIView {
    private var buttonImages:[String]!
    private var buttonTitles:[String]!
    private var buttons: [UIButton]!
    
    var buttonColor: UIColor = ThemeManager.currentTheme().generalSubtitleColor
    var selectedButtonColor: UIColor = .systemBlue
        
    weak var delegate: CustomSegmentedControlDelegate?
    
    var selectedIndex: Int?
    
    convenience init(buttonImages:[String]?, buttonTitles:[String]?, selectedIndex: Int?) {
        self.init()
        self.buttonImages = buttonImages
        self.buttonTitles = buttonTitles
        self.selectedIndex = selectedIndex
        updateView()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = .clear
        updateView()
    }
    
    func setButtonTitles(buttonImages:[String]?, buttonTitles:[String]?) {
        self.buttonImages = buttonImages
        self.buttonTitles = buttonTitles
        self.updateView()
    }
    
    func setIndex(index:Int) {
        buttons.forEach({ $0.tintColor = buttonColor })
        selectedIndex = index
        buttons[index].tintColor = selectedButtonColor
    }
    
    @objc func buttonAction(sender:UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.tintColor = buttonColor
            if btn == sender {
                selectedIndex = buttonIndex
                btn.tintColor = selectedButtonColor
                if let selectedIndex = selectedIndex {
                    delegate?.changeToIndex(index: selectedIndex)
                }
            }
        }
    }
}

//Configuration View
extension CustomSegmentedControl {
    private func updateView() {
        createButton()
        configStackView()
    }
    
    private func configStackView() {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    private func createButton() {
        buttons = [UIButton]()
        buttons.removeAll()
        subviews.forEach({$0.removeFromSuperview()})
        if buttonImages != nil {
            for buttonImage in buttonImages {
                let button = UIButton(type: .system)
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setImage(UIImage(named: buttonImage), for: .normal)
                button.tintColor = buttonColor
                buttons.append(button)
            }
        } else {
            for buttonTitle in buttonTitles {
                let button = UIButton(type: .system)
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setTitle(buttonTitle, for: .normal)
                button.titleLabel?.font = .boldSystemFont(ofSize: 20)
                button.tintColor = buttonColor
                buttons.append(button)
            }
        }
        if let selectedIndex = selectedIndex {
            buttons[selectedIndex].tintColor = selectedButtonColor
        }
    }
}

protocol CustomMultiSegmentedControlDelegate:class {
    func changeToIndex(indexes:[Int])
}

class CustomMultiSegmentedControl: UIView {
    private var buttonImages:[String]!
    private var buttonTitles:[String]!
    private var buttons: [UIButton]!
    
    var buttonColor: UIColor = ThemeManager.currentTheme().generalSubtitleColor
    var selectedButtonColor: UIColor = .systemBlue
        
    weak var delegate: CustomMultiSegmentedControlDelegate?
    
    var selectedIndex = [Int]()
    
    convenience init(buttonImages:[String]?, buttonTitles:[String]?, selectedIndex: [Int]?) {
        self.init()
        self.buttonImages = buttonImages
        self.buttonTitles = buttonTitles
        self.selectedIndex = selectedIndex ?? []
        updateView()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = .clear
        updateView()
    }
    
    func setButtonTitles(buttonImages:[String]?, buttonTitles:[String]?) {
        self.buttonImages = buttonImages
        self.buttonTitles = buttonTitles
        self.updateView()
    }
    
    func setIndex(indexes:[Int]) {
        buttons.forEach({ $0.tintColor = buttonColor })
        selectedIndex = indexes
        indexes.forEach { (index) in
            buttons[index].tintColor = selectedButtonColor
        }
    }
    
    @objc func buttonAction(sender:UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            if btn == sender {
                if !selectedIndex.contains(buttonIndex) {
                    btn.tintColor = selectedButtonColor
                    self.selectedIndex.append(buttonIndex)
                } else {
                    btn.tintColor = buttonColor
                    if let index = self.selectedIndex.firstIndex(of: buttonIndex) {
                        self.selectedIndex.remove(at: index)
                    }
                }
            }
        }
        delegate?.changeToIndex(indexes: self.selectedIndex)
    }
}

//Configuration View
extension CustomMultiSegmentedControl {
    private func updateView() {
        createButton()
        configStackView()
    }
    
    private func configStackView() {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    private func createButton() {
        buttons = [UIButton]()
        buttons.removeAll()
        subviews.forEach({$0.removeFromSuperview()})
        if buttonImages != nil {
            for buttonImage in buttonImages {
                let button = UIButton(type: .system)
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setImage(UIImage(named: buttonImage), for: .normal)
                button.tintColor = buttonColor
                buttons.append(button)
            }
        } else {
            for buttonTitle in buttonTitles {
                let button = UIButton(type: .system)
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setTitle(buttonTitle, for: .normal)
                button.titleLabel?.font = .boldSystemFont(ofSize: 20)
                button.tintColor = buttonColor
                buttons.append(button)
            }
        }
        selectedIndex.forEach { (index) in
            buttons[index].tintColor = selectedButtonColor
        }
    }
}
