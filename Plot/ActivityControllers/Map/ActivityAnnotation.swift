//
//  ActivityAnnotation.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-23.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import MapKit

class ActivityAnnotation: MKPointAnnotation {
    var activity: Activity
    
    init(activity: Activity) {
        self.activity = activity
    }
}
