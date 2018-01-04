//
//  User.swift
//  Sockets
//
//  Created by Maxim on 26/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

open class LiveDesignUser: NSObject {
    
    public let displayName: String?
    public let username: String?
    public let profileImage: URL?   
    
    public init(displayName: String?, username: String?, profileImage: URL?) {
        self.displayName = displayName
        self.username = username
        self.profileImage = profileImage
    }
    
    internal init(payload: [String : Any]) {
        displayName     = payload["UserDisplayName"] as! String?
        username        = payload["UserName"] as! String?
        
        if let url = payload["ProfileImage"] as? String {
            profileImage = URL(string: url)
        } else {
            profileImage = nil
        }
    }
    
    internal convenience init?(payload: Any?) {
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

