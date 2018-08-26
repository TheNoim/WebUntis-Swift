//
//  WebUntisValidUser.swift
//  WebUntis
//
//  Created by Nils Bergmann on 23.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation
import RealmSwift

class ValidAccount: Object {
    @objc dynamic var username = ""
    @objc dynamic var server = ""
    @objc dynamic var school = ""
    @objc dynamic var accountHash = ""
    @objc dynamic var type = 0
    @objc dynamic var id = 0
    override static func primaryKey() -> String? {
        return "accountHash"
    }
}
