//
//  WebUntisCacheModels.swift
//  WebUntis
//
//  Created by Nils Bergmann on 24.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation
import RealmSwift

// Realm models

class LessonRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var date = Date()
    @objc dynamic var start = Date()
    @objc dynamic var end = Date()
    @objc dynamic var type = "" // LessonType
    @objc dynamic var code = "" // Code
    @objc dynamic var info = ""
    @objc dynamic var substitutionText = ""
    @objc dynamic var lessonText = ""
    @objc dynamic var studentGroup = ""
    @objc dynamic var userType = 0
    @objc dynamic var userId = 0
    
    @objc dynamic var startGrid: TimegridRealm?
    @objc dynamic var endGrid: TimegridRealm?
    
    let klassen = List<KlassenRealm>()
    let rooms = List<RoomRealm>()
    let subjects = List<SubjectRealm>()
    let teachers = List<TeacherRealm>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["start", "end", "userType", "userId"]
    }
}

class KlassenRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    @objc dynamic var longname = ""
    @objc dynamic var userType = 0
    @objc dynamic var userId = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["userType", "userId"]
    }
}

class RoomRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    @objc dynamic var longname = ""
    @objc dynamic var userType = 0
    @objc dynamic var userId = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["userType", "userId"]
    }
}

class SubjectRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    @objc dynamic var longname = ""
    @objc dynamic var userType = 0
    @objc dynamic var userId = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["userType", "userId"]
    }
}

class TeacherRealm: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    @objc dynamic var longname = ""
    @objc dynamic var userType = 0
    @objc dynamic var userId = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["userType", "userId"]
    }
}

class TimegridRealm: Object {
    @objc dynamic var name = ""
    @objc dynamic var day = 0
    @objc dynamic var start = 0
    @objc dynamic var end = 0
    @objc dynamic var custom = true
    
    @objc dynamic var startHash = ""
    @objc dynamic var endHash = ""
    
    @objc dynamic var timeHash = ""
    
    override static func primaryKey() -> String? {
        return "timeHash"
    }
    
    override static func indexedProperties() -> [String] {
        return ["startHash", "endHash"]
    }
}

// Enums

public enum LessonType: String {
    case Lesson = "ls"
    case OfficeHour = "oh"
    case StandBy = "sb"
    case BreakSupervision = "bs"
    case Examination = "ex"
}

public enum Code: String {
    case Regular = ""
    case Cancelled = "cancelled"
    case Irregular = "irregular"
}

// Structs

public struct Lesson {
    var id: Int
    var date: Date
    var start: Date
    var end: Date
    var type: LessonType
    var code: Code
    var info: String
    var substitutionText: String
    var lessonText: String
    var studentGroup: String
    var klassen: [Klasse]
    var rooms: [Room]
    var subjects: [Subject]
    var teachers: [Teacher]
    
    var userType: Int
    var userId: Int
    
    var startGrid: TimegridEntry
    var endGrid: TimegridEntry
    
    var dictionary: [String : Any] {
        var klassen: [[String: Any]] = [];
        var rooms: [[String: Any]] = [];
        var subjects: [[String: Any]] = [];
        var teachers: [[String: Any]] = [];
        for k in self.klassen {
            klassen.append(k.dictionary);
        }
        for r in self.rooms {
            rooms.append(r.dictionary);
        }
        for s in self.subjects {
            subjects.append(s.dictionary)
        }
        for t in self.teachers {
            teachers.append(t.dictionary)
        }
        
        return [
            "id": self.id,
            "date": self.date,
            "start": self.start,
            "end": self.end,
            "type": self.type.rawValue,
            "code": self.code.rawValue,
            "info": self.info,
            "substitutionText": self.substitutionText,
            "lessonText": self.lessonText,
            "studentGroup": self.studentGroup,
            "klassen": klassen,
            "rooms": rooms,
            "subjects": subjects,
            "teachers": teachers,
            "userType": self.userType,
            "userId": self.userId,
            "startGrid": self.startGrid.dictionary,
            "endGrid": self.endGrid.dictionary
        ];
    }
}

public struct Klasse {
    var id: Int
    var name: String
    var longname: String
    
    var userType: Int
    var userId: Int
    
    var dictionary: [String : Any] {
        return [
            "name": self.name,
            "longname": self.longname,
            "id": self.id,
            "userType": self.userType,
            "userId": self.userId
        ];
    }
}

public struct Room {
    var id: Int
    var name: String
    var longname: String
    
    var userType: Int
    var userId: Int
    
    var dictionary: [String : Any] {
        return [
            "name": self.name,
            "longname": self.longname,
            "id": self.id,
            "userType": self.userType,
            "userId": self.userId
        ];
    }
}

public struct Subject {
    var id: Int
    var name: String
    var longname: String
    
    var userType: Int
    var userId: Int
    
    var dictionary: [String : Any] {
        return [
            "name": self.name,
            "longname": self.longname,
            "id": self.id,
            "userType": self.userType,
            "userId": self.userId
        ];
    }
}

public struct Teacher {
    var id: Int
    var name: String
    var longname: String
    
    var userType: Int
    var userId: Int
    
    var dictionary: [String : Any] {
        return [
            "name": self.name,
            "longname": self.longname,
            "id": self.id,
            "userType": self.userType,
            "userId": self.userId
        ];
    }
}

public struct TimegridEntry {
    var name: String
    var day: WeekDay
    var start: Int
    var end: Int
    var custom: Bool
    
    var startHash: String
    var endHash: String
    var timeHash: String
    
    var userType: Int
    var userId: Int
    
    var dictionary: [String : Any] {
        return [
            "name": self.name,
            "start": self.start,
            "end": self.end,
            "custom": self.custom,
            "startHash": self.startHash,
            "endHash": self.endHash,
            "timeHash": self.timeHash,
            "day": self.day.rawValue,
            "userType": self.userType,
            "userId": self.userId
        ];
    }
}
