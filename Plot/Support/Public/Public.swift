//
//  Public.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SystemConfiguration
import SDWebImage
import Photos

struct ScreenSize {
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let maxLength = max(ScreenSize.width, ScreenSize.height)
    static let minLength = min(ScreenSize.width, ScreenSize.height)
    static let frame = CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height)
}

struct DeviceType {
    static let iPhone4orLess = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength < 568.0
    static let iPhone5orSE = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 568.0
    static let iPhone678 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 667.0
    static let iPhone678p = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 736.0
    static let iPhoneX = UIDevice.current.userInterfaceIdiom == .phone && (ScreenSize.maxLength == 812.0 || ScreenSize.maxLength == 896.0)
    
    static let IS_IPAD = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1024.0
    static let IS_IPAD_PRO = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1366.0
}

extension UILocalizedIndexedCollation {
    
    func partitionObjects(array:[AnyObject], collationStringSelector:Selector) -> ([AnyObject], [String]) {
        var unsortedSections = [[AnyObject]]()
        
        //1. Create a array to hold the data for each section
        for _ in self.sectionTitles {
            unsortedSections.append([]) //appending an empty array
        }
        //2. Put each objects into a section
        for item in array {
            let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
            unsortedSections[index].append(item)
        }
        //3. sorting the array of each sections
        var sectionTitles = [String]()
        var sections = [AnyObject]()
        for index in 0 ..< unsortedSections.count { if unsortedSections[index].count > 0 {
            sectionTitles.append(self.sectionTitles[index])
            sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
            }
        }
        
        return (sections, sectionTitles)
    }
}

extension Array {
    public func stablePartition(by condition: (Element) throws -> Bool) rethrows -> ([Element], [Element]) {
        var indexes = Set<Int>()
        for (index, element) in self.enumerated() {
            if try condition(element) {
                indexes.insert(index)
            }
        }
        var matching = [Element]()
        matching.reserveCapacity(indexes.count)
        var nonMatching = [Element]()
        nonMatching.reserveCapacity(self.count - indexes.count)
        for (index, element) in self.enumerated() {
            if indexes.contains(index) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        return (matching, nonMatching)
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
}

func topViewController(rootViewController: UIViewController?) -> UIViewController? {
    guard let rootViewController = rootViewController else {
        return nil
    }
    
    guard let presented = rootViewController.presentedViewController else {
        return rootViewController
    }
    
    switch presented {
    case let navigationController as UINavigationController:
        return topViewController(rootViewController: navigationController.viewControllers.last)
        
    case let tabBarController as UITabBarController:
        return topViewController(rootViewController: tabBarController.selectedViewController)
        
    default:
        return topViewController(rootViewController: presented)
    }
}

struct NameConstants {
    static let personalStorage = "Personal storage"
}

public let messageStatusRead = "Read"
public let messageStatusSending = "Sending"
public let messageStatusDelivered = "Delivered"

let cameraAccessDeniedMessage = "Plot needs access to your camera to take photos and videos.\n\nPlease go to Settings –– Privacy –– Camera –– and set Plot to ON."
let contactsAccessDeniedMessage = "Plot needs access to your contacts to create new ones.\n\nPlease go to Settings –– Privacy –– Contacts –– and set Plot to ON."
let microphoneAccessDeniedMessage = "Plot needs access to your microphone to record audio messages.\n\nPlease go to Settings –– Privacy –– Microphone –– and set Plot to ON."
let photoLibraryAccessDeniedMessage = "Plot needs access to your photo library to send photos and videos.\n\nPlease go to Settings –– Privacy –– Photos –– and set Plot to ON."

let cameraAccessDeniedMessageProfilePicture = "Plot needs access to your camera to take photo for your profile.\n\nPlease go to Settings –– Privacy –– Camera –– and set Plot to ON."
let photoLibraryAccessDeniedMessageProfilePicture = "Plot needs access to your photo library to select photo for your profile.\n\nPlease go to Settings –– Privacy –– Photos –– and set Plot to ON."

let videoRecordedButLibraryUnavailableError = "To send a recorded video, it has to be saved to your photo library first. Please go to Settings –– Privacy –– Photos –– and set Plot to ON."

let basicErrorTitleForAlert = "Error"
let basicTitleForAccessError = "Please Allow Access"
let noInternetError = "Internet is not available. Please try again later"
let copyingImageError = "You cannot copy not downloaded image, please wait until downloading finished"

let deletionErrorMessage = "There was a problem when deleting. Try again later."
let cameraNotExistsMessage = "You don't have camera"
let thumbnailUploadError = "Failed to upload your image to database. Please, check your internet connection and try again."
let fullsizePictureUploadError = "Failed to upload fullsize image to database. Please, check your internet connection and try again. Despite this error, thumbnail version of this picture has been uploaded, but you still should re-upload your fullsize image."

extension String {
    
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
    
    var doubleValue: Double {
        return Double(self) ?? 0
    }
}

extension UINavigationController {
    
    func backToViewController(viewController: Swift.AnyClass) {
        
        for element in viewControllers {
            if element.isKind(of: viewController) {
                self.popToViewController(element, animated: true)
                break
            }
        }
    }
}

extension UICollectionView {
    func deselectAllItems(animated: Bool = false) {
        for indexPath in self.indexPathsForSelectedItems ?? [] {
            self.deselectItem(at: indexPath, animated: animated)
        }
    }
}


extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}

//extension Collection {
//    func insertionIndex(of element: Self.Iterator.Element,
//                        using areInIncreasingOrder: (Self.Iterator.Element, Self.Iterator.Element) -> Bool) -> Index {
//        return firstIndex(where: { !areInIncreasingOrder($0, element) }) ?? endIndex
//    }
//}

extension Bool {
    init<T: BinaryInteger>(_ num: T) {
        self.init(num != 0)
    }
}

extension Int {
    func toString() -> String {
        let myString = String(self)
        return myString
    }
}

extension String {
    func toInt() -> Int {
        let myInt = Int(self)
        return myInt ?? 0
    }
    
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if self.contains("T") {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }  else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
        }
        if let date = dateFormatter.date(from:self) {
            return date
        } else {
            return nil
        }
    }
}

