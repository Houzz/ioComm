//
//  CallService.swift
//  Sockets
//
//  Created by Maxim on 03/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation

@objc
public protocol CallServiceDelegate: class {
        
    @objc optional func callService(_ service: CallService, didReceiveCall call: Call)
    
    @objc optional func callService(_ service: CallService, didDisconnectCall call: Call)
    
}

@objc
public protocol CallService {
    
    var delegate: CallServiceDelegate? { get set }
    
    /**
     Make a VOIP call.
     */
    func call(toIdentifier identifier: String) -> Call?
    
    /**
     Currently active calls.
     */
    func activeCalls() -> [Call]
    
    /**
     Disconnects the service.
     */
    func disconnect()

    /**
     Starts the service for a given caller id and contact user
     */
    func start(withIdentifier identifier: String)
    
    /**
     Assigns a user to an identifier that is used to call that user.
     */
    func associate(identifier: String, withUser user: LiveDesignUser)
    
    /**
     Registers the call service to use a device token
     */
    func register(voipDeviceToken: String)
    
}


