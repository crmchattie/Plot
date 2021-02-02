//
//  GoogleService.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn

class GoogleService {
    var calendarService: GTLRCalendarService? {
        return GoogleSetupAssistant.calendarService
    }
    
    var user : GIDGoogleUser?
    
    func setupGoogle(completion: @escaping (Bool) -> Swift.Void) {
        GoogleSetupAssistant.setupGoogle { bool in
            if let user = GIDSignIn.sharedInstance()?.currentUser {
                print("user \(user.profile.email)")
                self.user = user
            }
            completion(bool)
        }
    }
    
    func grabCalendars(completion: @escaping ([String: [String]]?) -> Swift.Void) {
        print("grabCalendars")
        guard let service = self.calendarService, let user = user else {
            completion(nil)
            return
        }
        
        print("GIDSignIn.sharedInstance().scopes \(GIDSignIn.sharedInstance().scopes)")
        print("service.authorizer?.canAuthorize \(service.authorizer?.canAuthorize)")
        
        var calendars = [String: [String]]()
        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let items = (result as? GTLRCalendar_CalendarList)?.items else {
                print("error \(error)")
                completion(nil)
                return
            }
            print("items.map { $0.summary ??} \(items.map { $0.summary ?? "" })")
            calendars[user.profile.email] = items.map { $0.summary ?? "" }
            completion(calendars)
        }
    }
}
