//
//  CallService.swift
//  Sockets
//
//  Created by Maxim on 03/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation

@objc
public enum CallServiceState: Int {
    case online
    case offline
    case connecting
}

@objc
public protocol CallServiceDelegate: class {
    
    @objc optional func callService(_ service: CallService, didChangeState state: CallServiceState)
    
    @objc optional func callService(_ service: CallService, didReceiveCall call: Call)
    
    @objc optional func callService(_ service: CallService, didDisconnectCall call: Call)
    
}

@objc
public protocol CallService {
    
    var delegate: CallServiceDelegate? { get set }

    /**
     Current state of call service.
     */
    var state: CallServiceState { get }
    
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
    
}

@objc
public protocol ConfigurableCallService : CallService {
    
    /**
     Starts the service for a given caller id and contact user
     */
    func start(withIdentifier identifier: String)
    
    /**
     Registers a user to an identifier that is used to call that user.
     */
    func associate(identifier: String, withUser user: LiveDesignUser)
    
}

