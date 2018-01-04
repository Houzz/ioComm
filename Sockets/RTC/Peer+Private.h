//
//  Peer+Private.h
//  Sockets
//
//  Created by Maxim on 26/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

#import <libjingle_peerconnection/RTCSessionDescriptionDelegate.h>
#import <libjingle_peerconnection/RTCPeerConnectionDelegate.h>

#import "Peer.h"

@class WebRTCClient;
@class RTCPeerConnection;
@class RTCAudioTrack;

@interface Peer ()  <RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate>
@property (nonatomic) RTCPeerConnection *pc;
@property (nonatomic) NSString *ID;
@property (nonatomic) NSInteger endPoint;
@property (nonatomic, weak) WebRTCClient *webRTCClient;
@property (nonatomic) RTCAudioTrack *defaultAudioTrack;

-(instancetype) initWithWithId:(NSString *)ID
                      endPoint:(NSInteger)endPoint
               andWebRTCClient:(WebRTCClient *)webRTCClient;



- (void)muteAudioIn;
- (void)unmuteAudioIn;
@end
