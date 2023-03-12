//
//  EnterVerificationContainerView+timerHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/24/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

extension EnterVerificationContainerView {
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,  selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
        resend.setTitle("Sent", for: .normal)
        resend.setTitleColor(.systemBlue, for: .normal)
        resend.backgroundColor = .secondarySystemGroupedBackground
    }
    
    @objc func updateTimer() {
        print("updateTimer")
        print(seconds)
        if seconds < 1 {
            resetTimer()
        } else {
            seconds -= 1
            subtitleText.text =  "We can send another code in \(timeString(time: TimeInterval(seconds)))"
        }
    }
    
    func resetTimer() {
        subtitleText.text =  "We have sent you an SMS with the code"
        resend.setTitle("Resend", for: .normal)
        resend.setTitleColor(.white, for: .normal)
        resend.backgroundColor = .systemBlue
        
        timer.invalidate()
        seconds = 120
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}
