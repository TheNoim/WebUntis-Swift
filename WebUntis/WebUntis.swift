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

class WebUntis: RequestAdapter, RequestRetrier {
    
    static var `default` = WebUntis();
    
    private var credentialsSetAndValid = false;
    
    private var realm: Realm?;
    
    // Static
    private let identity = randomString(length: 10);
    private let client = randomString(length: 10);
    
    // Credentials
    private var server = "";
    private var username = "";
    private var password = "";
    private var school = "";
    
    private var currentSession = "";
    private var sessionExpiresAt = Date();
    
    private var sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.ephemeral);
    
    private let lock = NSLock();
    
    init() {
        sessionManager.adapter = self;
        sessionManager.retrier = self;
        var config = Realm.Configuration();
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("WebUntis.realm");
        Realm.Configuration.defaultConfiguration = config;
        self.realm = try! Realm();
    }
    
    public func setCredentials(server: String, username: String, password: String, school: String) -> Promise<Bool> {
        return loginWith(server: server, username: username, password: password, school: school).then { (sessionId) -> Bool in
            self.server = server;
            self.username = username;
            self.password = password;
            self.school = school;
            self.currentSession = sessionId;
            self.sessionExpiresAt = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!;
            self.credentialsSetAndValid = true;
            return true;
        }
    }
    
    private func login() -> Promise<String> {
        return Promise { fullfill, reject in
            if (!self.credentialsSet()) {
                reject(getWebUntisErrorBy(type: .CREDENTIALS_NOT_SET, userInfo: nil));
                return;
            }
            self.loginWith(server: self.server, username: self.username, password: self.password, school: self.school).then { sessionId in
                fullfill(sessionId);
            }.catch { error in
                reject(error);
            };
        };
        
    }
    
    private func loginWith(server: String, username: String, password: String, school: String) -> Promise<String> {
        return Promise<String> { fulfill, reject in
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
                        reject(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil));
                        return;
                    }
                    guard let sessionId = result["sessionId"] as? String else {
                        reject(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil));
                        return;
                    }
                    print("Login successfully: \(sessionId)");
                    fulfill(sessionId);
                    break;
                case .failure(let error):
                    reject(getWebUntisErrorBy(type: .UNKNOWN, userInfo: ["error": error]));
                }
            };
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
            self.sessionManager.request("https://\(self.server)/WebUntis/jsonrpc.do?school=\(self.school)", method: .post, parameters: JSONRPCBody, encoding: JSONEncoding.default).responseJSONRPC { response in
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
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if self.isSessionNotTimedout() && self.currentSession != "" {
            var urlRequest = urlRequest;
            urlRequest.setValue("JSESSIONID=\(self.currentSession); Path=/WebUntis; HttpOnly; Domain=\(self.server)", forHTTPHeaderField: "Cookie");
            return urlRequest;
        }
        return urlRequest;
    }
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        self.lock.lock() ; defer { self.lock.unlock() };
        if error.isWebUntisError(type: .UNAUTHORIZED) && self.credentialsSet() {
            requestsToRetry.append(completion);
            self.login().then { [weak self] sessionId in
                guard let strongSelf = self else { return }
                strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                strongSelf.requestsToRetry.forEach { $0(true, 0.0) }
                strongSelf.requestsToRetry.removeAll();
            }.catch { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                strongSelf.requestsToRetry.forEach { $0(false, 0.0) }
                strongSelf.requestsToRetry.removeAll();
            };
        } else {
            completion(false, 0.0);
        }
    }
    
}

extension DataRequest {
    static func jsonRPCResponseSerializer() -> DataResponseSerializer<[String: Any]> {
        return DataResponseSerializer { request, response, data, error in
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
                default:
                    return .failure(getWebUntisErrorBy(type: .WEBUNTIS_UNKNOWN_ERROR_CODE, userInfo: nil));
                }
            }
            if let result = root["result"] as? [String: Any] {
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
