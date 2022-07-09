//
//  TrackingService.swift
//  Plot
//
//  Created by Cory McHattie on 5/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import AppTrackingTransparency
import AdSupport
import FacebookCore

class TrackingService {
    func requestPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("TrackingService Authorized")
                    Settings.setAdvertiserTrackingEnabled(true)
                    
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("TrackingService Denied")
                    Settings.setAdvertiserTrackingEnabled(false)
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("TrackingService Not Determined")
                    Settings.setAdvertiserTrackingEnabled(false)
                case .restricted:
                    print("TrackingService Restricted")
                    Settings.setAdvertiserTrackingEnabled(false)
                @unknown default:
                    print("TrackingService Unknown")
                }
            }
        }
    }
}
