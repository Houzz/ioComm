//
//  Peer.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libjingle_peerconnection/RTCSessionDescriptionDelegate.h>
#import <libjingle_peerconnection/RTCPeerConnectionDelegate.h>

@class WebRTCClient;
@class RTCPeerConnection;

@interface Peer : NSObject <RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate>
@property (nonatomic, readonly) NSString *ID;
@property (nonatomic, readonly) RTCPeerConnection *pc;
@property (nonatomic, readonly) NSInteger endPoint;

-(instancetype) initWithWithId:(NSString *)ID
                      endPoint:(NSInteger)endPoint
               andWebRTCClient:(WebRTCClient *)webRTCClient;



- (void)muteAudioIn;
- (void)unmuteAudioIn;

@end
