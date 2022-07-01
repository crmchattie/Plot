//
//  CustomSegmentedControl.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol CustomSegmentedControlDelegate: AnyObject {
    func changeToIndex(index:Int)
}

class CustomSegmentedControl: UIView {
    private var buttonImages:[String]!
    private var buttonTitles:[String]!
    private var selectedStrings:[String]!
    private var buttons: [UIButton]!
    
    var buttonColor: UIColor = ThemeManager.currentTheme().generalSubtitleColor
    var selectedButtonColor: UIColor = .systemBlue
        
    weak var delegate: CustomSegmentedControlDelegate?
    
    var selectedIndex = Int()
    
    convenience init(buttonImages:[String]?, buttonTitles:[String]?, selectedIndex: Int, selectedStrings:[String]?) {
        self.init()
        self.buttonImages = buttonImages
        self.buttonTitles = buttonTitles
        self.selectedIndex = selectedIndex
        self.selectedStrings = selectedStrings
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
        if buttonImages != nil {
            buttons[index].tintColor = selectedButtonColor
            buttons[selectedIndex].tintColor = buttonColor
        } else {
            buttons[index].setTitleColor(selectedButtonColor, for: .normal)
            buttons[selectedIndex].setTitleColor(buttonColor, for: .normal)
        
            if let selectedStrings = selectedStrings {
                buttons[index].setTitle(selectedStrings[index], for: .normal)
                buttons[selectedIndex].setTitle(buttonTitles[selectedIndex], for: .normal)
            }
        }
        selectedIndex = index
    }
    
    @objc func buttonAction(sender:UIButton) {
        if sender.tag == selectedIndex {
            return
        }
        if buttonImages != nil {
            buttons[sender.tag].tintColor = selectedButtonColor
            buttons[selectedIndex].tintColor = buttonColor
        } else {
            buttons[sender.tag].setTitleColor(selectedButtonColor, for: .normal)
            buttons[selectedIndex].setTitleColor(buttonColor, for: .normal)
        
            if let selectedStrings = selectedStrings {
                buttons[sender.tag].setTitle(selectedStrings[sender.tag], for: .normal)
                buttons[selectedIndex].setTitle(buttonTitles[selectedIndex], for: .normal)
            }
        }
        selectedIndex = sender.tag
        delegate?.changeToIndex(index: selectedIndex)
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
            for index in 0...buttonImages.count - 1 {
                let button = UIButton(type: .system)
                button.tag = index
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setImage(UIImage(named: buttonImages[index]), for: .normal)
                button.tintColor = buttonColor
                buttons.append(button)
            }
            buttons[selectedIndex].tintColor = selectedButtonColor
        } else {
            for index in 0...buttonTitles.count - 1 {
                let button = UIButton(type: .custom)
                button.tag = index
                button.addTarget(self, action:#selector(CustomSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setTitle(buttonTitles[index], for: .normal)
                button.titleLabel?.font = .boldSystemFont(ofSize: 20)
                button.setTitleColor(buttonColor, for: .normal)
                buttons.append(button)
            }
            buttons[selectedIndex].setTitleColor(selectedButtonColor, for: .normal)
        }
        
        if let selectedStrings = selectedStrings {
            buttons[selectedIndex].setTitle(selectedStrings[selectedIndex], for: .normal)
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
    
    var unselectedTintColor: UIColor = .systemBlue
    var unselectedBackgroundColor: UIColor = ThemeManager.currentTheme().generalBackgroundColor
    var selectedTintColor: UIColor = UIColor.white
    var selectedBackgroundColor: UIColor = .systemBlue
        
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
        buttons.forEach({
            $0.tintColor = unselectedTintColor
            $0.backgroundColor = unselectedBackgroundColor
        })
        selectedIndex = indexes
        indexes.forEach { (index) in
            buttons[index].tintColor = selectedTintColor
            buttons[index].backgroundColor = selectedBackgroundColor
        }
    }
    
    @objc func buttonAction(sender:UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            if btn == sender {
                if !selectedIndex.contains(buttonIndex) {
                    btn.tintColor = selectedTintColor
                    btn.backgroundColor = selectedBackgroundColor
                    self.selectedIndex.append(buttonIndex)
                } else {
                    btn.tintColor = unselectedTintColor
                    btn.backgroundColor = unselectedBackgroundColor
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
    
    private func createButton() {
        buttons = [UIButton]()
        buttons.removeAll()
        subviews.forEach({$0.removeFromSuperview()})
        if buttonImages != nil {
            for buttonImage in buttonImages {
                let button = RoundedButton(type: .system)
                button.addTarget(self, action:#selector(CustomMultiSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setImage(UIImage(named: buttonImage), for: .normal)
                button.tintColor = unselectedTintColor
                button.backgroundColor = unselectedBackgroundColor
                buttons.append(button)
            }
        } else {
            for buttonTitle in buttonTitles {
                let button = RoundedButton(type: .system)
                button.addTarget(self, action:#selector(CustomMultiSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
                button.setTitle(buttonTitle, for: .normal)
                button.titleLabel?.font = .boldSystemFont(ofSize: 20)
                button.tintColor = unselectedTintColor
                button.backgroundColor = unselectedBackgroundColor
                buttons.append(button)
            }
        }
        selectedIndex.forEach { (index) in
            buttons[index].tintColor = selectedTintColor
            buttons[index].backgroundColor = selectedBackgroundColor
        }
    }
        
    private func configStackView() {
        for button in buttons {
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1.0/1.0).isActive = true
        }
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
}

class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = min(self.frame.width, self.frame.height) / 2
    }
}
