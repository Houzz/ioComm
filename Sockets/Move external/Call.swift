//
//  Call.swift
//  Sockets
//
//  Created by Maxim on 26/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

@objc public enum CallState: Int {
    case connecting
    case active
    case muted
    case ended
}

@objc public protocol Call {
    
    /**
     State of call.
     */
    var state: CallState { get }
    
    /**
     Called when call state is changed.
     */
    var stateChanged: (() -> ())? { get set }
    
    /**
     Identifier of call.
     */
    var uuid: UUID { get }
    
    /**
     Whether the call is muted or not.
     */
    var muted: Bool { get set }
    
    /**
     User who initiated the call.
     */
    var contact: LiveDesignUser { get }
    
    /**
     Ends call.
     */
    func end()
    
}

