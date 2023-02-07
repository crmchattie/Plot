//
//  ActivityDetailService.swift
//  Plot
//
//  Created by Cory McHattie on 11/3/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

protocol ActivityDetailServiceInterface {
    func getActivityCategoriesSamples(
        segmentType: TimeSegmentType,
        activities: [Activity],
        completion: @escaping ([String: [Statistic]]?, [Activity]?, Error?) -> Void)
    
    func getActivityCategoriesSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([String: [Statistic]], [Activity]) -> Void)
    
    func getActivityCategoriesSamples(activities: [Activity], activityCategories: [String]?, activitySubcategories: [String]?, range: DateRange, completion: @escaping ([String: [Statistic]]?, [Activity]?) -> Void)
}

class ActivityDetailService: ActivityDetailServiceInterface {
    func getActivityCategoriesSamples(segmentType: TimeSegmentType, activities: [Activity], completion: @escaping ([String: [Statistic]]?, [Activity]?, Error?) -> Swift.Void) {
        getActivityCategoriesStatisticalSamples(segmentType: segmentType, range: nil, activities: activities, completion: completion)
    }
    
    func getActivityCategoriesSamples(for range: DateRange, segment: TimeSegmentType, activities: [Activity], completion: @escaping ([String : [Statistic]], [Activity]) -> Void) {
        getActivityCategoriesStatisticalSamples(segmentType: segment, range: range, activities: activities) { (stats, activities, _) in
            completion(stats ?? [:], activities ?? [])
        }
    }
    
    func getActivityCategoriesSamples(activities: [Activity], activityCategories: [String]?, activitySubcategories: [String]?, range: DateRange, completion: @escaping ([String: [Statistic]]?, [Activity]?) -> Void) {
        getActivityCategoriesStatisticalSamples(activities: activities, activityCategories: activityCategories, activitySubcategories: activitySubcategories, range: range) { (stats, activities, _) in
            completion(stats ?? [:], activities ?? [])
        }
    }

    private func getActivityCategoriesStatisticalSamples(segmentType: TimeSegmentType, range: DateRange?, activities: [Activity], completion: @escaping ([String: [Statistic]]?, [Activity]?, Error?) -> Void) {
        
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
        
        categorizeActivities(activities: activities, start: startDate, end: endDate) { (categoryDict, categorizedActivitiesList) in
            activitiesOverTimeChartData(activities: categorizedActivitiesList, activityCategories: Array(categoryDict.keys), start: startDate, end: endDate, segmentType: segmentType) { (statsDict, _) in
                completion(statsDict, categorizedActivitiesList, nil)
            }
        }
    }
    
    private func getActivityCategoriesStatisticalSamples(activities: [Activity], activityCategories: [String]?, activitySubcategories: [String]?, range: DateRange, completion: @escaping ([String: [Statistic]]?, [Activity]?, Error?) -> Void) {
        activitiesData(activities: activities, activityCategories: activityCategories, activitySubcategories: activitySubcategories, start: range.startDate, end: range.endDate) { stats, activitiesList in
            completion(stats, activitiesList, nil)
        }
    }
}

struct Entry {
    var label: String
    var value: Double
    var icon: UIImage?
}
