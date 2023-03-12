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
        nextView.setTitle("Sent", for: .normal)
        nextView.setTitleColor(.systemBlue, for: .normal)
        nextView.backgroundColor = .secondarySystemGroupedBackground
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            resetTimer()
            subtitleText.text =  "We have sent you an SMS with the code"
            nextView.setTitle("Resend", for: .normal)
            nextView.setTitleColor(.white, for: .normal)
            nextView.backgroundColor = .systemBlue
        } else {
            seconds -= 1
            subtitleText.text =  "You can try again in \(timeString(time: TimeInterval(seconds)))"
            nextView.setTitle("Sent", for: .normal)
            nextView.setTitleColor(.systemBlue, for: .normal)
            nextView.backgroundColor = .secondarySystemGroupedBackground
        }
    }
    
    func resetTimer() {
        timer.invalidate()
        seconds = 120
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}