extension Date {
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> TimeInterval {
        let duration =  Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
        return Double(abs(duration))
    }
    
}

extension Date {
    
    func getShortDateStringForActivity() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from: self)
    }
    
    func getMonthAndDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "MMM, dd"
        return dateFormatter.string(from: self)
    }
    
    func getTimeStringForActivity() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: self)
    }
    
    func dayOfWeekForActivity() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: self).capitalized
    }
    
    func getShortDateStringFromUTC() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from: self)
    }
    
    func getTimeStringFromUTC() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: self)
    }
    
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: self).capitalized
    }
    
    func dayNumberOfWeek() -> Int {
        return Calendar.current.dateComponents([.weekday], from: self).weekday!
    }
    func dayNumber() -> Int {
        return Calendar.current.dateComponents([.day], from: self).day!
    }
    func monthNumber() -> Int {
        return Calendar.current.dateComponents([.month], from: self).month!
    }
    func yearNumber() -> Int {
        return Calendar.current.dateComponents([.year], from: self).year!
    }
}

func timestampOfLastMessage(_ date: Date) -> String {
    let calendar = NSCalendar.current
    let unitFlags: Set<Calendar.Component> = [ .day, .weekOfYear, .weekday]
    let now = Date()
    let earliest = now < date ? now : date
    let latest = (earliest == now) ? date : now
    let components =  calendar.dateComponents(unitFlags, from: earliest,  to: latest)
    
    //  if components.weekOfYear! >= 1 {
    //    return date.getShortDateStringFromUTC()
    //  } else if components.weekOfYear! < 1 && date.dayNumberOfWeek() != now.dayNumberOfWeek() {
    //    return date.dayOfWeek()
    //  } else {
    //    return date.getTimeStringFromUTC()
    //  }
    
    if now.getShortDateStringFromUTC() != date.getShortDateStringFromUTC() {  // not today
        if components.weekOfYear! >= 1 { // last week
            return date.getShortDateStringFromUTC()
        } else { // this week
            return date.dayOfWeek()
        }
        
    } else { // this day
        return date.getTimeStringFromUTC()
    }
    
    
}

