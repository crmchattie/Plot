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
        seconds = Int(timer.timeInterval)
        if seconds < 1 {
            resetTimer()
            subtitleText.text =  "We have sent you an SMS with the code"
            resend.setTitle("Resend", for: .normal)
            resend.setTitleColor(.white, for: .normal)
            resend.backgroundColor = .systemBlue
        } else {
            subtitleText.text =  "You can try again in \(timeString(time: TimeInterval(seconds)))"
            resend.setTitle("Sent", for: .normal)
            resend.setTitleColor(.systemBlue, for: .normal)
            resend.backgroundColor = .secondarySystemGroupedBackground
        }
    }
    
    func resetTimer() {
        timer.invalidate()
        seconds = 0
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}
