//
//  VisualChatSocketManager.swift
//  SocketIO
//
//  Created by Maxim on 07/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation
import SocketIO

@objc
public protocol LiveDesignUserSocketDelegate: class {

    // MARK: Sketch

    @objc optional func liveDesignUserSocketDidRequestAddAllToCart(_ socket: LiveDesignUserSocketProtocol)

    @objc optional func liveDesignUserSocketDidRequestRefresh(_ socket: LiveDesignUserSocketProtocol)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClaimedByRepresentative representative: Session.User)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClosedDueTo reason: SocketServiceReason)
    
    // MARK: VOIP
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, didReceiveCall call: Call)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, didDisconnectCall call: Call)
    
}

@objc
public protocol LiveDesignUserSocketProtocol {
    
    var delegate: LiveDesignUserSocketDelegate? { get set }
    
    /**
     Session that is currently handled by socket.
     */
    var session: Session? { get }
    
    /**
     Register the user to the livedesign queue.
     */
    func register(with user: Session.User, completion: @escaping (Session?)->())
    
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
    func makeCall(completion: @escaping (Call?)->())
    
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
    
    func register(with user: Session.User, completion: @escaping (Session?)->()) {
        
        if socket.status == .disconnected {
            socket.connect()
            return
        }
        socket.emitWithAck("session.register", user.dictionary()).timingOut(after: 5) { [weak self] payload in

            if let contents = payload[0] as? [String : Any] {
                self?.session = Session(payload: contents)
                self?.rtcClient?.start(withIdentifier: self?.session?.userClientID)
                
                completion(self?.session)
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
    
    func makeCall(completion: @escaping (Call?)->()) {
        guard let session = self.session else { return }
        self.rtcClient?.makeCall(withIdentifier: session.repClientID, completion: { (peer) in
            completion(peer != nil ? LiveDesignCall(peer: peer!) : nil)
        })
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
        delegate?.liveDesignUserSocket?(self, wasClaimedByRepresentative: session.representative!)
    }
    
    private func onInvokeAddAllToCart() {
        delegate?.liveDesignUserSocketDidRequestAddAllToCart?(self)
    }
    
    private func onRefresh(with session: Session) {
        self.session = session
        delegate?.liveDesignUserSocketDidRequestRefresh?(self)
    }
    
    private func onClose(reason: SocketServiceReason) {
        self.rtcClient?.disconnect()
        self.onClose?(self)
        delegate?.liveDesignUserSocket?(self, wasClosedDueTo: reason)
    }

}

extension LiveDesignUserSocketManager : WebRTCClientDelegate {
    
    func onStatusChanged(_ newStatus: WebRTCClientState) {

    }

    func webRTCClient(_ client: WebRTCClient!, didReceiveError error: Error!) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient!, didRecieveIncomingCallFrom peer: Peer!) {
        delegate?.liveDesignUserSocket?(self, didReceiveCall: LiveDesignCall(peer: peer))
    }
    
    func webRTCClient(_ client: WebRTCClient!, didDropIncomingCallFrom peer: Peer!) {
        delegate?.liveDesignUserSocket?(self, didDisconnectCall: LiveDesignCall(peer: peer))
    }

}

