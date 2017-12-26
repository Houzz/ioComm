//
//  WebRTCClient+Private.h
//  SocketIO POC
//
//  Created by Maxim on 18/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

#import "WebRTCClient.h"

#import <libjingle_peerconnection/RTCMediaStream.h>
#import <libjingle_peerconnection/RTCPeerConnection.h>
#import <libjingle_peerconnection/RTCPeerConnectionFactory.h>
#import <libjingle_peerconnection/RTCMediaConstraints.h>
#import <libjingle_peerconnection/RTCVideoSource.h>
#import <libjingle_peerconnection/RTCICECandidate.h>
#import <libjingle_peerconnection/RTCICEServer.h>
#import <libjingle_peerconnection/RTCPair.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>
#import <libjingle_peerconnection/RTCAudioTrack.h>
#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <libjingle_peerconnection/RTCVideoCapturer.h>
#import <libjingle_peerconnection/RTCSessionDescription.h>

#import "SocketIOManagerCall.h"

static NSString * const KEY_INIT = @"init";
static NSString * const KEY_OFFER = @"offer";
static NSString * const KEY_ANSWER = @"answer";
static NSString * const KEY_CANDIDATE = @"candidate";
static NSUInteger const MAX_PEER = 2;

@interface WebRTCClient () <SocketIOManagerCallDelegate>
@property (nonatomic, strong) SocketIOManagerCall *callManager;

@property (nonatomic) NSMutableArray<NSNumber *> *endPoints;
@property (nonatomic) NSMutableDictionary<NSString*, Peer*> *peers;
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) RTCMediaStream *localMS;
@property (nonatomic) NSString *currentPeerConnectionID;
@property (nonatomic) NSMutableArray *allKeyInPeers;
@property (nonatomic) NSMutableArray *iceServers;
@property (nonatomic, strong) NSString* callIdentifier;

@property (nonatomic, copy) void(^onCall)(Peer*);
@property (nonatomic, strong) NSTimer *timeoutCall;

// temp - change to object that has timeout
@property (nonatomic, strong) NSMutableDictionary<NSString*, void(^)(NSDictionary*)>* callbacks;


- (void)sendMessage:(NSString *)to type:(NSString *)type payload:(NSDictionary *)payload;

- (void)notifyError:(NSError*)error;
- (void)notifyRemoteStream:(RTCMediaStream*)stream;

-(Peer *)addPeer:(NSString *)ID;
-(void)removePeer:(NSString *)ID;

@end
