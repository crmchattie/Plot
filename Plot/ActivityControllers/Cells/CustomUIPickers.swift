//
//  CustomUIPickers.swift
//  Plot
//
//  Created by Cory McHattie on 4/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.


//  Never finished

import UIKit

class MealPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let UIPicker: UIPickerView = UIPickerView()
    
    enum Component: Int {
        case day = 0
        case time = 1
    }
    
    var dayArray: [String] {
        get {
            var days = [String]()

//            for i in minYear...maxYear {
//                years.append("\(i)")
//            }

            return days
        }
    }
    
    var timeArray: [String] {
        get {
            var times = ["Now", "Breakfast", "Lunch", "Dinner"]

            for i in 1...12 {
                times.append("\(i)")
            }

            return times
        }
    }
    
    var minuteArray: [String] {
        get {
            var minutes = [String]()

            for i in 00...60 {
                minutes.append("\(i)")
            }
            for i in stride(from: 0, to: 60, by: 5) {
                if i < 10 {
                    minutes.append("0\(i)")
                } else {
                    minutes.append("\(i)")
                }
            }

            return minutes
        }
    }
    
    var ampmArray = ["AM", "PM"]
    
    let numberOfComponentsRequired = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadDefaultParameters()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadDefaultParameters()
    }

    func loadDefaultParameters() {
        UIPicker.delegate = self as UIPickerViewDelegate
        UIPicker.dataSource = self as UIPickerViewDataSource
//        self.view.addSubview(UIPicker)
//        UIPicker.center = self.view.center
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numberOfComponentsRequired
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dayArray.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let row = dayArray[row]
        return row
    }
}

class WorkoutPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    let UIPicker: UIPickerView = UIPickerView()
        
    enum Component: Int {
        case day = 0
        case time = 1
    }
    
    var dayArray: [String] {
        get {
            var days = [String]()

//            for i in minYear...maxYear {
//                years.append("\(i)")
//            }

            return days
        }
    }
    
    var timeArray: [String] {
        get {
            var times = ["Now", "Breakfast", "Lunch", "Dinner"]

            for i in 1...12 {
                times.append("\(i)")
            }

            return times
        }
    }
    
    var minuteArray: [String] {
        get {
            var minutes = [String]()

            for i in 00...60 {
                minutes.append("\(i)")
            }
            for i in stride(from: 0, to: 60, by: 5) {
                if i < 10 {
                    minutes.append("0\(i)")
                } else {
                    minutes.append("\(i)")
                }
            }

            return minutes
        }
    }
    
    var ampmArray = ["AM", "PM"]
    
    let numberOfComponentsRequired = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadDefaultParameters()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadDefaultParameters()
    }

    func loadDefaultParameters() {
        UIPicker.delegate = self as UIPickerViewDelegate
        UIPicker.dataSource = self as UIPickerViewDataSource
//        self.view.addSubview(UIPicker)
//        UIPicker.center = self.view.center
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numberOfComponentsRequired
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dayArray.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let row = dayArray[row]
        return row
    }
    
}
