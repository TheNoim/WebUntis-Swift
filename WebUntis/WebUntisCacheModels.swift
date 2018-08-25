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
    
    let klassen = List<KlassenRealm>()
    let rooms = List<RoomRealm>()
    let subjects = List<SubjectRealm>()
    let teachers = List<TeacherRealm>()
    
    override static func primaryKey() -> String? {
        return "id"
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
}

// Enums

enum LessonType: String {
    case Lesson = "ls"
    case OfficeHour = "oh"
    case StandBy = "sb"
    case BreakSupervision = "bs"
    case Examination = "ex"
}

enum Code: String {
    case Regular = ""
    case Cancelled = "cancelled"
    case Irregular = "irregular"
}

// Structs

struct Lesson {
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
            "userId": self.userId
        ];
    }
}

struct Klasse {
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

struct Room {
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

struct Subject {
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

struct Teacher {
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
