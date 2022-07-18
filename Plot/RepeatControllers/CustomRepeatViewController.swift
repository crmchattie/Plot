//
//  CustomRepeatViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/18/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

let frequency = ["Daily","Weekly","Monthly","Yearly",]

protocol UpdateCustomRepeatDelegate: AnyObject {
    func updateCustomRepeat(repeat: EventRepeat)
}

class CustomRepeatViewController: FormViewController {
    weak var delegate : UpdateCustomRepeatDelegate?
    
    var repeatValue: EventRepeat = .Never
    
    var movingBackwards = true
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Custom"
        
        configureTableView()
        initializeForm()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateCustomRepeat(repeat: repeatValue)
        }
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem = plusBarButton
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        self.delegate?.updateCustomRepeat(repeat: repeatValue)
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func initializeForm() {
        form +++ Section("Generic picker")
            <<< PickerInlineRow<String>() {
                $0.title = "Frequency"
                $0.options = frequency
            }
            <<< DoublePickerInlineRow<Int, String>() {
                $0.title = "Every"
                $0.firstOptions = { return [1, 2, 3]}
                $0.secondOptions = { _ in return ["a", "b", "c"]}
            }
    }
}
