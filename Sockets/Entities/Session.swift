//
//  Session.swift
//  SocketIO POC
//
//  Created by Maxim on 11/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

public class Session: NSObject {
    
    public class User: NSObject {
        public let displayName: String?
        public let username: String?
        public let profileImage: URL?
        
        public init(displayName: String?, username: String?, profileImage: URL?) {
            self.displayName = displayName
            self.username = username
            self.profileImage = profileImage
        }
        
        fileprivate init(payload: [String : Any]) {
            displayName     = payload["UserDisplayName"] as! String?
            username        = payload["UserName"] as! String?
            
            if let url = payload["ProfileImage"] as? String {
                profileImage = URL(string: url)
            } else {
                profileImage = nil
            }
        }
        
        fileprivate convenience init?(payload: Any?) {
            if let contents = payload as? [String : Any] {
                self.init(payload: contents)
            } else {
                return nil
            }
        }
        
        internal func dictionary() -> [String : Any] {
            var dictionary = [String : Any]()
            
            dictionary.safe(set: displayName, for: "UserDisplayName")
            dictionary.safe(set: username, for: "UserName")
            dictionary.safe(set: profileImage?.absoluteString, for: "ProfileImage")
            
            return dictionary
        }

    }
    
    
    public var status: String?
    public var identifier: String
    public var userClientID: String?
    public var repClientID: String?
    public var user: Session.User?
    public var representative: Session.User?
    
    public required init(payload: [String : Any]) {
        status                  = payload["Status"] as! String?
        identifier              = payload["Id"] as! String
        userClientID            = payload["UserClientId"] as! String?
        repClientID             = payload["RepClientId"] as! String?
        
        user            = Session.User(payload: payload["User"])
        representative  = Session.User(payload: payload["RepUser"])
        
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

extension Dictionary {
    
    mutating func safe(set object: Value?, for key: Key) {
        if let object = object {
            self[key] = object
        }
    }
    
}