func timestampOfActivity(startDate: Date, endDate: Date, allDay: Bool) -> (String, String) {
    var startString: String
    var endString: String
    let calendar = NSCalendar.current
    let unitFlags: Set<Calendar.Component> = [ .day, .weekOfYear, .weekday]
    let now = Date()
    let startEarliest = now < startDate ? now : startDate
    let startLatest = (startEarliest == now) ? startDate : now
    let startComponents =  calendar.dateComponents(unitFlags, from: startEarliest,  to: startLatest)
    let endEarliest = now < endDate ? now : endDate
    let endLatest = (endDate == now) ? endDate : now
    let endComponents =  calendar.dateComponents(unitFlags, from: endEarliest,  to: endLatest)
    
    if now.getShortDateStringForActivity() != startDate.getShortDateStringForActivity() {  // not today
        if startComponents.weekOfYear! >= 1 || startComponents.weekOfYear! <= -1 { // start date is next week
            if allDay {
                if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                    startString = startDate.getShortDateStringForActivity() + " All Day"
                    endString = ""
                } else {
                    startString = startDate.getShortDateStringForActivity() + " All Day"
                    endString = " - " + endDate.getShortDateStringForActivity() + " All Day"
                }
            } else {
                if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                    startString = startDate.getShortDateStringForActivity() + " " + startDate.getTimeStringForActivity()
                    endString = " - " + endDate.getTimeStringForActivity()
                } else {
                    startString = startDate.getShortDateStringForActivity() + " " + startDate.getTimeStringForActivity()
                    endString = " - " + endDate.getShortDateStringForActivity() + " " + endDate.getTimeStringForActivity()
                }
            }
        } else { // start date is this week
            if allDay {
                if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                    startString = startDate.dayOfWeekForActivity() + " All Day"
                    endString = ""
                } else {
                    if endComponents.weekOfYear! >= 1 { // end date is next week
                        startString = startDate.dayOfWeekForActivity() + " All Day"
                        endString = " - " + endDate.getShortDateStringForActivity() + " All Day"
                    } else {
                        startString = startDate.dayOfWeekForActivity() + " All Day"
                        endString = " - " + endDate.dayOfWeek() + " All Day"
                    }
                }
                
            } else {
                if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                    startString = startDate.dayOfWeekForActivity() + " @ " + startDate.getTimeStringForActivity()
                    endString = " - " + endDate.getTimeStringForActivity()
                } else {
                    if endComponents.weekOfYear! >= 1 { // end date is next week
                        startString = startDate.dayOfWeekForActivity() + " @ " + startDate.getTimeStringForActivity()
                        endString = " - " + endDate.getShortDateStringForActivity() + " " + endDate.getTimeStringForActivity()
                    } else {
                        startString = startDate.dayOfWeekForActivity() + " @ " + startDate.getTimeStringForActivity()
                        endString = " - " + endDate.dayOfWeekForActivity() + " @ " + endDate.getTimeStringForActivity()
                    }
                }
            }
        }
    } else { // start day is today
        if allDay {
            if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                startString = "Today All Day"
                endString = ""
            } else {
                if endComponents.weekOfYear! >= 1 { // end date is next week
                    startString = "Today All Day"
                    endString = " - " + endDate.getShortDateStringForActivity() + " All Day"
                } else {
                    startString = "Today All Day"
                    endString = " - " + endDate.dayOfWeekForActivity() + " All Day"
                }
            }
        } else {
            if startDate.getShortDateStringForActivity() == endDate.getShortDateStringForActivity() {
                startString = "Today @ " + startDate.getTimeStringForActivity()
                endString = " - " + endDate.getTimeStringForActivity()
            } else {
                if endComponents.weekOfYear! >= 1 { // end date is next week
                    startString = "Today @ " + startDate.getTimeStringForActivity()
                    endString = " - " + endDate.getShortDateStringForActivity() + " " + endDate.getTimeStringForActivity()
                } else {
                    startString = "Today @ " + startDate.getTimeStringForActivity()
                    endString = " - " + endDate.dayOfWeekForActivity() + " @ " + endDate.getTimeStringForActivity()
                }
            }
        }
    }
    
    return (startString, endString)
    
}

func timestampOfChatLogMessage(_ date: Date) -> String {
    let now = Date()
    if now.getShortDateStringFromUTC() != date.getShortDateStringFromUTC() {
        return "\(date.getShortDateStringFromUTC())\n\(date.getTimeStringFromUTC())"
    } else {
        return date.getTimeStringFromUTC()
    }
}

func timeAgoSinceDate(_ date:Date, numericDates:Bool = false) -> String {
    let calendar = NSCalendar.current
    let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
    let now = Date()
    let earliest = now < date ? now : date
    let latest = (earliest == now) ? date : now
    let components = calendar.dateComponents(unitFlags, from: earliest,  to: latest)
    
    if (components.year! >= 2) {
        return "\(components.year!) years ago"
    } else if (components.year! >= 1){
        if (numericDates){
            return "1 year ago"
        } else {
            return "last year"
        }
    } else if (components.month! >= 2) {
        return "\(components.month!) months ago"
    } else if (components.month! >= 1){
        if (numericDates){
            return "1 month ago"
        } else {
            return "last month"
        }
    } else if (components.weekOfYear! >= 2) {
        return "\(components.weekOfYear!) weeks ago"
    } else if (components.weekOfYear! >= 1){
        if (numericDates){
            return "1 week ago"
        } else {
            return "last week"
        }
    } else if (components.day! >= 2) {
        return "\(components.day!) days ago"
    } else if (components.day! >= 1){
        if (numericDates){
            return "1 day ago"
        } else {
            return "yesterday at \(date.getTimeStringFromUTC())"
        }
    } else if (components.hour! >= 2) {
        return "\(components.hour!) hours ago"
    } else if (components.hour! >= 1){
        if (numericDates){
            return "1 hour ago"
        } else {
            return "an hour ago"
        }
    } else if (components.minute! >= 2) {
        return "\(components.minute!) minutes ago"
    } else if (components.minute! >= 1){
        if (numericDates){
            return "1 minute ago"
        } else {
            return "a minute ago"
        }
    } else if (components.second! >= 3) {
        return "just now"//"\(components.second!) seconds ago"
    } else {
        return "just now"
    }
}

