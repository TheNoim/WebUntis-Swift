//
//  WebUntis.swift
//  WebUntis
//
//  Created by Nils Bergmann on 22.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire
import Promises
import CryptoSwift

func getURLSessionConfiguration() -> URLSessionConfiguration {
    let cfg = URLSessionConfiguration.ephemeral;
    cfg.timeoutIntervalForRequest = 5;
    cfg.timeoutIntervalForResource = 5;
    return cfg;
}

public class WebUntis: RequestAdapter, RequestRetrier {
    
    public static var `default` = WebUntis();
    
    private var credentialsSetAndValid = false;
    
    private var realm: Realm {
        var config = Realm.Configuration();
        config.fileURL = self.realmPath;
        Realm.Configuration.defaultConfiguration = config;
        if let _ = NSClassFromString("XCTest") {
            return try! Realm(configuration: Realm.Configuration(fileURL: nil, inMemoryIdentifier: "test", encryptionKey: nil, readOnly: false, schemaVersion: 0, migrationBlock: nil, objectTypes: nil))
        } else {
            return try! Realm();
        }
    }
    
    // Static
    private let identity = randomString(length: 10);
    private let client = randomString(length: 10);
    
    // Credentials
    private var server = "";
    private var username = "";
    private var password = "";
    private var school = "";
    
    public var type = 5;
    public var id = 0;
    
    public var events = EventManager()
    
    public var refreshAfter = 8; // minutes
    
    private var currentSession = "";
    private var sessionExpiresAt = Date();
    
    private var sessionManager = Alamofire.SessionManager(configuration: getURLSessionConfiguration());
    
    private let lock = NSLock();
    
    private var realmPath = Realm.Configuration().fileURL;
    
    public var webuntisDateFormatter = DateFormatter()
    
    public init(url: URL = Realm.Configuration().fileURL!.deletingLastPathComponent().appendingPathComponent("WebUntis.realm")) {
        sessionManager.adapter = self;
        sessionManager.retrier = self;
        self.realmPath = url;
        webuntisDateFormatter.dateFormat = "YYYYMMdd";
    }
    
    public func setCredentials(server: String, username: String, password: String, school: String) -> Promise<Bool> {
        return Promise<Bool> { fullfill, reject in
            if !self.isAccountConsideredValid(server: server, username: username, password: password, school: school) {
                self.loginWith(server: server, username: username, password: password, school: school).then { (sessionId, type, id) -> Bool in
                    self.server = server;
                    self.username = username;
                    self.password = password;
                    self.school = school;
                    self.currentSession = sessionId;
                    self.type = type;
                    self.id = id;
                    self.sessionExpiresAt = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!;
                    self.credentialsSetAndValid = true;
                    return true;
                }.then {_ in
                    self.markAccountAsValid(server: server, username: username, password: password, school: school);
                    fullfill(true);
                }.catch { error in
                    reject(error);
                }
            } else {
                self.server = server;
                self.username = username;
                self.password = password;
                self.school = school;
                self.credentialsSetAndValid = true;
                fullfill(true);
            }
        };
    }
    
    private func login() -> Promise<(sessionId: String, type: Int, id: Int)> {
        return Promise { fullfill, reject in
            if (!self.credentialsSet()) {
                reject(getWebUntisErrorBy(type: .CREDENTIALS_NOT_SET, userInfo: nil));
                return;
            }
            self.loginWith(server: self.server, username: self.username, password: self.password, school: self.school).then { (sessionId, type, id) in
                fullfill((sessionId : sessionId, type : type, id : id));
            }.catch { error in
                reject(error);
            };
        };
        
    }
    
