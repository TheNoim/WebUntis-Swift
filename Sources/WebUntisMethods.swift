//
//  WebUntisMethods.swift
//  WebUntis
//
//  Created by Nils Bergmann on 23.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation

public enum WebUntisMethod: String {
    case AUTHENTICATE = "authenticate";
    case STATUS = "getStatusData";
    case TIMETABLE = "getTimetable";
    case TIMEGRID = "getTimegridUnits";
    case SUBJECTS = "getSubjects";
}
