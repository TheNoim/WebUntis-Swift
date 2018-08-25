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

enum LessonType: String, Encodable {
    case Lesson = "ls"
    case OfficeHour = "oh"
    case StandBy = "sb"
    case BreakSupervision = "bs"
    case Examination = "ex"
}

enum Code: String, Encodable {
    case Regular = ""
    case Cancelled = "cancelled"
    case Irregular = "irregular"
}

// Structs

struct Lesson: Encodable {
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
}

struct Klasse: Encodable {
    var id: Int
    var name: String
    var longname: String
}

struct Room: Encodable {
    var id: Int
    var name: String
    var longname: String
}

struct Subject: Encodable {
    var id: Int
    var name: String
    var longname: String
}

struct Teacher: Encodable {
    var id: Int
    var name: String
    var longname: String
}

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}
