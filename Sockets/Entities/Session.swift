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
    public var userClientID: String?
    public var repClientID: String?
    public var user: User?
    public var representative: User?
    
    public required init(payload: [String : Any]) {
        status                  = payload["Status"] as! String?
        identifier              = payload["Id"] as! String
        userClientID            = payload["UserClientId"] as! String?
        repClientID             = payload["RepClientId"] as! String?
        
        user                    = User(payload: payload["User"])
        representative          = User(payload: payload["RepUser"])
        
        super.init()
    }
    
    internal convenience init?(payload: [Any]) {
        if let contents = payload[0] as? [String : Any] {
            self.init(payload: contents)
        } else {
            return nil
        }
    }
    
    internal func dictionary() -> [String : Any] {
        
        var dictionary = [String : Any]()
        
        dictionary.safe(set: identifier, for: "Id")
        dictionary.safe(set: status, for: "Status")
        dictionary.safe(set: userClientID, for: "UserClientId")
        dictionary.safe(set: repClientID, for: "RepClientId")
        
        dictionary.safe(set: user?.dictionary(), for: "User")
        dictionary.safe(set: representative?.dictionary(), for: "RepUser")
        
        return dictionary
    }

}