extension Date: Strideable {
    public func distance(to other: Date) -> TimeInterval {
        return other.timeIntervalSinceReferenceDate - self.timeIntervalSinceReferenceDate
    }
    
    public func advanced(by n: TimeInterval) -> Date {
        return self + n
    }
}

extension Dictionary where Key: Comparable, Value: Equatable {
    func minus(dict: [Key:Value]) -> [Key:Value] {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
            var res = res
            res[entry.0] = entry.1
            return res
        }
    }
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func filterDictionaryUsingRegex(withRegex regex: String) -> Dictionary<Key, Value> {
        return self.filter({($0.key as! String).range(of: ".*\(regex.lowercased()).*", options: .regularExpression) != nil}).toDictionary(byTransforming: {$0})
    }
}

extension Array
{
    func toDictionary<H:Hashable, T>(byTransforming transformer: (Element) -> (H, T)) -> Dictionary<H, T>
    {
        var result = Dictionary<H,T>()
        self.forEach({ element in
            let (key,value) = transformer(element)
            result[key] = value
        })
        return result
    }
}

extension UITableViewCell {
    var selectionColor: UIColor {
        set {
            let view = UIView()
            view.backgroundColor = newValue
            
            self.selectedBackgroundView = view
        }
        get {
            return self.selectedBackgroundView?.backgroundColor ?? UIColor.clear
        }
    }
}

extension SystemSoundID {
    static func playFileNamed(fileName: String, withExtenstion fileExtension: String) {
        var sound: SystemSoundID = 0
        if let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
            AudioServicesPlaySystemSound(sound)
        }
    }
}

func basicErrorAlertWith (title: String, message: String, controller: UIViewController) {
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
    controller.present(alert, animated: true, completion: nil)
}

func libraryAccessChecking() -> Bool {
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    switch status {
    case .authorized:
        return true
        
    case .denied, .restricted :
        return false
        
    case .notDetermined:
        return false
    @unknown default:
        fatalError()
    }
}

public let statusOnline = "Online"
public let userMessagesFirebaseFolder = "userMessages"
public let messageMetaDataFirebaseFolder = "metaData"

func setOnlineStatus()  {
    
    if Auth.auth().currentUser != nil {
        let onlineStatusReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("OnlineStatus")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        connectedRef.observe(.value, with: { (snapshot) in
            guard let connected = snapshot.value as? Bool, connected else { return }
            onlineStatusReference.setValue(statusOnline)
            
            onlineStatusReference.onDisconnectSetValue(ServerValue.timestamp())
        })
    }
}


extension UINavigationItem {
    
    func setTitle(title:String, subtitle:String) {
        
        //    let button =  UIButton(type: .custom)
        //    button.frame = CGRect(x: 0, y: 0, width: 100, height: 35)
        //    button.backgroundColor = .clear
        //    button.setTitle(title, for: .normal)
        //    button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        //    button.titleLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        //    button.addTarget(self, action: #selector(getInfoAction), for: .touchUpInside)
        //    navigationItem.titleView = button
        
        let one = UILabel()
        one.text = title
        one.textColor = ThemeManager.currentTheme().generalTitleColor
        //    one.font = UIFont.systemFont(ofSize: 17)
        one.font = UIFont.preferredFont(forTextStyle: .body)
        one.adjustsFontForContentSizeCategory = true
        
        one.sizeToFit()
        
        let two = UILabel()
        two.text = subtitle
        //    two.font = UIFont.systemFont(ofSize: 12)
        two.font = UIFont.preferredFont(forTextStyle: .subheadline)
        two.adjustsFontForContentSizeCategory = true
        two.textAlignment = .center
        two.textColor = ThemeManager.currentTheme().generalSubtitleColor
        two.sizeToFit()
        
        let stackView = UIStackView(arrangedSubviews: [one, two])
        stackView.distribution = .equalCentering
        stackView.axis = .vertical
        
        let width = max(one.frame.size.width, two.frame.size.width)
        stackView.frame = CGRect(x: 0, y: 0, width: width, height: 35)
        
        one.sizeToFit()
        two.sizeToFit()
        self.titleView = stackView
    }
}

