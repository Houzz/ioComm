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

    @objc optional func liveDesignUserSocketDidRequestAddAllToCart(_ socket: LiveDesignUserSocketProtocol, with session: LiveDesignSession)

    @objc optional func liveDesignUserSocketDidRequestRefresh(_ socket: LiveDesignUserSocketProtocol, with session: LiveDesignSession)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClaimedByRepresentativeWith session: LiveDesignSession)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClosedDueTo reason: SocketServiceReason)
    
}

@objc
public protocol LiveDesignUserSocketProtocol {
    
    var delegate: LiveDesignUserSocketDelegate? { get set }
    
    /**
     Session that is currently handled by socket.
     */
    var session: LiveDesignSession? { get }
    
    /**
     Register the user to the livedesign queue.
     */
    func register(with user: LiveDesignUser, productID: String, completion: @escaping (LiveDesignSession?)->())
    
    /**
     Call when the user app makes the first setSketch and receives sketchId.
     */
    func setSketch(with session: LiveDesignSession)
    
    /**
     Call when the user takes another photo.
     */
    func refresh(with session: LiveDesignSession?)
    
    /**
     Hangup.
     */
    func close()
    
}

internal class LiveDesignUserSocketManager: NSObject, LiveDesignUserSocketProtocol {
    
    weak var delegate: LiveDesignUserSocketDelegate?

    let socket: SocketIOClient
    var session: LiveDesignSession?
    let onClose: ((LiveDesignUserSocketProtocol)->())?  // remove if singelton removed

    required init(socket: SocketIOClient, onClose: ((LiveDesignUserSocketProtocol)->())? = nil) {
        self.socket = socket
        self.onClose = onClose
        super.init()

        registerCallbacks()
    }
    
    // Mark: SocketManagerProtocol
    
    func register(with user: LiveDesignUser, productID: String, completion: @escaping (LiveDesignSession?)->()) {
        
        if socket.status == .disconnected {
            socket.connect()
            return
        }
        socket.emitWithAck("session.register", user.dictionary(), productID).timingOut(after: 10) { [weak self] payload in

            if let contents = payload[0] as? [String : Any] {
                self?.session = LiveDesignSession(payload: contents)
                completion(self?.session)
            } else {
                completion(nil)
            }
            
        }
    }
    
    func setSketch(with session: LiveDesignSession) {
        self.session = session
        socket.emit("session.setSketch", session.dictionary());
    }
    
    func refresh(with session: LiveDesignSession?) {
        if let session = session {
            self.session = session
        }
        
        if let session = self.session {
            socket.emit("session.refresh", session.dictionary())
        }
    }

    func close() {
        if let session = self.session {
            socket.emit("session.close", session.dictionary())
            onClose(reason: .request)
        }
    }
    
    // Mark: Private
    
    private func registerCallbacks() {
        socket.on("session.claimed") { [weak self] data, ack in
            if let session = LiveDesignSession(payload: data) {
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
            if let session = LiveDesignSession(payload: data) {
                self?.onRefresh(with: session)
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.onClose(reason: SocketServiceReason.disconnect)
        }
            
    }
    
    private func onClaim(with session: LiveDesignSession) {
        self.session = session
        delegate?.liveDesignUserSocket?(self, wasClaimedByRepresentativeWith: session)
    }
    
    private func onInvokeAddAllToCart() {
        delegate?.liveDesignUserSocketDidRequestAddAllToCart?(self, with: self.session!)
    }
    
    private func onRefresh(with session: LiveDesignSession) {
        self.session = session
        delegate?.liveDesignUserSocketDidRequestRefresh?(self, with: session)
    }
    
    private func onClose(reason: SocketServiceReason) {
        DispatchQueue.main.async {
            self.onClose?(self)
            self.delegate?.liveDesignUserSocket?(self, wasClosedDueTo: reason)
        }
    }

}

