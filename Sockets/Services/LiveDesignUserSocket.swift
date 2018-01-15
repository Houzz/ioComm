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

    @objc optional func liveDesignUserSocketDidRequestAddAllToCart(_ socket: LiveDesignUserSocketProtocol)

    @objc optional func liveDesignUserSocketDidRequestRefresh(_ socket: LiveDesignUserSocketProtocol)
    
    @objc optional func liveDesignUserSocket(_ socket: LiveDesignUserSocketProtocol, wasClaimedByRepresentative representative: LiveDesignUser)
    
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
    func register(with user: LiveDesignUser, completion: @escaping (LiveDesignSession?)->())
    
    /**
     Call when the user app makes the first setSketch and receives sketchId.
     */
    func setSketch(sketchID: String, galleryID: String)
    
    /**
     Call when the user takes another photo.
     */
    func refresh()
    
    /**
     Hangup.
     */
    func close()
    
}

internal class LiveDesignUserSocketManager: NSObject, LiveDesignUserSocketProtocol {
    
    weak var delegate: LiveDesignUserSocketDelegate?

    let socket: SocketIOClient
    let callService: ConfigurableCallService
    var session: LiveDesignSession?
    let onClose: ((LiveDesignUserSocketProtocol)->())?  // remove if singelton removed

    required init(socket: SocketIOClient, callService: ConfigurableCallService, onClose: ((LiveDesignUserSocketProtocol)->())? = nil) {
        self.socket = socket
        self.callService = callService
        self.onClose = onClose
        super.init()

        registerCallbacks()
    }
    
    // Mark: SocketManagerProtocol
    
    func register(with user: LiveDesignUser, completion: @escaping (LiveDesignSession?)->()) {
        
        if socket.status == .disconnected {
            socket.connect()
            return
        }
        socket.emitWithAck("session.register", user.dictionary(), "").timingOut(after: 10) { [weak self] payload in

            if let contents = payload[0] as? [String : Any] {
                self?.session = LiveDesignSession(payload: contents)
                
                if let userClientID = self?.session?.userClientID {
                    self?.callService.start(withIdentifier: userClientID)
                }
                
                completion(self?.session)
            } else {
                completion(nil)
            }
            
        }
    }
    
    func setSketch(sketchID: String, galleryID: String) {
        self.session?.sketchID = sketchID
        self.session?.galleryID = galleryID
        
        if let dictionary = self.session?.dictionary() {
            socket.emit("session.setSketch", dictionary);
        }
    }
    
    func refresh() {
        if let dictionary = self.session?.dictionary() {
            socket.emit("session.refresh", dictionary)
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
            if let session = LiveDesignSession(payload: data), let representative = session.representative, let repID = session.repClientID {
                self?.callService.associate(identifier: repID, withUser: representative)
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
        delegate?.liveDesignUserSocket?(self, wasClaimedByRepresentative: session.representative!)
    }
    
    private func onInvokeAddAllToCart() {
        delegate?.liveDesignUserSocketDidRequestAddAllToCart?(self)
    }
    
    private func onRefresh(with session: LiveDesignSession) {
        self.session = session
        delegate?.liveDesignUserSocketDidRequestRefresh?(self)
    }
    
    private func onClose(reason: SocketServiceReason) {
        DispatchQueue.main.async {
            self.callService.disconnect()
            self.onClose?(self)
            self.delegate?.liveDesignUserSocket?(self, wasClosedDueTo: reason)
        }
    }

}

