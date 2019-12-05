//
//  WebUntisDecodeable.swift
//  WebUntis
//
//  Created by Nils Bergmann on 24.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation

public extension Lesson {
    init?(json: [String: Any], userType: Int, userId: Int, startGrid: TimegridEntry, endGrid: TimegridEntry) {
        let formatter = WebUntis.getDateFormatter();
        let timeformatter = WebUntis.getTimeDateFormatter();
        
        guard let id = json["id"] as? Int,
            let dateInt = json["date"] as? Int,
            let date = formatter.date(from: "\(dateInt)"),
            let startInt = json["startTime"] as? Int,
            let endInt = json["endTime"] as? Int,
            let start = timeformatter.date(from: "\(dateInt) \(startInt)"),
            let end = timeformatter.date(from: "\(dateInt) \(endInt)"),
            let type = LessonType(rawValue: json["lstype"] as? String ?? "ls"),
            let code = Code(rawValue: json["code"] as? String ?? ""),
            let info = json["info"] as? String ?? "",
            let substitutionText = json["substText"] as? String ?? "",
            let lessonText = json["lstext"] as? String ?? "",
            let studentGroup = json["sg"] as? String ?? "",
            let klassenArray = json["kl"] as? [Any],
            let roomsArray = json["ro"] as? [Any],
            let subjectsArray = json["su"] as? [Any],
            let teachersArray = json["te"] as? [Any] else {
            return nil
        }
        self.id = id;
        self.date = date;
        self.start = start;
        self.end = end;
        self.type = type;
        self.code = code;
        self.info = info;
        self.substitutionText = substitutionText;
        self.lessonText = lessonText;
        self.studentGroup = studentGroup;
        self.teachers = [];
        self.klassen = [];
        self.subjects = [];
        self.rooms = [];
        
        self.userType = userType;
        self.userId = userId;
        
        self.startGrid = startGrid;
        self.endGrid = endGrid;

        for klasseU in klassenArray {
            if let klasseO = klasseU as? [String: Any], let klasse = Klasse(json: klasseO, userType: userType, userId: userId) {
                self.klassen.append(klasse);
            }
        }
        
        for roomU in roomsArray {
            if let roomO = roomU as? [String: Any], let room = Room(json: roomO, userType: userType, userId: userId) {
                self.rooms.append(room);
            }
        }
        
        for teacherU in teachersArray {
            if let teacherO = teacherU as? [String: Any], let teacher = Teacher(json: teacherO, userType: userType, userId: userId) {
                self.teachers.append(teacher);
            }
        }
        
        for subjectU in subjectsArray {
            if let subjectO = subjectU as? [String: Any], let subject = Subject(json: subjectO, userType: userType, userId: userId) {
                self.subjects.append(subject);
            }
        }
    }
}

public extension Klasse {
    init?(json: [String: Any], userType: Int, userId: Int) {
        guard let id = json["id"] as? Int, let name = json["name"] as? String, let longname = json["longname"] as? String else {
            return nil;
        }
        self.id = id;
        self.longname = longname;
        self.name = name;
        
        self.userType = userType;
        self.userId = userId;
    }
}

public extension Room {
    init?(json: [String: Any], userType: Int, userId: Int) {
        guard let id = json["id"] as? Int, let name = json["name"] as? String, let longname = json["longname"] as? String else {
            return nil;
        }
        self.id = id;
        self.longname = longname;
        self.name = name;
        
        self.userType = userType;
        self.userId = userId;
    }
}

public extension Subject {
    init?(json: [String: Any], userType: Int, userId: Int) {
        guard let id = json["id"] as? Int, let name = json["name"] as? String, let longname = json["longname"] as? String else {
            return nil;
        }
        self.id = id;
        self.longname = longname;
        self.name = name;
        
        self.userType = userType;
        self.userId = userId;
        if let backgroundColor = json["backColor"] as? String {
            self.backgroundColor = backgroundColor;
        } else {
            self.backgroundColor = "ffffff"
        }
        if let foregroundColor = json["foreColor"] as? String {
            self.foregroundColor = foregroundColor;
        } else {
            self.foregroundColor = "000000"
        }
    }
}

public extension Teacher {
    init?(json: [String: Any], userType: Int, userId: Int) {
        guard let id = json["id"] as? Int, let name = json["name"] as? String, let longname = json["longname"] as? String else {
            return nil;
        }
        self.id = id;
        self.longname = longname;
        self.name = name;
        
        self.userType = userType;
        self.userId = userId;
    }
}

public extension TimegridEntry {
    init(name: String, weekDay: WeekDay, start: Int, end: Int, userType: Int, userId: Int, custom: Bool = false) {
        let hash = "\(weekDay)\(start)\(end)@\(userType)+\(userId)".sha1();
        let startHash = "\(weekDay)\(start)@\(userType)+\(userId)".sha1();
        let endHash = "\(weekDay)\(end)@\(userType)+\(userId)".sha1();
        
        self.custom = custom;
        self.day = weekDay;
        self.end = end;
        self.start = start;
        self.endHash = endHash;
        self.startHash = startHash;
        self.timeHash = hash;
        self.userId = userId;
        self.userType = userType;
        self.name = name;
    }
}
