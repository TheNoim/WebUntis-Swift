//
//  RealmStructConverter.swift
//  WebUntis
//
//  Created by Nils Bergmann on 24.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation
import RealmSwift

func lessonStruct(by lessonsAsRealm: Results<LessonRealm>) -> [Lesson] {
    var lessons: [Lesson] = [];
    for lesson in lessonsAsRealm.enumerated() {
        let element = lesson.element;
        
        var klassen: [Klasse] = [];
        var rooms: [Room] = [];
        var subjects: [Subject] = [];
        var teachers: [Teacher] = [];
        
        for klasse in element.klassen.enumerated() {
            klassen.append(Klasse(id: klasse.element.id, name: klasse.element.name, longname: klasse.element.longname, userType: klasse.element.userType, userId: klasse.element.userId));
        }
        for room in element.rooms.enumerated() {
            rooms.append(Room(id: room.element.id, name: room.element.name, longname: room.element.longname, userType: room.element.userType, userId: room.element.userId));
        }
        for subject in element.subjects.enumerated() {
            subjects.append(Subject(id: subject.element.id, name: subject.element.name, longname: subject.element.longname, userType: subject.element.userType, userId: subject.element.userId));
        }
        for teacher in element.teachers.enumerated() {
            teachers.append(Teacher(id: teacher.element.id, name: teacher.element.name, longname: teacher.element.longname, userType: teacher.element.userType, userId: teacher.element.userId));
        }
        
        lessons.append(Lesson(id: element.id, date: element.date, start: element.start, end: element.end, type: LessonType(rawValue: element.type)!, code: Code(rawValue: element.code)!, info: element.info, substitutionText: element.substitutionText, lessonText: element.lessonText, studentGroup: element.studentGroup, klassen: klassen, rooms: rooms, subjects: subjects, teachers: teachers, userType: lesson.element.userType, userId: lesson.element.userId));
    }
    return lessons;
}
