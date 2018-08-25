//
//  WebUntisErrors.swift
//  WebUntis
//
//  Created by Nils Bergmann on 23.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import Foundation

enum WebUntisError: Int {
    case UNKNOWN = 500;
    case UNAUTHORIZED = 401;
    case CREDENTIALS_NOT_SET = 402;
    case WEBUNTIS_SERVER_ERROR = 501;
    case WEBUNTIS_SERVER_RESPONSE_MISSING_RESULT = 502;
    case WEBUNTIS_UNKNOWN_ERROR_CODE = 503;
    case WEBUNTIS_INVALID_PERSON_TYPE = 504;
    case WEBUNTIS_INVALID_PERSON_ID = 505;
    case WEBUNTIS_PERMISSION_DENIED = 403;
    case WEBUNTIS_METHOD_NOT_FOUND;
}

func getWebUntisErrorBy(type: WebUntisError, userInfo: [String: Any]?) -> NSError {
    return NSError(domain: "com.webuntis", code: type.rawValue, userInfo: userInfo);
}

extension Error {
    func isWebUntisError(type: WebUntisError) -> Bool {
        let error = self as NSError;
        if error.domain == "com.webuntis" && error.code == type.rawValue {
            return true;
        }
        return false;
    }
}
