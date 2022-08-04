//
//  Extensions.swift
//  AppStoreJSONApis
//
//  Created by Brian Voong on 2/14/19.
//  Copyright © 2019 Brian Voong. All rights reserved.
//

import UIKit
import HealthKit

extension UILabel {
    convenience init(text: String, font: UIFont, numberOfLines: Int = 1) {
        self.init(frame: .zero)
        self.text = text
        self.font = font
        self.numberOfLines = numberOfLines
    }
}

extension UIImageView {
    convenience init(cornerRadius: CGFloat) {
        self.init(image: nil)
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
    }
}

extension UIButton {
    convenience init(title: String) {
        self.init(type: .system)
        self.setTitle(title, for: .normal)
    }
}

extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}

public extension HKWorkoutActivityType {
    
    /*
     Simple mapping of available workout types to a human readable name.
     */
    var name: String {
        switch self {
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional Strength Training"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Traditional Strength Training"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"
            
        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "High Intensity Interval Training"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"
            
        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"
            
        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"
            
        case .cricket:
            return "Cricket"
        case .cardioDance:
            return "Cardio Dance"
        case .socialDance:
            return "Social Dance"
        case .pickleball:
            return "Pickleball"
        case .cooldown:
            return "Cooldown"
        case .other:
            return "Other"
        @unknown default:
            return "Workout"
        }
    }
    
    var calories: Double {
        switch self {
        case .americanFootball:
            return 0.072
        case .archery:
            return 0.028
        case .australianFootball:
            return 0.072
        case .badminton:
            return 0.036
        case .baseball:
            return 0.028
        case .basketball:
            return 0.064
        case .bowling:
            return 0.024
        case .boxing:
            return 0.072
        case .climbing:
            return 0.088
        case .cricket:
            return 0.036
        case .crossTraining:
            return 0.064
        case .curling:
            return 0.032
        case .cycling:
            return 0.056
        case .dance:
            return 0.044
        case .danceInspiredTraining:
            return 0.048
        case .elliptical:
            return 0.072
        case .equestrianSports:
            return 0.032
        case .fencing:
            return 0.048
        case .fishing:
            return 0.024
        case .functionalStrengthTraining:
            return 0.036
        case .golf:
            return 0.028
        case .gymnastics:
            return 0.032
        case .handball:
            return 0.096
        case .hiking:
            return 0.048
        case .hockey:
            return 0.064
        case .hunting:
            return 0.048
        case .lacrosse:
            return 0.064
        case .martialArts:
            return 0.080
        case .mindAndBody:
            return 0.032
        case .mixedMetabolicCardioTraining:
            return 0.072
        case .paddleSports:
            return 0.056
        case .play:
            return 0.056
        case .preparationAndRecovery:
            return 0.032
        case .racquetball:
            return 0.056
        case .rowing:
            return 0.056
        case .rugby:
            return 0.072
        case .running:
            return 0.072
        case .sailing:
            return 0.024
        case .skatingSports:
            return 0.064
        case .snowSports:
            return 0.048
        case .soccer:
            return 0.056
        case .softball:
            return 0.040
        case .squash:
            return 0.056
        case .stairClimbing:
            return 0.048
        case .surfingSports:
            return 0.048
        case .swimming:
            return 0.048
        case .tableTennis:
            return 0.024
        case .tennis:
            return 0.056
        case .trackAndField:
            return 0.048
        case .traditionalStrengthTraining:
            return 0.024
        case .volleyball:
            return 0.032
        case .walking:
            return 0.036
        case .waterFitness:
            return 0.080
        case .waterPolo:
            return 0.080
        case .waterSports:
            return 0.048
        case .wrestling:
            return 0.048
        case .yoga:
            return 0.032
        case .barre:
            return 0.048
        case .coreTraining:
            return 0.048
        case .crossCountrySkiing:
            return 0.064
        case .downhillSkiing:
            return 0.048
        case .flexibility:
            return 0.032
        case .highIntensityIntervalTraining:
            return 0.064
        case .jumpRope:
            return 0.080
        case .kickboxing:
            return 0.080
        case .pilates:
            return 0.048
        case .snowboarding:
            return 0.048
        case .stairs:
            return 0.048
        case .stepTraining:
            return 0.048
        case .wheelchairWalkPace:
            return 0.048
        case .wheelchairRunPace:
            return 0.052
        case .taiChi:
            return 0.032
        case .mixedCardio:
            return 0.048
        case .handCycling:
            return 0.032
        case .discSports:
            return 0.032
        case .fitnessGaming:
            return 0.024
        case .cardioDance:
            return 0.024
        case .socialDance:
            return 0.044
        case .pickleball:
            return 0.056
        case .cooldown:
            return 0.024
        case .other:
            return 0.024
        @unknown default:
            return 0.024
        }
    }
    
