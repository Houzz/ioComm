//
//  LiveDesignRepresentativeClaimedSessionSocketManager.swift
//  SocketIO POC
//
//  Created by Maxim on 18/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation
import SocketIO

@objc
public protocol LiveDesignRepresentativeClaimedSessionSocketDelegate : class {
    
    // MARK: Sketch
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didSetSketchWith sketchID: String, galleryID: String)
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didRequestRefreshForSession session: LiveDesignSession)
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, wasClosedDueTo reason: SocketServiceReason)
    
    // MARK: VOIP
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didReceiveCall call: Call)
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didDisconnectCall call: Call)
    
}

@objc public protocol LiveDesignRepresentativeClaimedSessionSocketProtocol {
    
    var delegate: LiveDesignRepresentativeClaimedSessionSocketDelegate? { get set }
    
    /**
     Session that is currently handled by socket.
     */
    var session: LiveDesignSession { get }
    
    /**
     Called when the rep pressed “AddToCart” button in the uiu
     */
    func invokeAddToCart()
    
    /**
     Make a VOIP call to the user.
     */
    func makeCall(completion: @escaping (Call?)->())

    /**
     Should be called when the rep saves the sketch.
     */
    func refresh()
    
    /**
     Hangup
     */
    func close()
    
}

internal class LiveDesignRepresentativeClaimedSessionSocketManager : NSObject, LiveDesignRepresentativeClaimedSessionSocketProtocol {
    
    weak var delegate: LiveDesignRepresentativeClaimedSessionSocketDelegate?
    
    let socket: SocketIOClient
    let rtcClient: WebRTCClient
    var session: LiveDesignSession
    let onClose: ((LiveDesignRepresentativeClaimedSessionSocketManager)->())?   // remove if singelton removed
    
    required init(socket: SocketIOClient, rtcClient: WebRTCClient, session: LiveDesignSession, onClose: ((LiveDesignRepresentativeClaimedSessionSocketManager)->())? = nil) {
        self.socket = socket
        self.rtcClient = rtcClient
        self.session = session
        self.onClose = onClose
        super.init()
        
        rtcClient.delegate = self;
        rtcClient.start(withIdentifier: session.repClientID)
        
        registerCallbacks()
    }
    
    // Mark:
    
    func invokeAddToCart() {
        socket.emit("session.invokeAddAllToCart", session.dictionary());
    }
    
    func makeCall(completion: @escaping (Call?)->()) {
        rtcClient.makeCall(withIdentifier: session.userClientID) { (peer) in
            completion(peer != nil ? LiveDesignCall(peer: peer!) : nil)
        }
    }
    
    func refresh() {
            socket.emit("session.refresh", session.dictionary())
    }
    
    func close() {
        socket.emit("session.close", session.dictionary());
    }
    
    // Mark: Private
    
    private func registerCallbacks() {
        socket.on("session.refresh") { [weak self] data, ack in
            if let session = LiveDesignSession(payload: data) {
                self?.onRefresh(with: session)
            }
        }
        
        socket.on("session.setSketch") { [weak self] data, ack in
            if let session = LiveDesignSession(payload: data), let payload = data[0] as? [String : Any] {
                self?.onSetSketch(with: session, payload: payload)
            }
        }
        
        socket.on("session.closed") { [weak self] data, ack in
            self?.onClose(reason: SocketServiceReason.request)
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.onClose(reason: SocketServiceReason.disconnect)
        }
    }
    
    private func onRefresh(with session: LiveDesignSession) {
        self.session = session
        delegate?.liveDesignRepresentativeClaimedSocket?(self, didRequestRefreshForSession: self.session)
    }
    
    private func onSetSketch(with session: LiveDesignSession, payload: [String : Any]) {
        self.session = session
        
        let sketchID = payload["SketchId"] as! String
        let galleryID = payload["GalleryId"] as! String
        
        delegate?.liveDesignRepresentativeClaimedSocket?(self, didSetSketchWith: sketchID, galleryID: galleryID)
    }
    
    private func onClose(reason: SocketServiceReason) {
        rtcClient.disconnect()
        self.onClose?(self)
        delegate?.liveDesignRepresentativeClaimedSocket?(self, wasClosedDueTo: reason)
    }
    
}

extension LiveDesignRepresentativeClaimedSessionSocketManager : WebRTCClientDelegate {
    
    func onStatusChanged(_ newStatus: WebRTCClientState) {

    }
    
    func webRTCClient(_ client: WebRTCClient!, didReceiveError error: Error!) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient!, didRecieveIncomingCallFrom peer: Peer!) {
        delegate?.liveDesignRepresentativeClaimedSocket?(self, didReceiveCall: LiveDesignCall(peer: peer))
    }
    
    func webRTCClient(_ client: WebRTCClient!, didDropIncomingCallFrom peer: Peer!) {
        delegate?.liveDesignRepresentativeClaimedSocket?(self, didDisconnectCall: LiveDesignCall(peer: peer))
    }

}
