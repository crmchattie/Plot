//
//  ActivityDetailService.swift
//  Plot
//
//  Created by Cory McHattie on 11/3/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

protocol ActivityDetailServiceInterface {
    
    func getEventCategoriesSamples(
        segmentType: TimeSegmentType,
        activities: [Activity]?,
        completion: @escaping ([SectionType: [String: [Statistic]]]?, [Activity]?, Error?) -> Void)
    
    func getEventCategoriesSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([SectionType: [String: [Statistic]]], [Activity]) -> Void)
}

class ActivityDetailService: ActivityDetailServiceInterface {
    func getEventCategoriesSamples(segmentType: TimeSegmentType, activities: [Activity]?, completion: @escaping ([SectionType: [String: [Statistic]]]?, [Activity]?, Error?) -> Swift.Void) {
        getEventCategoriesStatisticalSamples(segmentType: segmentType, range: nil, activities: activities, completion: completion)
    }
    
    func getEventCategoriesSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([SectionType : [String : [Statistic]]], [Activity]) -> Void) {
        getEventCategoriesStatisticalSamples(segmentType: segment, range: range, activities: activities) { (stats, activities, _) in
            completion(stats ?? [:], activities ?? [])
        }
    }

    private func getEventCategoriesStatisticalSamples(segmentType: TimeSegmentType, range: DateRange?, activities: [Activity]?, completion: @escaping ([SectionType: [String: [Statistic]]]?, [Activity]?, Error?) -> Void) {

        let dispatchGroup = DispatchGroup()
        var barChartStats = [SectionType: [String: [Statistic]]]()
        var activitiesList = [Activity]()
        
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
            categorizeActivities(activities: activities, start: startDate, end: endDate) { (categoryDict, categorizedActivitiesList) in
                activitiesOverTimeChartData(activities: categorizedActivitiesList, activityCategories: Array(categoryDict.keys), start: startDate, end: endDate, segmentType: segmentType) { (statsDict, _) in
                    if !statsDict.isEmpty {
                        barChartStats[.calendarSummary] = statsDict
                        activitiesList = categorizedActivitiesList
                    }
                }
                
                let totalValue: Double = endDate.timeIntervalSince(startDate)
                for (key, value) in categoryDict {
                    let entry = Entry(label: key.capitalized, value: value / totalValue, icon: nil)
                    entries.append(entry)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(barChartStats, activitiesList, nil)
        }
    }
}

struct Entry {
    var label: String
    var value: Double
    var icon: UIImage?
}
