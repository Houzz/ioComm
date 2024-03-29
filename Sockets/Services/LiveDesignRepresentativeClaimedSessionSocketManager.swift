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
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didSetSketchWith session: LiveDesignSession)
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, didRequestRefreshForSession session: LiveDesignSession)
    
    @objc optional func liveDesignRepresentativeClaimedSocket(_ socket: LiveDesignRepresentativeClaimedSessionSocketProtocol, wasClosedDueTo reason: SocketServiceReason)
    
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
    func invokeAddToCart(with session: LiveDesignSession?)

    /**
     Should be called when the rep saves the sketch.
     */
    func refresh(with session: LiveDesignSession?)
    
    /**
     Hangup
     */
    func close()
    
}

internal class LiveDesignRepresentativeClaimedSessionSocketManager : NSObject, LiveDesignRepresentativeClaimedSessionSocketProtocol {
    
    weak var delegate: LiveDesignRepresentativeClaimedSessionSocketDelegate?
    
    let socket: SocketIOClient
    var session: LiveDesignSession
    let onClose: ((LiveDesignRepresentativeClaimedSessionSocketManager)->())?   // remove if singelton removed
    
    required init(socket: SocketIOClient, session: LiveDesignSession, onClose: ((LiveDesignRepresentativeClaimedSessionSocketManager)->())? = nil) {
        self.socket = socket
        self.session = session
        self.onClose = onClose
        super.init()
        
        registerCallbacks()
    }
    
    // Mark:
    
    func invokeAddToCart(with session: LiveDesignSession?) {
        if let session = session {
            self.session = session
        }
        
        socket.emit("session.invokeAddAllToCart", self.session.dictionary());
    }
    
    func refresh(with session: LiveDesignSession?) {
        if let session = session {
            self.session = session
        }
        
        socket.emit("session.refresh", self.session.dictionary())
    }
    
    func close() {
        socket.emit("session.close", session.dictionary());
        onClose(reason: .request)
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
        delegate?.liveDesignRepresentativeClaimedSocket?(self, didSetSketchWith: session)
    }
    
    private func onClose(reason: SocketServiceReason) {
        DispatchQueue.main.async {
            self.onClose?(self)
            self.delegate?.liveDesignRepresentativeClaimedSocket?(self, wasClosedDueTo: reason)
        }
    }
    
}
