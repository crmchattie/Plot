//
//  ThemeManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit

struct ThemeManager {
    static func currentTheme() -> Theme {
        if let storedTheme = userDefaults.currentIntObjectState(for: userDefaults.selectedTheme) {
            return Theme(rawValue: storedTheme)!
        } else {
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark ? .Dark : .Default
            } else {
                return .Default
            }
        }
    }
}

enum Theme: Int {
    case Default, Dark
    
    var typingIndicatorURL: URL? {
        switch self {
        case .Default:
            return Bundle.main.url(forResource: "typingIndicator", withExtension: "gif")
        case .Dark:
            return Bundle.main.url(forResource: "typingindicatorDark", withExtension: "gif")
        }
    }
    
    var enterPhoneNumberBackground: UIImage {
        switch self {
        case .Default:
            return  UIImage(named: "LightAuthCountryButtonNormal")!
        case .Dark:
            return UIImage(named: "DarkAuthCountryButtonNormal")!
        }
    }
    
    var enterPhoneNumberBackgroundSelected: UIImage {
        switch self {
        case .Default:
            return UIImage(named:"LightAuthCountryButtonHighlighted")!
        case .Dark:
            return UIImage(named:"DarkAuthCountryButtonHighlighted")!
        }
    }
    
    var personalStorageImage: UIImage {
        switch self {
        case .Default:
            return  UIImage(named: "PersonalStorage")!
        case .Dark:
            return UIImage(named: "PersonalStorage")!
        }
    }
    
    var incomingBubble: UIImage {
        switch self {
        case .Default:
            return UIImage(named: "DarkPigeonBubbleIncomingFull")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 22, bottom: 17, right: 20))
        case .Dark:
            return UIImage(named: "DarkPigeonBubbleIncomingFull")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 22, bottom: 17, right: 20))
        }
    }
    
    var outgoingBubble: UIImage {
        switch self {
        case .Default:
            return UIImage(named: "PigeonBubbleOutgoingFull")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 14, bottom: 17, right: 28))
        case .Dark: //DarkPigeonBubbleOutgoingFull
            return UIImage(named: "PigeonBubbleOutgoingFull")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 14, bottom: 17, right: 28))
        }
    }
}

struct FalconPalette {
    static let defaultBlack = UIColor.black
    static let defaultBlue = UIColor(red:0.00, green:0.50, blue:1.00, alpha: 1.0)
    static let dismissRed = UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0)
    static let appStoreGrey = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.0)
    static let defaultGreen = UIColor(red: 127.0/255.0, green: 184.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    static let defaultRed = UIColor(red: 246.0/255.0, green: 81.0/255.0, blue: 29.0/255.0, alpha: 1.0)
    static let defaultOrange = UIColor(red: 255.0/255.0, green: 180.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    static let defaultDarkBlue = UIColor(red: 123/255.0, green: 104/255.0, blue: 142/255.0, alpha: 1.0)
    static let ticketmaster = UIColor(red: 2.0/255.0, green: 108.0/255.0, blue: 223.0/255.0, alpha: 1.0)
}

open class ChartColors: NSObject
{
    @objc open class func palette() -> [UIColor]
    {
        return [
            UIColor(red: 0/255.0, green: 127/255.0, blue: 255/255.0, alpha: 1.0),
            UIColor(red: 123/255.0, green: 104/255.0, blue: 142/255.0, alpha: 1.0),
            UIColor(red: 246/255.0, green: 81/255.0, blue: 29/255.0, alpha: 1.0),
            UIColor(red: 251/255.0, green: 131/255.0, blue: 31/255.0, alpha: 1.0),
            UIColor(red: 255/255.0, green: 180/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 191/255.0, green: 192/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 127/255.0, green: 184/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 70/255.0, green: 114/255.0, blue: 42/255.0, alpha: 1.0),
            UIColor(red: 13/255.0, green: 44/255.0, blue: 84/255.0, alpha: 1.0),
            UIColor(red: 35/255.0, green: 63/255.0, blue: 190/255.0, alpha: 1.0),
        ]
    }
}