extension UIImage {
    var asJPEGData: Data? {
        //	self.jpegData(compressionQuality: 1)
        return self.jpegData(compressionQuality: 1)   // QUALITY min = 0 / max = 1
    }
    var asPNGData: Data? {
        return self.pngData()
    }
}

extension PHAsset {
    
    var originalFilename: String? {
        
        var fname:String?
        
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                fname = resource.originalFilename
            }
        }
        
        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }
        
        return fname
    }
}

extension Data {
    var asUIImage: UIImage? {
        return UIImage(data: self)
    }
}

extension FileManager {
    func clearTemp() {
        do {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach { file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}

public func rearrange<T>(array: Array<T>, fromIndex: Int, toIndex: Int) -> Array<T>{
    var arr = array
    let element = arr.remove(at: fromIndex)
    arr.insert(element, at: toIndex)
    
    return arr
}

extension UISearchBar {
    func changeBackgroundColor(to color: UIColor) {
        if let textfield = self.value(forKey: "searchField") as? UITextField {
            textfield.textColor = UIColor.blue
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = color
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }
    }
}

extension UITableView {
    
    func indexPathForView(_ view: UIView) -> IndexPath? {
        let center = view.center
        let viewCenter = self.convert(center, from: view.superview)
        let indexPath = self.indexPathForRow(at: viewCenter)
        return indexPath
    }
}

extension UIScrollView {
    
    // Scroll to a specific view so that it's top is at the top our scrollview
    func scrollToView(view:UIView, animated: Bool) {
        if let origin = view.superview {
            // Get the Y position of your child view
            let childStartPoint = origin.convert(view.frame.origin, to: self)
            // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview
            self.scrollRectToVisible(CGRect(x:0, y:childStartPoint.y, width: 1, height: self.frame.height), animated: animated)
        }
    }
    
    // Bonus: Scroll to top
    func scrollToTop(animated: Bool) {
        let topOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(topOffset, animated: animated)
    }
}

func createImageThumbnail (_ image: UIImage) -> UIImage {
    
    let actualHeight:CGFloat = image.size.height
    let actualWidth:CGFloat = image.size.width
    let imgRatio:CGFloat = actualWidth/actualHeight
    let maxWidth:CGFloat = 150.0
    let resizedHeight:CGFloat = maxWidth/imgRatio
    let compressionQuality:CGFloat = 0.5
    
    let rect:CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
    UIGraphicsBeginImageContext(rect.size)
    image.draw(in: rect)
    let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    let imageData: Data = img.jpegData(compressionQuality: compressionQuality)!
    UIGraphicsEndImageContext()
    
    return UIImage(data: imageData)!
}

func compressImage(image: UIImage) -> Data {
    // Reducing file size to a 10th
    
    var actualHeight : CGFloat = image.size.height
    var actualWidth : CGFloat = image.size.width
    let maxHeight : CGFloat = 1920.0
    let maxWidth : CGFloat = 1080.0
    var imgRatio : CGFloat = actualWidth/actualHeight
    let maxRatio : CGFloat = maxWidth/maxHeight
    var compressionQuality : CGFloat = 0.8
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        
        if (imgRatio < maxRatio) {
            
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        } else if (imgRatio > maxRatio) {
            
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
            
        } else {
            
            actualHeight = maxHeight
            actualWidth = maxWidth
            compressionQuality = 1
        }
    }
    
    let rect = CGRect(x: 0.0, y: 0.0, width:actualWidth, height:actualHeight)
    UIGraphicsBeginImageContext(rect.size)
    image.draw(in: rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    let imageData = img!.jpegData(compressionQuality: compressionQuality)
    UIGraphicsEndImageContext();
    
    return imageData!
}

func uiImageFromAsset(phAsset: PHAsset) -> UIImage? {
    
    var img: UIImage?
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.version = .current
    options.deliveryMode = .fastFormat
    options.resizeMode = .exact
    options.isSynchronous = true
    manager.requestImageData(for: phAsset, options: options) { data, _, _, _ in
        
        if let data = data {
            img = UIImage(data: data)
        }
    }
    return img
}

func dataFromAsset(asset: PHAsset) -> Data? {
    
    var finalData: Data?
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.version = .current
    options.deliveryMode = .fastFormat
    options.isSynchronous = true
    options.resizeMode = .exact
    options.normalizedCropRect = CGRect(x: 0, y: 0, width: 1000, height: 1000)
    manager.requestImageData(for: asset, options: options) { data, _, _, _ in
        finalData = data
    }
    
    return finalData
}

extension UILabel {
    var maxNumberOfLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font as Any], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}

extension UILabel {
    var numberOfVisibleLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let textHeight = sizeThatFits(maxSize).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}

public extension UIView {
    
    func shake(count : Float? = nil,for duration : TimeInterval? = nil,withTranslation translation : Float? = nil) {
        
        // You can change these values, so that you won't have to write a long function
        let defaultRepeatCount = 3
        let defaultTotalDuration = 0.1
        let defaultTranslation = -8
        
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        
        animation.repeatCount = count ?? Float(defaultRepeatCount)
        animation.duration = (duration ?? defaultTotalDuration)/TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.byValue = translation ?? defaultTranslation
        layer.add(animation, forKey: "shake")
    }
}

extension UIView {
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?,  paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
}

func uploadAvatarForUserToFirebaseStorageUsingImage(_ image: UIImage, quality: CGFloat, completion: @escaping (_  imageUrl: String) -> ()) {
    let imageName = UUID().uuidString
    let ref = Storage.storage().reference().child("userProfilePictures").child(imageName)
    
    if let uploadData = image.jpegData(compressionQuality: quality) {
        ref.putData(uploadData, metadata: nil) { (metadata, error) in
            guard error == nil else { completion(""); return }
            
            ref.downloadURL(completion: { (url, error) in
                guard error == nil, let imageURL = url else { completion(""); return }
                completion(imageURL.absoluteString)
            })
        }
    }
}

func uploadAvatarForActivityToFirebaseStorageUsingImage(_ image: UIImage, quality: CGFloat, completion: @escaping (_  imageUrl: String) -> ()) {
    let imageName = UUID().uuidString
    let ref = Storage.storage().reference().child("activityImages").child(imageName)
    
    if let uploadData = image.jpegData(compressionQuality: quality) {
        ref.putData(uploadData, metadata: nil) { (metadata, error) in
            guard error == nil else { completion(""); return }
            
            ref.downloadURL(completion: { (url, error) in
                guard error == nil, let imageURL = url else { completion(""); return }
                completion(imageURL.absoluteString)
            })
        }
    }
}

func uploadDocToFirebaseStorage(_ url: URL, contentType: String, name: String, completion: @escaping (_  url: String) -> ()) {
    let fileName = UUID().uuidString
    let ref = Storage.storage().reference().child("activityDocs").child(fileName)

    let localFile = url
    // Create the file metadata
    let metadata = StorageMetadata()
    metadata.contentType = contentType
    metadata.customMetadata = ["name": name, "type": url.pathExtension]
        
    ref.putFile(from: localFile, metadata: metadata) { (metadata, error) in
        guard error == nil else { completion(""); return }
        ref.downloadURL(completion: { (url, error) in
            guard error == nil, let url = url else { completion(""); return }
            completion(url.absoluteString)
        })
    }
}

private var backgroundView: UIView = {
    let backgroundView = UIView()
    backgroundView.backgroundColor = UIColor.black
    backgroundView.alpha = 0.8
    backgroundView.layer.cornerRadius = 0
    backgroundView.layer.masksToBounds = true
    
    return backgroundView
}()

private var activityIndicator: UIActivityIndicatorView = {
    var activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    activityIndicator.hidesWhenStopped = true
    activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
    activityIndicator.style = UIActivityIndicatorView.Style.large
    activityIndicator.autoresizingMask = [.flexibleLeftMargin , .flexibleRightMargin , .flexibleTopMargin , .flexibleBottomMargin]
    activityIndicator.isUserInteractionEnabled = false
    
    return activityIndicator
}()


extension UIImageView {
    
    func showActivityIndicator() {
        
        self.addSubview(backgroundView)
        self.addSubview(activityIndicator)
        activityIndicator.style = UIActivityIndicatorView.Style.medium
        activityIndicator.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        DispatchQueue.main.async {
            activityIndicator.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
        }
        
        activityIndicator.removeFromSuperview()
        backgroundView.removeFromSuperview()
    }
}

protocol Utilities {}

extension NSObject: Utilities {
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
}

var vSpinner : UIView?

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

let messageAlert = UIAlertController(title: "Activity Sent!", message: nil, preferredStyle: UIAlertController.Style.alert)

let activityAlert = UIAlertController(title: "Activity Created!", message: nil, preferredStyle: UIAlertController.Style.alert)

let activityNFAlert = UIAlertController(title: "Could Not Load Activity", message: nil, preferredStyle: UIAlertController.Style.alert)

let dupeRecipeAlert = UIAlertController(title: "Recipe already on Grocery List", message: nil, preferredStyle: UIAlertController.Style.alert)

extension UIViewController {
    func messageSentAlert() {
        self.present(messageAlert, animated: true, completion: nil)
    }
    func removeMessageAlert() {
        messageAlert.dismiss(animated: true, completion: nil)
    }
    func activitySentAlert() {
        self.present(activityAlert, animated: true, completion: nil)
    }
    func removeActivityAlert() {
        activityAlert.dismiss(animated: true, completion: nil)
    }
    func activityNotFoundAlert() {
        self.present(activityNFAlert, animated: true, completion: nil)
    }
    func removeActivityNotFoundAlert() {
        activityNFAlert.dismiss(animated: true, completion: nil)
    }
    func dupeRecAlert() {
        self.present(dupeRecipeAlert, animated: true, completion: nil)
    }
    func removeDupeRecAlert() {
        dupeRecipeAlert.dismiss(animated: true, completion: nil)
    }
}

extension String {
    func removeCharacters() -> String {
        var updatedSelf = self
        if self.contains("/") {
            updatedSelf = self.replacingOccurrences(of: "/", with: "")
        }
        if self.contains(".") {
            updatedSelf = self.replacingOccurrences(of: ".", with: "")
        }
        if self.contains("#") {
            updatedSelf = self.replacingOccurrences(of: "#", with: "")
        }
        if self.contains("$") {
            updatedSelf = self.replacingOccurrences(of: "$", with: "")
        }
        if self.contains("[") {
            updatedSelf = self.replacingOccurrences(of: "[", with: "")
        }
        if self.contains("]") {
            updatedSelf = self.replacingOccurrences(of: "]", with: "")
        }
        return updatedSelf
    }
}

// MARK: - Reminder Frequency
enum EventAlert : String, CustomStringConvertible {
    case None = "None"
    case At_time_of_event = "At time of activity"
    case Five_Minutes = "5 minutes before"
    case Fifteen_Minutes = "15 minutes before"
    case Half_Hour = "30 minutes before"
    case One_Hour = "1 hour before"
    case One_Day = "1 day before"
    case One_Week = "1 week before"
    case One_Month = "1 month before"
    
    var description : String { return rawValue }
    
    static let allValues = [None, At_time_of_event, Fifteen_Minutes, Half_Hour, One_Hour, One_Day, One_Week, One_Month]
    
    var timeInterval: Double {
        switch self {
        case .None:
            return 0
        case .At_time_of_event:
            return 0
        case .Fifteen_Minutes:
            return -900
        case .Half_Hour:
            return -1800
        case .One_Hour:
            return -3600
        case .One_Day:
            return -86400
        case .One_Week:
            return -604800
        case .One_Month:
            return -2419200
        default:
            return 0
        }
    }
    
    static func fromInterval(_ interval: TimeInterval) -> EventAlert {
        switch interval {
        case 0:
            return .At_time_of_event
        case 900:
            return .Fifteen_Minutes
        case 1800:
            return .Half_Hour
        case 3600:
            return .One_Hour
        case 86400:
            return .One_Day
        case 604800:
            return .One_Week
        case 2419200:
            return .One_Month
        default:
            return .None
        }
    }
    
}

public func runUserBadgeUpdate(firstChild: String) {
    var ref = Database.database().reference().child("users").child(firstChild)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
        guard snapshot.hasChild("badge") else {
            ref.updateChildValues(["badge": 1])
            return
        }
        
        ref = ref.child("badge")
        ref.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            if value == nil { value = 0 }
            mutableData.value = value! + 1
            return TransactionResult.success(withValue: mutableData)
        })
    })
}

