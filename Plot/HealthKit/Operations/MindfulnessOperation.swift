//
//  MindfulnessOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-18.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class MindfulnessOperation: AsyncOperation {
    weak var delegate: MetricOperationDelegate?
    private var date: Date
    var lastSyncDate: Date?
    
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date
        let startDate = endDate.lastYear
        HealthKitService.getAllCategoryTypeSamples(forIdentifier: .mindfulSession, startDate: startDate, endDate: endDate) { [weak self] samples, error  in
            guard let samples = samples, samples.count > 0, error == nil, let _self = self, let currentUserID = Auth.auth().currentUser?.uid else {
                self?.finish()
                return
            }
            
            let healthkitMindfulnessReference = Database.database().reference().child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey)
            healthkitMindfulnessReference.observeSingleEvent(of: .value) { dataSnapshot in
                var existingMindfulnessKeys: [String: Any] = [:]
                if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: Any] {
                    existingMindfulnessKeys = dataSnapshotValue
                }
                                
                var startDay = startDate.dayBefore
                var interval = NSDateInterval(start: startDay, duration: 86400)
                var map: [Date: Double] = [:]
                var sum: Double = 0
                for sample in samples {
                    while !(interval.contains(sample.endDate)) && interval.endDate < endDate {
                        startDay = startDay.advanced(by: 86400)
                        interval = NSDateInterval(start: startDay, duration: 86400)
                    }
                    
                    let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                    map[startDay, default: 0] += timeSum
                    sum += timeSum
                    
                    // Only create activities that past lastSync date time
                    if (_self.lastSyncDate == nil || (sample.startDate >= _self.lastSyncDate!)) && existingMindfulnessKeys[sample.uuid.uuidString] == nil {
                        let ref = Database.database().reference()
                        var mindfulnessID = UUID().uuidString

                        if let newMindfulnessId = ref.child(userMindfulnessEntity).child(currentUserID).childByAutoId().key {
                            mindfulnessID = newMindfulnessId
                        }
                        
                        ref.child(userHealthEntity).child(currentUserID).child(healthkitMindfulnessKey).child(sample.uuid.uuidString).child(identifierKey).setValue(mindfulnessID)
                        
                        ref.child(userMindfulnessEntity).child(currentUserID).child(mindfulnessID).child(hkSampleIDKey).setValue(sample.uuid.uuidString)
                                                                                
                        let mindfulnessFB = Mindfulness(forInitialSave: mindfulnessID, mindfuless: sample)
                        let mindfulnessActions = MindfulnessActions(mindfulness: mindfulnessFB, active: false, selectedFalconUsers: [])
                        mindfulnessActions.createNewMindfulness()
                    }
                }
                
                let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
                let average = sum / Double(map.count)
                
                if let last = sortedDates.last?.key, let val = map[last] {
                    var metric = HealthMetric(type: .mindfulness, total: val, date: last, unitName: "hrs", rank: HealthMetricType.mindfulness.rank)
                    metric.hkSample = samples.last
                    metric.average = average
                    _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
                    
                }
                
                self?.finish()

            }
        }
    }
}
