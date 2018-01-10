//
//  WebRTCCall.swift
//  Sockets
//
//  Created by Maxim on 04/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation

internal class WebRTCCall: NSObject, Call {
    
    /**
     UUID is kept until a peer is introduced, and then we use it's uuid.
     This is because peer takes initial UUID of call once its allocated.
     A call can later be instantiated and have a random UUID - but since they represent
     a peer we will take it's uuid.
     */
    internal var uuid = UUID()
    
    internal var stateChanged: (() -> ())?
    
    internal(set) var peer: Peer? {
        didSet {
            state = (peer != nil) ? .active : .ended
            
            if let peerUUID = peer?.uuid {
                uuid = peerUUID
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
