//
//  WebRTCClient.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WebRTCClientState) {
    // Disconnected from servers.
    kWebRTCClientStateDisconnected,
    // Connecting to servers.
    kWebRTCClientStateConnecting,
    // Connected to servers.
    kWebRTCClientStateConnected,
};

static NSString * const KEY_INIT = @"init";

@class WebRTCClient;
@class SocketIOClient;
@class Peer;

@protocol WebRTCClientDelegate <NSObject>
@required
- (void)onStatusChanged:(WebRTCClientState)newStatus;

- (void)webRTCClient:(WebRTCClient*)client didReceiveError:(NSError*)error;
- (void)webRTCClient:(WebRTCClient*)client didRecieveIncomingCallFromPeer:(Peer*)peer;
- (void)webRTCClient:(WebRTCClient*)client didDropIncomingCallFromPeer:(Peer*)peer;
@end

@class Peer;

@interface WebRTCClient : NSObject
@property (nonatomic, weak) id<WebRTCClientDelegate> delegate;

-(instancetype) initWebRTCClient:(id<WebRTCClientDelegate>)delegate
                          socket:(SocketIOClient*)socket;

// for later implementation

///**
// Initiate a call with a user that has input identifier.
// Once remote user accepts client will open up communication.
// */
//- (void)callToIdentifier:(NSString*)identifier completion:(void(^)(BOOL answered))completion;
//
///**
// Answers an incoming call.
// */
//- (void)answerCall;

/**
 Disconnect from RTC (also hangs up current call).
 */
- (void)disconnect;

// for removal
- (void)startWithIdentifier:(NSString*)identifier;

- (void)muteAllAudioIn;
- (void)unmuteAllAudioIn;

- (void)makeCallWithIdentifier:(NSString*)identifier completion:(void(^)(Peer*))completion;

@end
