//
//  VisualChatSocketManager.swift
//  SocketIO
//
//  Created by Maxim on 07/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation
import SocketIO

public protocol LiveDesignUserSocketDelegate: class {

    // MARK: Sketch

    func liveDesignUserSocketDidRequestAddAllToCart(_ socket: LiveDesignUserSocketProtocol)

    func liveDesignUserSocketDidRequestRefresh(_ socket: LiveDesignUserSocketProtocol)
    
    func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClaimedByRepresentative representative: String?)
    
    func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClosedDueTo reason: SocketServiceReason)
    
    // MARK: VOIP
    
    func liveDesignUserSocketDidReceiveCall(_ socket: LiveDesignUserSocketProtocol)
    
    func liveDesignUserSocketDidDisconnectCall(_ socket: LiveDesignUserSocketProtocol)
    
}

public protocol LiveDesignUserSocketProtocol {
    
    var delegate: LiveDesignUserSocketDelegate? { get set }
    
    /**
     Register the user to the livedesign queue.
     */
    func register(with username: String, completion: @escaping (String?)->())
    
    /**
     Call when the user app makes the first setSketch and receives sketchId.
     */
    func setSketch(sketchID: String, galleryID: String)
    
    /**
     Call when the user takes another photo.
     */
    func refresh()
    
    /**
     Make a VOIP call to the representative.
     */
    func makeCall()
    
    /**
     Hangup.
     */
    func close()
    
}

internal class LiveDesignUserSocketManager: NSObject, LiveDesignUserSocketProtocol {
    
    weak var delegate: LiveDesignUserSocketDelegate?

    let socket: SocketIOClient
    var session: Session?
    var rtcClient: WebRTCClient?
    let onClose: ((LiveDesignUserSocketProtocol)->())?  // remove if singelton removed

    required init(socket: SocketIOClient, onClose: ((LiveDesignUserSocketProtocol)->())? = nil) {
        self.socket = socket
        self.onClose = onClose
        super.init()
        self.rtcClient = WebRTCClient(webRTCClient: self, socket: socket)

        registerCallbacks()
    }
    
    // Mark: SocketManagerProtocol
    
    func register(with username: String, completion: @escaping (String?)->()) {
        
        if socket.status == .disconnected {
            socket.connect()
            return
        }
        socket.emitWithAck("session.register", username).timingOut(after: 1) { [weak self] payload in

            if let contents = payload[0] as? [String : Any] {
                self?.session = Session(payload: contents)
                self?.rtcClient?.start(withIdentifier: self?.session?.userClientID)

                if let sessionID = self?.session?.identifier {
                    completion(sessionID)
                }
            } else {
                completion(nil)
            }
            
        }
    }
    
    func setSketch(sketchID: String, galleryID: String) {
        if var dictionary = self.session?.dictionary() {
            
            dictionary["SketchId"] = sketchID
            dictionary["GalleryId"] = galleryID
            
            socket.emit("session.setSketch", dictionary);
        }
    }
    
    func refresh() {
        if let dictionary = self.session?.dictionary() {
            socket.emit("session.refresh", dictionary)
        }
    }
    
    func makeCall() {
        guard let session = self.session else { return }
        self.rtcClient?.sendMessage(session.repClientID, type: KEY_INIT, payload: nil)
    }
    
    func close() {
        if let session = self.session {
            socket.emit("session.close", session.dictionary())
        }
    }
    
    // Mark: Private
    
    private func registerCallbacks() {
        socket.on("session.claimed") { [weak self] data, ack in
            if let session = Session(payload: data) {
                self?.onClaim(with: session)
            }
        }
        
        socket.on("session.invokeAddAllToCart") { [weak self] data, ack in
            self?.onInvokeAddAllToCart()
        }
        
        socket.on("session.closed") { [weak self] data, ack in
            self?.onClose(reason: SocketServiceReason.request)
        }
        
        socket.on("session.refresh") { [weak self] data, ack in
            if let session = Session(payload: data) {
                self?.onRefresh(with: session)
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.onClose(reason: SocketServiceReason.disconnect)
        }
            
    }
    
    private func onClaim(with session: Session) {
        self.session = session
        delegate?.liveDesignUserSocket(self, wasClaimedByRepresentative: session.representativeUsername)
    }
    
    private func onInvokeAddAllToCart() {
        delegate?.liveDesignUserSocketDidRequestAddAllToCart(self)
    }
    
    private func onRefresh(with session: Session) {
        self.session = session
        delegate?.liveDesignUserSocketDidRequestRefresh(self)
    }
    
    private func onClose(reason: SocketServiceReason) {
        self.rtcClient?.disconnect()
        self.onClose?(self)
        delegate?.liveDesignUserSocket(self, wasClosedDueTo: reason)
    }

}

extension LiveDesignUserSocketManager : WebRTCClientDelegate {
    
    func onStatusChanged(_ newStatus: WebRTCClientState) {

    }

    func webRTCClient(_ client: WebRTCClient!, didReceiveError error: Error!) {
        
    }
    
    func webRTCClientDidRecieveIncomingCall(_ client: WebRTCClient!) {
        delegate?.liveDesignUserSocketDidReceiveCall(self)
    }
    
    func webRTCClientDidDropIncomingCall(_ client: WebRTCClient!) {
        delegate?.liveDesignUserSocketDidDisconnectCall(self)
    }

}

