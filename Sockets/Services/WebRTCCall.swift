//
//  WebRTCCall.swift
//  Sockets
//
//  Created by Maxim on 04/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation

internal class WebRTCCall: NSObject, Call {
    
    internal var identifier = String()
    
    internal var stateChanged: (() -> ())?
    
    internal(set) var peer: Peer? {
        didSet {
            state = (peer != nil) ? .active : .ended

            if let peer = peer {
                identifier = peer.identifier
            } 
        }
    }
    
    internal(set) var state: CallState = .connecting {
        didSet {
            stateChanged?()
        }
    }
    
    var muted: Bool = false {
        didSet {
            if muted != oldValue {
                if muted {
                    peer?.muteAudioIn()
                } else {
                    peer?.unmuteAudioIn()
                }
                
                if state != .ended {
                    state = muted ? .muted : .active
                }
            }
        }
    }
    
    let contact: LiveDesignUser
    
    internal init(contact: LiveDesignUser, peer: Peer? = nil) {
        self.muted = false
        self.peer = peer
        self.contact = contact
    }
    
    func end() {
        peer?.disconnect()
    }
}
