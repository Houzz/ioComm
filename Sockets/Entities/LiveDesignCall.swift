//
//  Call.swift
//  Sockets
//
//  Created by Maxim on 26/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

@objc public protocol LiveDesignCall {
    
    /**
     UUID of call.
     */
    var uuid: UUID { get }
    
    /**
     Whether the call is muted or not.
     */
    var muted: Bool { get set }
    
}

internal class LiveDesignPeerCall: NSObject, LiveDesignCall {
    
    private let peer: Peer?
    
    let uuid = UUID()
    
    var muted: Bool = false {
        didSet {
            if muted != oldValue {
                if muted {
                    peer?.muteAudioIn()
                } else {
                    peer?.unmuteAudioIn()
                }
            }
        }
    }
    
    internal init(peer: Peer) {
        self.muted = false
        self.peer = peer
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? LiveDesignPeerCall {
            return object.peer == self.peer
        }
        return false
    }
}