    private func loginWith(server: String, username: String, password: String, school: String) -> Promise<(sessionId: String, type: Int, id: Int)> {
        return Promise<(sessionId: String, type: Int, id: Int)> { fulfill, reject in
            // Try Login
            let JSONRPCBody: Parameters = [
                "id": self.identity,
                "method": "authenticate",
                "jsonrpc": "2.0",
                "params": [
                    "user": username,
                    "password": password,
                    "client": self.client
                ]
            ];
            Alamofire.request("https://\(server)/WebUntis/jsonrpc.do?school=\(school)", method: .post, parameters: JSONRPCBody, encoding: JSONEncoding.default).responseJSON { response in
                switch response.result {
                case .success:
                    //
                    guard let json = response.result.value as? [String: Any] else {
                        reject(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil));
                        return;
                    }
                    guard let result = json["result"] as? [String: Any] else {
                        reject(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: json));
                        return;
                    }
                    guard let sessionId = result["sessionId"] as? String else {
                        reject(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: json));
                        return;
                    }
                    guard let type = result["personType"] as? Int else {
                        reject(getWebUntisErrorBy(type: .WEBUNTIS_INVALID_PERSON_TYPE, userInfo: json));
                        return;
                    }
                    guard let id = result["personId"] as? Int else {
                        reject(getWebUntisErrorBy(type: .WEBUNTIS_INVALID_PERSON_ID, userInfo: json));
                        return;
                    }
                    print("Login successfully: \(sessionId)");
                    fulfill((sessionId : sessionId, type : type, id : id));
                    break;
                case .failure(let error):
                    reject(getWebUntisErrorBy(type: .UNKNOWN, userInfo: ["error": error]));
                }
            };
        };
    }
    
    private func getTimetableFromCache(between start: Date = Date(), and end: Date = Date()) -> Results<LessonRealm>? {
        return self.realm.objects(LessonRealm.self).filter("userType == %@ AND userId == %@ AND start >= %@ AND start <= %@", type, id, start, end);
    }
    
    public func getTimetable(between start: Date = Date(), and end: Date = Date(), forceRefresh: Bool = false) -> Promise<[Lesson]> {
        return Promise<[Lesson]> { fulfill, reject in
            if let lessonsAsRealm = self.getTimetableFromCache(between: start, and: end), !forceRefresh {
                fulfill(lessonStruct(by: lessonsAsRealm))
                self.refreshTimetable(between: start, and: end).then { _ in
                    print("Finish refresh!")
                };
            } else {
                print("Hello my friend")
                self.refreshTimetable(between: start, and: end, forceRefresh: true).then { lessons in
                    fulfill(lessons);
                }.catch { error in
                    let e = error as NSError;
                    if e.code == NSURLErrorTimedOut, let lessonsAsRealm = self.getTimetableFromCache(between: start, and: end), !forceRefresh {
                        fulfill(lessonStruct(by: lessonsAsRealm))
                    } else {
                        reject(error);
                    }
                };
            }
        };
    }
    
    var lastTimetableRefresh: Date {
        get {
            guard let time = self.realm.object(ofType: RefreshTime.self, forPrimaryKey: "timetable") else {
                return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            };
            return time.date;
        }
        set {
            guard let time = self.realm.object(ofType: RefreshTime.self, forPrimaryKey: "timetable") else {
                try? realm.write {
                    realm.add(RefreshTime(value: [
                        "name": "timetable",
                        "date": newValue
                    ]), update: true)
                }
                return;
            };
            try? realm.write {
                time.date = newValue
            }
        }
    }
    
    var lastTimegridRefresh: Date {
        get {
            guard let time = self.realm.object(ofType: RefreshTime.self, forPrimaryKey: "timegrid") else {
                return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            };
            return time.date;
        }
        set {
            guard let time = self.realm.object(ofType: RefreshTime.self, forPrimaryKey: "timegrid") else {
                try? realm.write {
                    realm.add(RefreshTime(value: [
                        "name": "timetable",
                        "date": newValue
                    ]), update: true)
                }
                return;
            };
            try? realm.write {
                time.date = newValue
            }
        }
    }
    
    private func getTimegridP() -> Promise<[TimegridEntry]> {
        return Promise<[TimegridEntry]> { fulfill, reject in
            self.doJSONRPCArray(method: .TIMEGRID).then { timegridArray in
                var result: [TimegridEntry] = [];
                for dayU in timegridArray {
                    if let dayObject = dayU as? [String: Any], let day = dayObject["day"] as? Int, let units = dayObject["timeUnits"] as? [Any] {
                        let weekDay = WeekDay.untisToWeekDay(day);
                        for unitU in units {
                            if let unit = unitU as? [String: Any], let name = unit["name"] as? String, let startTime = unit["startTime"] as? Int, let endTime = unit["endTime"] as? Int {
                                result.append(TimegridEntry(name: name, weekDay: weekDay, start: startTime, end: endTime, userType: self.type, userId: self.id, custom: false));
                            }
                        }
                    }
                }
                fulfill(result);
            }.catch { error in
                fulfill([]);
            }
        };
        
    }
    
    @discardableResult
    public func refreshTimetable(between start: Date = Date(), and end: Date = Date(), forceRefresh: Bool = false) -> Promise<[Lesson]> {
        return Promise<[Lesson]> { fulfill, reject in
            if forceRefresh || self.lastTimetableRefresh < Calendar.current.date(byAdding: .minute, value: self.refreshAfter * -1, to: Date())! {
                self.doJSONRPCArray(method: .TIMETABLE, params: ["options": [
                    "element": [
                        "id": self.id,
                        "type": self.type
                    ],
                    "startDate": self.webuntisDateFormatter.string(from: start),
                    "endDate": self.webuntisDateFormatter.string(from: end),
                    "showInfo": true,
                    "showSubstText": true,
                    "showLsText": true,
                    "showStudentgroup": true,
                    "klasseFields": ["id", "name", "longname"],
                    "roomFields": ["id", "name", "longname"],
                    "subjectFields": ["id", "name", "longname"],
                    "teacherFields": ["id", "name", "longname"],
                ]]).then { result in
                    var lessons: [Lesson] = [];
                    self.getTimegridP().then { timegridUnits in
                        for lessonU in result {
                            if let lessonO = lessonU as? [String: Any], let dateInt = lessonO["date"] as? Int, let date = self.webuntisDateFormatter.date(from: "\(dateInt)"), let startTime = lessonO["startTime"] as? Int, let endTime = lessonO["endTime"] as? Int, let lesson = Lesson(json: lessonO, userType: self.type, userId: self.id, startGrid: timegridUnits.getUnitOrCreate(for: TimegridEntryType.Start, at: WeekDay.dateToWeekDay(date: date), at: startTime, at: endTime, userType: self.type, userId: self.id), endGrid: timegridUnits.getUnitOrCreate(for: TimegridEntryType.End, at: WeekDay.dateToWeekDay(date: date), at: startTime, at: endTime, userType: self.type, userId: self.id)) {
                                lessons.append(lesson);
                            }
                        }
                        lessons = lessons.sorted(by: { $0.start.compare($1.start) == .orderedAscending });
                        try? self.realm.write {
                            if let startDate = lessons.first?.start, let endDate = lessons.last?.end {
                                let oldData = self.getTimetableFromCache(between: start, and: end);
                                if oldData != nil {
                                    for oldLesson in (oldData?.enumerated())! {
                                        self.realm.delete(oldLesson.element.klassen);
                                        self.realm.delete(oldLesson.element.rooms);
                                        self.realm.delete(oldLesson.element.subjects);
                                        self.realm.delete(oldLesson.element.teachers);
                                    }
                                    self.realm.delete(oldData!);
                                }
                            }
                            for lesson in lessons {
                                self.realm.add(LessonRealm(value: lesson.dictionary), update: true);
                            }
                        }
                        self.lastTimetableRefresh = Date()
                        DispatchQueue.main.sync {
                            self.events.trigger(eventName: "refresh");
                        }
                        fulfill(lessons);
                    }
                }.catch { error in
                    DispatchQueue.main.sync {
                        self.events.trigger(eventName: "error", information: getWebUntisErrorBy(type: .WEBUNTIS_BACKGROUND_REFRESH_ERROR, userInfo: ["error": error]));
                    }
                    fulfill([]);
                }
            } else {
                fulfill([]);
            }
        };
    }
    
    public func doJSONRPC(method: WebUntisMethod, params: [String: Any] = [:]) -> Promise<[String: Any]> {
        return Promise<[String: Any]> { fulfill, reject in
            let JSONRPCBody: Parameters = [
                "id": self.identity,
                "method": method.rawValue,
                "jsonrpc": "2.0",
                "params": params
            ];
            self.sessionManager.request("https://\(self.server)/WebUntis/jsonrpc.do?school=\(self.school)", method: .post, parameters: JSONRPCBody, encoding: JSONEncoding.default).validateWebUntisResponse().responseJSONRPC { response in
                switch response.result {
                case .success:
                    guard let result = response.result.value else {
                        reject(getWebUntisErrorBy(type: .UNKNOWN, userInfo: nil));
                        return;
                    }
                    fulfill(result);
                    break;
                case .failure(let error):
                    reject(error);
                }
            };
        };
    }
    
    public func doJSONRPCArray(method: WebUntisMethod, params: [String: Any] = [:]) -> Promise<[Any]> {
        return Promise<[Any]> { fulfill, reject in
            let JSONRPCBody: Parameters = [
                "id": self.identity,
                "method": method.rawValue,
                "jsonrpc": "2.0",
                "params": params
            ];
            let r = self.sessionManager.request("https://\(self.server)/WebUntis/jsonrpc.do?school=\(self.school)", method: .post, parameters: JSONRPCBody, encoding: JSONEncoding.default).validateWebUntisResponse().responseJSONRPCArray { response in
                switch response.result {
                case .success:
                    guard let result = response.result.value else {
                        reject(getWebUntisErrorBy(type: .UNKNOWN, userInfo: nil));
                        return;
                    }
                    fulfill(result);
                    break;
                case .failure(let error):
                    reject(error);
                }
            };
            debugPrint(r)
        };
    }
    
    private func isSessionNotTimedout() -> Bool {
        if self.sessionExpiresAt > Date() {
            return true;
        }
        return false;
    }
    
    private func credentialsSet() -> Bool {
        return self.credentialsSetAndValid;
    }
    
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if self.isSessionNotTimedout() && self.currentSession != "" {
            var urlRequest = urlRequest;
            urlRequest.setValue("JSESSIONID=\(self.currentSession); Path=/WebUntis; HttpOnly; Domain=\(self.server)", forHTTPHeaderField: "Cookie");
            return urlRequest;
        }
        return urlRequest;
    }
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        self.lock.lock() ; defer { self.lock.unlock() };
        if error.isWebUntisError(type: .UNAUTHORIZED) && self.credentialsSet() {
            requestsToRetry.append(completion);
            self.login().then { [weak self] (sessionId, type, id) in
                guard let strongSelf = self else { return }
                strongSelf.currentSession = sessionId;
                strongSelf.id = id;
                strongSelf.type = type;
                strongSelf.sessionExpiresAt = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!;
                strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                strongSelf.requestsToRetry.forEach { $0(true, 0.0) }
                strongSelf.requestsToRetry.removeAll();
            }.catch { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.invalidateAccount(server: strongSelf.server, username: strongSelf.username, password: strongSelf.password, school: strongSelf.school)
                strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                strongSelf.requestsToRetry.forEach { $0(false, 0.0) }
                strongSelf.requestsToRetry.removeAll();
            };
        } else {
            completion(false, 0.0);
        }
    }
    
    public func isAccountConsideredValid(server: String, username: String, password: String, school: String) -> Bool {
        let hash = accountHash(server: server, username: username, password: password, school: school);
        let validAccount = self.realm.object(ofType: ValidAccount.self, forPrimaryKey: hash);
        return validAccount != nil;
    }
    
    public func markAccountAsValid(server: String, username: String, password: String, school: String) {
        let hash = accountHash(server: server, username: username, password: password, school: school);
        let validAccount = ValidAccount();
        validAccount.accountHash = hash;
        validAccount.school = school;
        validAccount.server = server;
        validAccount.username = username;
        try? realm.write {
            realm.add(validAccount);
        }
    }
    
    public func invalidateAccount(server: String, username: String, password: String, school: String) {
        let hash = accountHash(server: server, username: username, password: password, school: school);
        guard let validAccount = self.realm.object(ofType: ValidAccount.self, forPrimaryKey: hash) else {
            return;
        }
        try? realm.write {
            realm.delete(validAccount);
        }
    }
    
    private func accountHash(server: String, username: String, password: String, school: String) -> String {
        var base: String = server + username + password + school;
        for _ in 0..<64 {
            base = base.sha512();
        }
        return base;
    }
    
    public static func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd";
        return formatter;
    }
    
    public static func getTimeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd HHmm";
        return formatter;
    }
    
    // Src: https://stackoverflow.com/questions/13324633/nsdate-beginning-of-day-and-end-of-day
    public static func startAndEnd(of date : Date) -> (start : Date, end : Date) {
        var startDate = Date()
        var interval : TimeInterval = 0.0
        let _ = Calendar.current.dateInterval(of: .day, start: &startDate, interval: &interval, for: date)
        let endDate = startDate.addingTimeInterval(interval-1)
        return (start : startDate, end : endDate)
    }
}

