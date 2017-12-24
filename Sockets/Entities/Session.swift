//
//  Session.swift
//  SocketIO POC
//
//  Created by Maxim on 11/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

public class Session: NSObject {
    
    public var status: String?
    public var identifier: String
    public var representativeUsername: String?
    public var username: String?
    public var userClientID: String?
    public var repClientID: String?
    
    public required init(payload: [String:Any]) {
        status                  = payload["Status"] as! String?
        identifier              = payload["Id"] as! String
//        representativeUsername  = payload["RepUsername"] as! String?
        username                = payload["Username"] as! String?
        userClientID            = payload["UserClientId"] as! String?
        repClientID             = payload["RepClientId"] as! String?
        
        super.init()
    }
    
    public convenience init?(payload: [Any]) {
        if let contents = payload[0] as? [String : Any] {
            self.init(payload: contents)
        } else {
            return nil
        }
    }
    
    func dictionary() -> [String : Any] {
        
        var dictionary = [String : Any]()
        
        dictionary.safe(set: username, for: "Username")
        dictionary.safe(set: identifier, for: "Id")
        dictionary.safe(set: representativeUsername, for: "representativeUsername")
        dictionary.safe(set: status, for: "Status")
        dictionary.safe(set: userClientID, for: "UserClientId")
        dictionary.safe(set: repClientID, for: "RepClientId")

        return dictionary
    }

}

extension Dictionary {
    
    mutating func safe(set object: Value?, for key: Key) {
        if let object = object {
            self[key] = object
        }
    }
    
}
