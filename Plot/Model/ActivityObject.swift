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
  var activityName: String?
  var activityType: String?
  var activityID: String?
  var activityImageURL: String?
  
  init(dictionary: [String: AnyObject]) {
    super.init()
    activityName = dictionary["activityName"] as? String
    activityType = dictionary["activityType"] as? String
    activityID = dictionary["activityID"] as? String
    activityImageURL = dictionary["activityImageURL"] as? String
    object = dictionary["object"] as? Data
  }
}
