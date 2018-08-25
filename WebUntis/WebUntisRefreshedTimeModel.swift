//
//  WebUntisRefreshedTime.swift
//  WebUntis
//
//  Created by Nils Bergmann on 25.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation
import RealmSwift

class RefreshTime: Object {
    @objc dynamic var name = ""
    @objc dynamic var date = Date()
    
    override static func primaryKey() -> String? {
        return "name"
    }
}