extension Array where Element: Comparable {
    func containsSameElements(_ other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

let activityIndicatorView: UIActivityIndicatorView = {
    let aiv = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    aiv.color = .darkGray
    aiv.startAnimating()
    aiv.hidesWhenStopped = true
    return aiv
}()

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.25)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

class DictionaryEncoder {
    
    private let encoder = JSONEncoder()
    
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        set { encoder.dateEncodingStrategy = newValue }
        get { return encoder.dateEncodingStrategy }
    }
    
    var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy {
        set { encoder.dataEncodingStrategy = newValue }
        get { return encoder.dataEncodingStrategy }
    }
    
    var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy {
        set { encoder.nonConformingFloatEncodingStrategy = newValue }
        get { return encoder.nonConformingFloatEncodingStrategy }
    }
    
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        set { encoder.keyEncodingStrategy = newValue }
        get { return encoder.keyEncodingStrategy }
    }
    
    func encode<T>(_ value: T) throws -> [String: Any] where T : Encodable {
        let data = try encoder.encode(value)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
    }
}


class DictionaryDecoder {
    private let jsonDecoder = JSONDecoder()
    
    /// Decodes given Decodable type from given array or dictionary
    func decode<T>(_ type: T.Type, from json: Any) throws -> T where T: Decodable {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return try jsonDecoder.decode(type, from: jsonData)
    }
}

