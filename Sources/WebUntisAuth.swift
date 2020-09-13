//
//  WebUntisAuth.swift
//  WebUntis iOS
//
//  Created by Nils Bergmann on 07/09/2020.
//  Copyright © 2020 Nils Bergmann. All rights reserved.
//

import Foundation
import Alamofire

struct WebUntisLogin: AuthenticationCredential {
    let username: String;
    let password: String;
    let expiration: Date;
    var session: String;
    let server: String;
    let school: String;
    let client: String;
    let identity: String;
    
    var id: Int?;
    var type: Int?;
    
    var requiresRefresh: Bool { expiration < Date() }
}

class WebUntisAuth: Authenticator {
    func refresh(_ credential: WebUntisLogin, for session: Session, completion: @escaping (Result<WebUntisLogin, Error>) -> Void) {
        // Try Login
        let JSONRPCBody: Parameters = [
            "id": credential.identity,
            "method": "authenticate",
            "jsonrpc": "2.0",
            "params": [
                "user": credential.username,
                "password": credential.password,
                "client": credential.client
            ]
        ];
        session.request("https://\(credential.server)/WebUntis/jsonrpc.do?school=\(credential.school)", method: .post, parameters: JSONRPCBody, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success:
                guard let json = try? response.result.get() as? [String: Any] else {
                    completion(.failure(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil)))
                    return;
                }
                guard let result = json["result"] as? [String: Any] else {
                    completion(.failure(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: json)));
                    return;
                }
                guard let sessionId = result["sessionId"] as? String else {
                    completion(.failure(getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: json)));
                    return;
                }
                guard let type = result["personType"] as? Int else {
                    completion(.failure(getWebUntisErrorBy(type: .WEBUNTIS_INVALID_PERSON_TYPE, userInfo: json)));
                    return;
                }
                guard let id = result["personId"] as? Int else {
                    completion(.failure(getWebUntisErrorBy(type: .WEBUNTIS_INVALID_PERSON_ID, userInfo: json)));
                    return;
                }
                print("Login successfully: \(sessionId)");
                var newCredentials = credential;
                newCredentials.session = sessionId;
                newCredentials.type = type;
                newCredentials.id = id;
                completion(.success(credential));
                break;
            case .failure(let error):
                completion(.failure(getWebUntisErrorBy(type: .UNKNOWN, userInfo: ["error": error])));
            }
        };
    }
    
    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool {
        // If authentication server CANNOT invalidate credentials, return `false`
        return false
    }
    
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: WebUntisLogin) -> Bool {
        // If authentication server CANNOT invalidate credentials, return `true`
        return true
    }
    
    func apply(_ credential: WebUntisLogin, to urlRequest: inout URLRequest) {
        urlRequest.setValue("JSESSIONID=\(credential.session); Path=/WebUntis; HttpOnly; Domain=\(credential.server)", forHTTPHeaderField: "Cookie");
    }
}
