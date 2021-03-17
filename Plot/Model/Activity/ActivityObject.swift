//
//  ActivityObject.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Photos

class ActivityObject: NSObject {
    var object: Data?
    var activityID: String?
    var activityName: String?
    var activityTypeID: String?
    var activityType: String?
    var activityImageURL: String?
    var activityCategory: String?
    var activitySubcategory: String?
  
    init(dictionary: [String: AnyObject]) {
        super.init()
        activityName = dictionary["activityName"] as? String
        activityID = dictionary["activityID"] as? String
        activityTypeID = dictionary["activityTypeID"] as? String
        activityType = dictionary["activityType"] as? String
        activityImageURL = dictionary["activityImageURL"] as? String
        activityCategory = dictionary["activityCategory"] as? String
        activitySubcategory = dictionary["activitySubcategory"] as? String
        object = dictionary["object"] as? Data
    }
}
