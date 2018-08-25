//
//  DayOrder.swift
//  WebUntis
//
//  Created by Nils Bergmann on 25.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation

enum WeekDay: Int {
    case Monday = 0
    case Tuesday = 1
    case Wednesday = 2
    case Thursday = 3
    case Friday = 4
    case Saturday = 5
    case Sunday = 6

    static func untisToWeekDay(_ untisDay: Int) -> WeekDay {
        if untisDay == 1 {
            return .Sunday
        }
        return WeekDay(rawValue: untisDay - 2) ?? .Monday
    }
    
    static func dateToWeekDay(date: Date) -> WeekDay {
        let weekd = Calendar.current.component(.weekday, from: date);
        if weekd == 1 {
            return .Sunday
        }
        return WeekDay(rawValue: weekd - 2) ?? .Monday
    }
}