public protocol FormatterProtocol {
    func getNewPosition(forPosition: UITextPosition, inTextInput textInput: UITextInput, oldValue: String?, newValue: String?) -> UITextPosition
}

class CurrencyFormatter : NumberFormatter, FormatterProtocol {
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, range rangep: UnsafeMutablePointer<NSRange>?) throws {
        guard obj != nil else { return }
        var str = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        if !string.isEmpty, numberStyle == .currency && !string.contains(currencySymbol) {
            // Check if the currency symbol is at the last index
            if let formattedNumber = self.string(from: 1), String(formattedNumber[formattedNumber.index(before: formattedNumber.endIndex)...]) == currencySymbol {
                // This means the user has deleted the currency symbol. We cut the last number and then add the symbol automatically
                str = String(str[..<str.index(before: str.endIndex)])
                
            }
        }
        obj?.pointee = NSNumber(value: (Double(str) ?? 0.0)/Double(pow(10.0, Double(minimumFractionDigits))))
    }
    
    func getNewPosition(forPosition position: UITextPosition, inTextInput textInput: UITextInput, oldValue: String?, newValue: String?) -> UITextPosition {
        return textInput.position(from: position, offset:((newValue?.count ?? 0) - (oldValue?.count ?? 0))) ?? position
    }
}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    static let iso8601withFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Array where Element: Equatable {
    
    func reorder(by preferredOrder: [Element]) -> [Element] {
        
        return self.sorted { (a, b) -> Bool in
            guard let first = preferredOrder.firstIndex(of: a) else {
                return false
            }
            
            guard let second = preferredOrder.firstIndex(of: b) else {
                return true
            }
            
            return first < second
        }
    }
}

