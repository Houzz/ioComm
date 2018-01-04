//
//  SocketsCallService.swift
//  Sockets
//
//  Created by Maxim on 04/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import SocketIO

/**
 Needs to be instantiated with an active socket.
 */
internal class WebRTCCallService: NSObject, ConfigurableCallService {
    
    public weak var delegate: CallServiceDelegate?
    
    private var rtcClient: WebRTCClient?
    private var peerCalls = [WebRTCCall]()
    private var associations = [String : LiveDesignUser]()
    
    internal var state = CallServiceState.offline {
        didSet { delegate?.callService?(self, didChangeState: state) }
    }
    
    init(socketService: SocketService) {
        super.init()
        
        // register for socket updates
        let socketClosure: (SocketIOClient?)->() = { [weak self] socket in
            if let socket = socket {
                self?.attach(socket: socket)
            } else {
                self?.detach()
            }
        }
        
        socketService.onSocketChange = socketClosure
        
        // update for current socket
        socketClosure(socketService.socket)
    }
    
    /**
     Make a VOIP call.
     */
    func call(toIdentifier identifier: String) -> Call? {
        guard
            let rtcClient = rtcClient,
            let contact = user(forIdentifier: identifier)
            else { return nil }
        
        let call = WebRTCCall(contact: contact)
        peerCalls.append(call)
        
        rtcClient.makeCall(withIdentifier: identifier, completion: { [weak call] (peer) in
            guard let call = call else {
                peer?.disconnect()  // nothing to manage the peer
                return
            }
            
            call.peer = peer
        })
        
        return call
    }
    
    func activeCalls() -> [Call] {
        return peerCalls
    }
    
    internal func attach(socket: SocketIOClient) {
        guard self.rtcClient == nil else { return }
        self.rtcClient = WebRTCClient(webRTCClient: self, socket: socket)
        delegate?.callService?(self, didChangeState: .connecting)
    }
    
    internal func detach() {
        disconnect()
        self.rtcClient = nil
        delegate?.callService?(self, didChangeState: .offline)
    }
    
    internal func start(withIdentifier identifier: String) {
        self.rtcClient?.start(withIdentifier: identifier)
    }
    
    internal func associate(identifier: String, withUser user: LiveDesignUser) {
        associations[identifier] = user
    }
    
    internal func disconnect() {
        self.rtcClient?.disconnect()
    }

}

extension WebRTCCallService {
    
    fileprivate func call(byPeer peer: Peer) -> WebRTCCall {
        for call in peerCalls {
            if call.peer == peer {
                return call
            }
        }
        fatalError()
    }
    
    fileprivate func remove(call: WebRTCCall) {
        for i in 0..<peerCalls.count {
            if peerCalls[i] == call {
                peerCalls.remove(at: i)
                return
            }
        }
        fatalError()
    }
    
    fileprivate func user(forIdentifier identifier: String) -> LiveDesignUser? {
        return associations[identifier]
    }
    
}

extension WebRTCCallService : WebRTCClientDelegate {
    
    func onStatusChanged(_ newStatus: WebRTCClientState) {
        switch newStatus {
        case .connected:    state = .online
        case .connecting:   state = .connecting
        case .disconnected: state = .offline
        }
    }
    
    func webRTCClient(_ client: WebRTCClient!, didReceiveError error: Error!) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient!, didRecieveIncomingCallFrom peer: Peer!) {
        peerCalls.append(WebRTCCall(contact: user(forIdentifier: peer.identifier)!, peer: peer))
        if let delegate = self.delegate {
            DispatchQueue.main.async {
                delegate.callService?(self, didReceiveCall: self.call(byPeer: peer))
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient!, didDropIncomingCallFrom peer: Peer!) {
        let call = self.call(byPeer: peer)
        remove(call: call)
        call.state = .ended
        
        if let delegate = self.delegate {
            DispatchQueue.main.async {
                delegate.callService?(self, didDisconnectCall: call)
            }
        }
    }
}
