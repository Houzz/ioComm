//
//  Session.swift
//  SocketIO POC
//
//  Created by Maxim on 11/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

open class LiveDesignSession: NSObject {
    
    public var status: String?      
    public var identifier: String
    public var sketchID: String?
    public var galleryID: String?
    public var user: LiveDesignUser?
    public var representative: LiveDesignUser?
    
    public required init(payload: [String : Any]) {
        status                  = payload["Status"] as! String?
        identifier              = payload["Id"] as! String
        galleryID               = payload["GalleryId"] as! String?
        sketchID                = payload["SketchId"] as! String?

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
        dictionary.safe(set: galleryID, for: "GalleryId")
        dictionary.safe(set: sketchID, for: "SketchId")
        
        dictionary.safe(set: user?.dictionary(), for: "User")
        dictionary.safe(set: representative?.dictionary(), for: "RepUser")
        
        return dictionary
    }

}