    static let oldAllCases: [HKWorkoutActivityType] = [
            .americanFootball,
            .archery,
            .australianFootball,
            .badminton,
            .barre,
            .baseball,
            .basketball,
            .bowling,
            .boxing,
            .climbing,
            .coreTraining,
            .cricket,
            .crossCountrySkiing,
            .crossTraining,
            .curling,
            .cycling,
            .dance,
            .danceInspiredTraining,
            .discSports,
            .downhillSkiing,
            .elliptical,
            .equestrianSports,
            .fencing,
            .fishing,
            .fitnessGaming,
            .flexibility,
            .functionalStrengthTraining,
            .golf,
            .gymnastics,
            .handCycling,
            .handball,
            .highIntensityIntervalTraining,
            .hiking,
            .hockey,
            .hunting,
            .jumpRope,
            .kickboxing,
            .lacrosse,
            .martialArts,
            .mindAndBody,
            .mixedCardio,
            .other,
            .paddleSports,
            .pilates,
            .play,
            .preparationAndRecovery,
            .racquetball,
            .rowing,
            .rugby,
            .running,
            .sailing,
            .skatingSports,
            .snowSports,
            .snowboarding,
            .soccer,
            .softball,
            .squash,
            .stairClimbing,
            .stairs,
            .stepTraining,
            .surfingSports,
            .swimming,
            .tableTennis,
            .taiChi,
            .tennis,
            .trackAndField,
            .traditionalStrengthTraining,
            .volleyball,
            .walking,
            .waterFitness,
            .waterPolo,
            .waterSports,
            .wheelchairRunPace,
            .wheelchairWalkPace,
            .wrestling,
            .yoga
        ]
    
    @available(iOS 14.0, *)
    static let allCases: [HKWorkoutActivityType] = [
            .americanFootball,
            .archery,
            .australianFootball,
            .badminton,
            .barre,
            .baseball,
            .basketball,
            .bowling,
            .boxing,
            .cardioDance,
            .climbing,
            .cooldown,
            .coreTraining,
            .cricket,
            .crossCountrySkiing,
            .crossTraining,
            .curling,
            .cycling,
            .dance,
            .danceInspiredTraining,
            .discSports,
            .downhillSkiing,
            .elliptical,
            .equestrianSports,
            .fencing,
            .fishing,
            .fitnessGaming,
            .flexibility,
            .functionalStrengthTraining,
            .golf,
            .gymnastics,
            .handCycling,
            .handball,
            .highIntensityIntervalTraining,
            .hiking,
            .hockey,
            .hunting,
            .jumpRope,
            .kickboxing,
            .lacrosse,
            .martialArts,
            .mindAndBody,
            .mixedCardio,
            .other,
            .paddleSports,
            .pickleball,
            .pilates,
            .play,
            .preparationAndRecovery,
            .racquetball,
            .rowing,
            .rugby,
            .running,
            .sailing,
            .skatingSports,
            .snowSports,
            .snowboarding,
            .soccer,
            .socialDance,
            .softball,
            .squash,
            .stairClimbing,
            .stairs,
            .stepTraining,
            .surfingSports,
            .swimming,
            .tableTennis,
            .taiChi,
            .tennis,
            .trackAndField,
            .traditionalStrengthTraining,
            .volleyball,
            .walking,
            .waterFitness,
            .waterPolo,
            .waterSports,
            .wheelchairRunPace,
            .wheelchairWalkPace,
            .wrestling,
            .yoga
        ]
}

public extension HKQuantityTypeIdentifier {
    var name: String {
        switch self {
        case .dietaryFatTotal:             return "Dietary Fat Total"
        case .dietaryEnergyConsumed:       return "Dietary Energy"
        case .dietaryCarbohydrates:        return "Dietary Carbohydrates"
        case .dietaryProtein:              return "Dietary Protein"
        case .dietarySugar:                return "Dietary Sugar"
        // Catch-all
        default:                           return "QuantityTypeIdentifier"
        }
    }
}
