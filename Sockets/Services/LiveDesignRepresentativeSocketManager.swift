//
//  LiveDesignRepresentativeSocket.swift
//  SocketIO POC
//
//  Created by Maxim on 11/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation
import SocketIO

public protocol LiveDesignRepresentativeSocketDelegate : class {
    
    func liveDesignRepresentativeSocketDidRequestRefreshSessionList(_ socket: LiveDesignRepresentativeSocketProtocol)
    
    func liveDesignRepresentativeSocket(_ socket: LiveDesignRepresentativeSocketProtocol, wasClosedDueTo reason: SocketServiceReason)

}

public protocol LiveDesignRepresentativeSocketProtocol {

    var delegate: LiveDesignRepresentativeSocketDelegate? { get set }

    /**
     Returns active claimed sessions.
     (remove if singelton is removed).
     */
    func claimedSessions() -> [LiveDesignRepresentativeClaimedSessionSocketProtocol]
    
    /**
     Joins the current rep to the “livedesign” room.
     This will register the rep to receive “livedesign.refresh” when new sessions are available.
     
     In case socket is not connected the function will initiate connection.
     */
    func join()
    
    /**
     Claims a livedesign session.
     If session id is null, returns one of the available sessions.
     
     In case socket is not connected the function will initiate connection.
     */
    func claim(session: Session?, with representative: User, completion: @escaping (LiveDesignRepresentativeClaimedSessionSocketProtocol?)->())

}

internal class LiveDesignRepresentativeSocketManager: LiveDesignRepresentativeSocketProtocol {
    
    weak var delegate: LiveDesignRepresentativeSocketDelegate?

    let socket: SocketIOClient
    let onClose: ((LiveDesignRepresentativeSocketProtocol)->())?    // remove if singelton removed

    var rtcClient: WebRTCClient?
    var activeSessions = Set<LiveDesignRepresentativeClaimedSessionSocketManager>()
    
    required init(socket: SocketIOClient, onClose: ((LiveDesignRepresentativeSocketProtocol)->())? = nil) {
        self.socket = socket
        self.rtcClient = WebRTCClient(webRTCClient: nil, socket: socket)
        self.onClose = onClose
        registerCallbacks()
    }
    
    // Mark: LiveDesignRepresentativeSocketProtocol
    
    func claimedSessions() -> [LiveDesignRepresentativeClaimedSessionSocketProtocol] {
        return Array(activeSessions)
    }
    
    func join() {
        socket.emit("livedesign.join")
    }
    
    func claim(session: Session?, with representative: User, completion: @escaping (LiveDesignRepresentativeClaimedSessionSocketProtocol?)->()) {
        socket.emitWithAck("session.claim", session?.identifier ?? "<null>", representative.dictionary()).timingOut(after: 10) { [weak self] payload in
            
            if let contents = payload[0] as? [String : Any], let socket = self?.socket, let rtcClient = self?.rtcClient {
                let session = Session(payload: contents)
                let claimedSession = LiveDesignRepresentativeClaimedSessionSocketManager(socket: socket, rtcClient: rtcClient, session: session, onClose: { manager in
                    self?.activeSessions.remove(manager)
                })
                self?.activeSessions.insert(claimedSession)
                completion(claimedSession)
            } else {
                completion(nil)
            }
            
        }
    }
    
    // Mark: Private
    
    private func registerCallbacks() {
        socket.on("livedesign.refresh") { [weak self] (_, _) in
            self?.refreshed()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.closed(reason: SocketServiceReason.disconnect)
        }
    }
    
    private func refreshed() {
        delegate?.liveDesignRepresentativeSocketDidRequestRefreshSessionList(self)
    }
    
    private func closed(reason: SocketServiceReason) {
        self.onClose?(self)
        delegate?.liveDesignRepresentativeSocket(self, wasClosedDueTo: reason)
    }
    
}
