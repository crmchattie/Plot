//
//  ActivityDetailService.swift
//  Plot
//
//  Created by Cory McHattie on 11/3/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

protocol ActivityDetailServiceInterface {
    
    func getSamples(
        segmentType: TimeSegmentType,
        activities: [Activity]?,
        completion: @escaping ([SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Void)
    
    func getSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([SectionType: [String: [Statistic]]]) -> Void)
}

class ActivityDetailService: ActivityDetailServiceInterface {
    func getSamples(segmentType: TimeSegmentType, activities: [Activity]?, completion: @escaping ([SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Swift.Void) {
        getStatisticalSamples(segmentType: segmentType, range: nil, activities: activities, completion: completion)
    }
    
    func getSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([SectionType : [String : [Statistic]]]) -> Void) {
        getStatisticalSamples(segmentType: segment, range: range, activities: activities) { (_, stats, _) in
            completion(stats ?? [:])
        }
    }

    private func getStatisticalSamples(segmentType: TimeSegmentType, range: DateRange?, activities: [Activity]?, completion: @escaping ([SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Void) {

        let dispatchGroup = DispatchGroup()
        var pieChartEntries = [SectionType: [Entry]]()
        var barChartStats = [SectionType: [String: [Statistic]]]()
        
        let anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate
        
        if let range = range {
            startDate = range.startDate
            endDate = range.endDate
        } else if segmentType == .day {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.endOfDay
        } else if segmentType == .week {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.endOfWeek
        } else if segmentType == .month {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.endOfMonth
        } else if segmentType == .year {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.endOfYear
        }
        
        if let activities = activities {
            var entries = [Entry]()
            dispatchGroup.enter()
            categorizeActivities(activities: activities, start: startDate, end: endDate) { (categoryDict, activitiesList) in
                activitiesOverTimeChartData(activities: activitiesList, activityCategories: Array(categoryDict.keys), start: startDate, end: endDate, segmentType: segmentType) { (statsDict, _) in
                    if !statsDict.isEmpty {
                        barChartStats[.calendarSummary] = statsDict
                    }
                }
                
                let totalValue: Double = endDate.timeIntervalSince(startDate)
                for (key, value) in categoryDict {
                    let entry = Entry(label: key.capitalized, value: value / totalValue, icon: nil)
                    entries.append(entry)
                }
                if !entries.isEmpty {
                    pieChartEntries[.calendarMix] = entries
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(pieChartEntries, barChartStats, nil)
        }
    }
}

struct Entry {
    var label: String
    var value: Double
    var icon: UIImage?
}
