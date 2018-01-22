//
//  Session.swift
//  SocketIO POC
//
//  Created by Maxim on 11/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

open class LiveDesignSession: NSObject {
    
//    enum Status {
//        case waiting    // Waiting
//    }
    
    private(set) public var status: String? // change to enum
    private(set) public var identifier: String
    private(set) public var userClientID: String?
    private(set) public var repClientID: String?
    private(set) public var sketchID: String?
    private(set) public var galleryID: String?
    private(set) public var productID: String?
    private(set) public var allowsUserInteraction: Bool
    private(set) public var user: LiveDesignUser?
    private(set) public var representative: LiveDesignUser?
    
    public required init(payload: [String : Any]) {
        status                  = payload["Status"] as! String?
        identifier              = payload["Id"] as! String
        userClientID            = payload["UserClientId"] as! String?
        repClientID             = payload["RepClientId"] as! String?
        galleryID               = payload["GalleryId"] as! String?
        sketchID                = payload["SketchId"] as! String?
        productID               = payload["SpaceId"] as! String?

        allowsUserInteraction   =  (payload["AllowUserInteraction"] as! String) == "true"
        
        user                    = LiveDesignUser(payload: payload["User"])
        representative          = LiveDesignUser(payload: payload["RepUser"])
        
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
        dictionary.safe(set: galleryID, for: "GalleryId")
        dictionary.safe(set: sketchID, for: "SketchId")
        
        dictionary.safe(set: user?.dictionary(), for: "User")
        dictionary.safe(set: representative?.dictionary(), for: "RepUser")
        
        return dictionary
    }
    
}

public extension LiveDesignSession {
    
    public func set(galleryID: String, sketchID: String) {
        self.galleryID = galleryID
        self.sketchID = sketchID
    }
    
}