extension DataRequest {
    
    public func validateWebUntisResponse() -> Self {
        return validate { request,response,data in
            let json = try? JSONSerialization.jsonObject(with: data!, options: []);
            guard let root = json as? [String: Any] else {
                return .failure(getWebUntisErrorBy(type: .WEBUNTIS_SERVER_ERROR, userInfo: nil));
            }
            if let error = root["error"] as? [String: Any] {
                guard let code = error["code"] as? Int else {
                    return .failure(getWebUntisErrorBy(type: .WEBUNTIS_UNKNOWN_ERROR_CODE, userInfo: nil));
                }
                // TODO: Add more error codes
                switch (code) {
                case -8520:
                    return .failure(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil));
                case -8509:
                    return .failure(getWebUntisErrorBy(type: .WEBUNTIS_PERMISSION_DENIED, userInfo: nil));
                case -32601:
                    return .failure(getWebUntisErrorBy(type: .WEBUNTIS_METHOD_NOT_FOUND, userInfo: nil));
                default:
                    return .failure(getWebUntisErrorBy(type: .WEBUNTIS_UNKNOWN_ERROR_CODE, userInfo: nil));
                }
            }
            return .success;
        }
    }
    
    static func jsonRPCResponseSerializer() -> DataResponseSerializer<[String: Any]> {
        return DataResponseSerializer { request, response, data, error in
            let json = try? JSONSerialization.jsonObject(with: data!, options: []);
            guard let root = json as? [String: Any] else {
                return .failure(getWebUntisErrorBy(type: .WEBUNTIS_SERVER_ERROR, userInfo: nil));
            }
            if let result = root["result"] as? [String: Any] {
                return .success(result);
            } else {
                return .failure(getWebUntisErrorBy(type: .WEBUNTIS_SERVER_RESPONSE_MISSING_RESULT, userInfo: nil));
            }
        };
    }
    
    static func jsonRPCResponseSerializerArray() -> DataResponseSerializer<[Any]> {
        return DataResponseSerializer { request, response, data, error in
            let json = try? JSONSerialization.jsonObject(with: data!, options: []);
            guard let root = json as? [String: Any] else {
                return .failure(getWebUntisErrorBy(type: .WEBUNTIS_SERVER_ERROR, userInfo: nil));
            }
            if let result = root["result"] as? [Any] {
                return .success(result);
            } else {
                return .failure(getWebUntisErrorBy(type: .WEBUNTIS_SERVER_RESPONSE_MISSING_RESULT, userInfo: nil));
            }
        };
    }
    
    @discardableResult
    func responseJSONRPC(queue: DispatchQueue? = nil, options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (DataResponse<[String: Any]>) -> Void) -> Self {
        return response(
            queue: queue,
            responseSerializer: DataRequest.jsonRPCResponseSerializer(),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    func responseJSONRPCArray(queue: DispatchQueue? = nil, options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (DataResponse<[Any]>) -> Void) -> Self {
        return response(
            queue: queue,
            responseSerializer: DataRequest.jsonRPCResponseSerializerArray(),
            completionHandler: completionHandler
        )
    }
}

enum TimegridEntryType {
    case Start
    case End
}

extension Array where Element == TimegridEntry {
    func getUnitOrCreate(for type: TimegridEntryType, at day: WeekDay, at startTime: Int, at endTime: Int, userType: Int, userId: Int) -> TimegridEntry {
        for unit in self {
            var isCorrect = false;
            switch(type) {
            case .End:
                if unit.end == endTime {
                    isCorrect = true;
                }
                break;
            case .Start:
                if unit.start == startTime {
                    isCorrect = true;
                }
                break;
            }
            if isCorrect {
                return unit;
            }
        }
        return TimegridEntry(name: "Unknown", weekDay: day, start: startTime, end: endTime, userType: userType, userId: userId, custom: true);
    }
}

func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}
