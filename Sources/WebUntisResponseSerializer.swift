//
//  WebUntisResponseSerializer.swift
//  WebUntis iOS
//
//  Created by Nils Bergmann on 07/09/2020.
//  Copyright © 2020 Nils Bergmann. All rights reserved.
//

import Foundation
import Alamofire

func serializeBase(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [String: Any] {
    let json = try JSONResponseSerializer().serialize(request: request, response: response, data: data, error: error);
    
    guard let root = json as? [String: Any] else {
        throw getWebUntisErrorBy(type: .WEBUNTIS_SERVER_ERROR, userInfo: ["response": json]);
    }
    
    if let error = root["error"] as? [String: Any] {
        guard let code = error["code"] as? Int else {
            throw getWebUntisErrorBy(type: .WEBUNTIS_UNKNOWN_ERROR_CODE, userInfo: nil);
        }
        // TODO: Add more error codes
        switch (code) {
        case -8520:
            throw getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil);
        case -8509:
            throw getWebUntisErrorBy(type: .WEBUNTIS_PERMISSION_DENIED, userInfo: nil);
        case -32601:
            throw getWebUntisErrorBy(type: .WEBUNTIS_METHOD_NOT_FOUND, userInfo: nil);
        default:
            print("Root \(root)")
            throw getWebUntisErrorBy(type: .WEBUNTIS_UNKNOWN_ERROR_CODE, userInfo: nil);
        }
    }
    
    return root;
}

struct JSONRPCResponseSerializer: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [String: Any] {
        let root = try serializeBase(request: request, response: response, data: data, error: error);
        
        guard let result = root["result"] as? [String: Any] else {
            throw getWebUntisErrorBy(type: .WEBUNTIS_SERVER_RESPONSE_MISSING_RESULT, userInfo: nil);
        }
        
        return result;
    }
}

struct JSONRPCResponseSerializerArray: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [Any] {
        let root = try serializeBase(request: request, response: response, data: data, error: error);
        
        guard let result = root["result"] as? [Any] else {
            throw getWebUntisErrorBy(type: .WEBUNTIS_SERVER_RESPONSE_MISSING_RESULT, userInfo: nil);
        }
        
        return result;
    }
}
