//
//  ThemeManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit

let SelectedThemeKey = "SelectedTheme"

extension NSNotification.Name {
    static let themeUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".themeUpdated")
}

struct ThemeManager {
    
    static func applyTheme(theme: Theme) {
        userDefaults.updateObject(for: userDefaults.selectedTheme, with: theme.rawValue)
        
        UITabBar.appearance().barStyle = theme.barStyle
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barStyle = theme.barStyle
        UINavigationBar.appearance().barTintColor = .secondarySystemBackground
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().largeTitleTextAttributes = textAttributes
        UINavigationBar.appearance().shadowImage = UIImage()
//        UINavigationBar.appearance().backgroundColor = theme.barBackgroundColor
        #warning("I would remove this globally. Ideally cells have selection styles that are updated automatically.")
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]
        
        NotificationCenter.default.post(name: .themeUpdated, object: nil)
    }
    
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
    
    @available(iOS 12.0, *)
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .Default:
            return .light
        case .Dark:
            return .dark
        }
    }
    
    var generalBackgroundColor: UIColor {
        switch self {
        case .Default:
            return #colorLiteral(red: 0.9489266276, green: 0.9490858912, blue: 0.9747040868, alpha: 1)
        case .Dark:
            return .black
        }
    }
    
    var cellBackgroundColor: UIColor {
        switch self {
        case .Default:
            return .white
        case .Dark:
            return #colorLiteral(red: 0.161149174, green: 0.1603732407, blue: 0.1725786328, alpha: 1)
        }
    }
    
    var chatBackgroundColor: UIColor {
        switch self {
        case .Default:
            return .white
        case .Dark:
            return .black
        }
    }
    
    var barBackgroundColor: UIColor {
        switch self {
        case .Default:
            return #colorLiteral(red: 0.9489266276, green: 0.9490858912, blue: 0.9747040868, alpha: 1)
        case .Dark:
            return .black
        }
    }
    
    var segmentedControlBackgroundColor: UIColor {
        switch self {
        case .Default:
            return .white
        case .Dark:
            return .gray
        }
    }
    
    var generalTitleColor: UIColor {
        switch self {
        case .Default:
            return UIColor.black
        case .Dark:
            return UIColor.white
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .Default:
            return .systemBlue
        case .Dark:
            return .systemBlue
        }
    }
    
    var generalSubtitleColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red:0.67, green:0.67, blue:0.67, alpha:1.0)
        case .Dark:
            return UIColor(red:0.67, green:0.67, blue:0.67, alpha:1.0)
        }
    }
    
    var cellSelectionColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        case .Dark:
            return UIColor(red: 10.0/255.0, green: 10.0/255.0, blue: 10.0/255.0, alpha: 1.0)
        }
    }
    
    var inputTextViewColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)
        case .Dark:
            return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        }
    }
    
    var controlButtonsColor: UIColor {
        switch self {
        case .Default:
            return   UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.0)
        case .Dark:
            return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        }
    }
    
    var searchBarColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
        case .Dark:
            return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 0.8)
        }
    }
    
    var mediaPickerControllerBackgroundColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 209.0/255.0, green: 213.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        case .Dark:
            return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
        }
    }
    
    var splashImage: UIImage {
        switch self {
        case .Default:
            return UIImage(named: "whiteSplash")!
        case .Dark:
            return UIImage(named: "blackSplash")!
        }
    }
    
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
            return UIImage(named: "DarkPigeonBubbleIncomingFull")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 22, bottom: 17, right: 20))//UIImage(named: "PigeonBubbleIncomingFull")!.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 22, 17, 20))
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
    
    var keyboardAppearance: UIKeyboardAppearance {
        switch self {
        case .Default:
            return  .default
        case .Dark:
            return .dark
        }
    }
    
    var barStyle: UIBarStyle {
        switch self {
        case .Default:
            return .default
        case .Dark:
            return .black
        }
    }
    
    var statusBarStyle: UIStatusBarStyle {
        switch self {
        case .Default:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        case .Dark:
            return .lightContent
        }
    }
    
    var scrollBarStyle: UIScrollView.IndicatorStyle {
        switch self {
        case .Default:
            return .default
        case .Dark:
            return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        case .Dark:
            return UIColor.black
        }
    }
    
    var secondaryColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 242.0/255.0, green: 101.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        case .Dark:
            return UIColor(red: 34.0/255.0, green: 128.0/255.0, blue: 66.0/255.0, alpha: 1.0)
            
        }
    }
    
    var controlButtonColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
        case .Dark:
            return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
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
            UIColor(red: 246/255.0, green: 81/255.0, blue: 29/255.0, alpha: 1.0),
            UIColor(red: 255/255.0, green: 180/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 127/255.0, green: 184/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 123/255.0, green: 104/255.0, blue: 142/255.0, alpha: 1.0),
            
            UIColor(red: 13/255.0, green: 44/255.0, blue: 84/255.0, alpha: 1.0),
            UIColor(red: 251/255.0, green: 131/255.0, blue: 31/255.0, alpha: 1.0),
            UIColor(red: 191/255.0, green: 192/255.0, blue: 0/255.0, alpha: 1.0),
            UIColor(red: 70/255.0, green: 114/255.0, blue: 42/255.0, alpha: 1.0),
            UIColor(red: 35/255.0, green: 63/255.0, blue: 190/255.0, alpha: 1.0),
            
            UIColor(red: 187/255.0, green: 118/255.0, blue: 79/255.0, alpha: 1.0),
            UIColor(red: 221/255.0, green: 157/255.0, blue: 8/255.0, alpha: 1.0),
            UIColor(red: 131/255.0, green: 148/255.0, blue: 21/255.0, alpha: 1.0),
            UIColor(red: 53/255.0, green: 89/255.0, blue: 71/255.0, alpha: 1.0),
            UIColor(red: 55/255.0, green: 80/255.0, blue: 114/255.0, alpha: 1.0)
        ]
    }
}
