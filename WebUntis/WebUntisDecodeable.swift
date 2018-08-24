//
//  WebUntisDecodeable.swift
//  WebUntis
//
//  Created by Nils Bergmann on 24.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation

extension Lesson: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case id, date, code, info
        case type = "lstype"
        case start = "startDate"
        case end = "endDate"
        case substitutionText = "substText"
        case lessonText = "lstext"
        case studentGroup = "sg"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try! container.decode(Int, forKey: .id)
        
    }
}