public struct HardCodedOrdering<Element> where Element: Hashable {
    public enum UnspecifiedItemSortingPolicy {
        case first
        case last
        case assertAllItemsHaveDefinedSorting
    }
    
    private let ordering: [Element: Int]
    private let sortingPolicy: UnspecifiedItemSortingPolicy
    
    public init(
        ordering: Element...,
        sortUnspecifiedItems sortingPolicy: UnspecifiedItemSortingPolicy = .assertAllItemsHaveDefinedSorting
    ) {
        self.init(ordering: ordering, sortUnspecifiedItems: sortingPolicy)
    }
    
    public init<S: Sequence>(
        ordering: S,
        sortUnspecifiedItems sortingPolicy: UnspecifiedItemSortingPolicy = .assertAllItemsHaveDefinedSorting
    ) where S.Element == Element {
        
        self.ordering = Dictionary(uniqueKeysWithValues: zip(ordering, 1...))
        self.sortingPolicy = sortingPolicy
    }
    
    private func sortKey(for element: Element) -> Int {
        if let definedSortKey = self.ordering[element] { return definedSortKey }
        
        switch sortingPolicy {
        case .first:    return Int.min
        case .last:     return Int.max
            
        case .assertAllItemsHaveDefinedSorting:
            fatalError("Found an element that does not have a defined ordering: \(element)")
        }
    }
    
    public func contains(_ element: Element) -> Bool {
        return self.ordering.keys.contains(element)
    }
    
    // For use in sorting a collection of `T`s by the value's yielded by `keyDeriver`.
    // A throwing varient could be introduced, if necessary.
    public func areInIncreasingOrder<T>(by keyDeriver: @escaping (T) -> Element) -> (T, T) -> Bool {
        return { lhs, rhs in
            self.sortKey(for: keyDeriver(lhs)) < self.sortKey(for: keyDeriver(rhs))
        }
    }
    
    // For use in sorting a collection of `Element`s
    public func areInIncreasingOrder(_ lhs: Element, rhs: Element) -> Bool {
        return sortKey(for: lhs) < sortKey(for: rhs)
    }
}

extension UITextField {
    
    func addDoneButtonOnKeyboard() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self, action: #selector(resignFirstResponder))
        keyboardToolbar.items = [flexibleSpace, doneButton]
        self.inputAccessoryView = keyboardToolbar
    }
}

