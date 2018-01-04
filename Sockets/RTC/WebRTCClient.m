//
//  WebRTCClient.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "WebRTCClient+Private.h"
#import "Peer+Private.h"

#import <AVFoundation/AVFoundation.h>

static NSString *const kARDDefaultSTUNServerUrl =
@"stun:stun.l.google.com:19302";

@implementation WebRTCClient

- (instancetype)initWebRTCClient:(id<WebRTCClientDelegate>)delegate
                          socket:(SocketIOClient *)socket
{
    if(self = [super init]){
        self.delegate = delegate;
        
        self.callManager = [[SocketIOManagerCall alloc] initWithSocket:socket];
        self.callManager.delegate = self;
        
        self.factory = [RTCPeerConnectionFactory new];

        self.iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
        [self.iceServers addObject:[self defaultSTUNServer2]];
        
        self.peers = [NSMutableDictionary new];
        self.allKeyInPeers = [NSMutableArray array];
        self.callbacks = [NSMutableDictionary dictionary];

        [RTCPeerConnectionFactory initializeSSL];
    }
    
    return self;
}


-(void)dealloc {
    [self disconnect];
}

-(void)startWithIdentifier:(NSString*)identifier {
    [self connectWithIdentifier:identifier];
}

- (void)connectWithIdentifier:(NSString *)name {
    self.localMS =  [self createLocalMediaStream];
    NSDictionary *messageDict = @{@"name":name};
    [self.callManager emitReadyToStream:messageDict];
    
}

//-(void)callToIdentifier:(NSString *)identifier completion:(void(^)(BOOL))completion {
//
//    // send a message to remote user asking for a call
//    [self initiateConnectionWithIdentifier:identifier completion:^(NSDictionary *response) {
//
//    }];
//
//}

//-(void)answerCall {
//
//}

-(void)disconnect {
    [self.peers enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, Peer*  _Nonnull obj, BOOL * _Nonnull stop) {
        [self disconnectPeer:obj];
    }];
    self.peers = [NSMutableDictionary dictionary];
}

-(void)disconnectPeer:(Peer *)peer {
    [peer.pc close];
    [self.delegate webRTCClient:self didDropIncomingCallFromPeer:peer];
}

-(void)notifyError:(NSError *)error {
    if (self.delegate) {
        [self.delegate webRTCClient:self didReceiveError:error];
    }
}

-(void)notifyRemoteStream:(RTCMediaStream *)stream {
    if (stream.audioTracks.count) {

        Peer *peer = [self.peers objectForKey:self.allKeyInPeers.lastObject];
        
        if (self.onCall) {
            
            // waiting for expected call with callback
            [self.timeoutCall invalidate];
            void(^onCall)(Peer*) = self.onCall;
            self.onCall = nil;
            onCall(peer);
            
        } else {
        
            // notify for an incoming call
            [self.delegate webRTCClient:self didRecieveIncomingCallFromPeer:peer];
        }
    }
}

- (RTCMediaStream *)createLocalMediaStream {
    RTCMediaStream *localStream = [_factory mediaStreamWithLabel:@"ARDAMS"];
    [localStream addAudioTrack:[_factory audioTrackWithID:@"ARDAMSa0"]];
    
    return localStream;
}

-(void)makeCallWithIdentifier:(NSString *)identifier
                   completion:(void (^)(Peer *))completion
{
    self.onCall = completion;
    [self sendMessage:identifier type:KEY_INIT payload:nil];
    
    __weak typeof(self) welf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        welf.timeoutCall = [NSTimer scheduledTimerWithTimeInterval:10 repeats:NO block:^(NSTimer * _Nonnull timer) {
            welf.onCall = nil;
            completion(nil);
        }];
    });
}

//#pragma mark - Commands
//
//-(void)makeConnectionToIdentifier:(NSString*)identifier completion:(void(^)(NSDictionary *response))completion
//{
//    [self sendMessage:identifier type:KEY_INIT payload:nil completion:completion];
//}
//
//-(void)makeOfferToIdentifier:(NSString*)identifier completion:(void(^)(NSDictionary *response))completion
//{
//    Peer *peer = [self.peers objectForKey:identifier];
//    [peer.pc createOfferWithDelegate:peer constraints:[self defaultOfferConstraints]];
//}
//
//-(void)makeAnswerToIdentifier:(NSString*)identifier offer:(NSDictionary*)offer completion:(void(^)(NSDictionary *response))completion
//{
//    Peer *peer = [self.peers objectForKey:identifier];
//
//    NSString *type = [offer objectForKey:@"type"];
//    NSString *sdpPayload = [offer objectForKey:@"sdp"];
//    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdpPayload];
//
//    [peer.pc setRemoteDescriptionWithDelegate:peer sessionDescription:sdp];
//    [peer.pc createAnswerWithDelegate:peer constraints:[self defaultAnswerConstraints]];
//}

#pragma mark - enable/disable speaker

//- (void)enableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
////    self.isSpeakerEnabled = YES;
//}
//
//- (void)disableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
////    self.isSpeakerEnabled = NO;
//}

-(Peer *)addPeer:(NSString *)ID {
    
    Peer *peer = [[Peer alloc] initWithWithId:ID endPoint:0 andWebRTCClient:self];
    [self.peers setObject:peer forKey:ID];
    [self.allKeyInPeers addObject:ID];
    
    return peer;
}


-(void)removePeer:(NSString *)ID {
    Peer *peer = [self.peers objectForKey:ID];
    
    [peer.pc close];
    
    [self.peers removeObjectForKey:peer.ID];
    [self.allKeyInPeers removeObject:peer.ID];
    
    [self.delegate webRTCClient:self didDropIncomingCallFromPeer:peer];
}

- (void)sendMessage:(NSString *)to type:(NSString *)type payload:(NSDictionary *)payload {
    [self sendMessage:to type:type payload:payload completion:nil];
}

- (void)sendMessage:(NSString *)to type:(NSString *)type payload:(NSDictionary *)payload completion:(void(^)(NSDictionary*))completion {
    NSMutableDictionary *messageDicts = [NSMutableDictionary new];
    messageDicts[@"to"] = to;
    messageDicts[@"type"] = type;
    messageDicts[@"payload"] = payload; //can be nil

    // additional details can be added
//    messageDicts[@"custom_details"] = @{ @"caller" : self.callIdentifier };
    
//    if (completion) {
//        [self.callbacks setObject:completion forKey:to];
//    }
    
    [self.callManager emitMessage:messageDicts];
}

#pragma mark - SocketIOManagerCallDelegate

-(void)socketIOManager:(SocketIOManagerCall*)manager didReceiveMessage:(NSDictionary*)json {
    
    if(!json){
        return;
    }
    
    NSString *from = [json objectForKey:@"from"];
    NSString *type = [json objectForKey:@"type"];
    
    NSDictionary *payloadDict = nil;
    if(![type isEqualToString:KEY_INIT]){
        payloadDict = [json objectForKey:@"payload"];
    }
    
    
    BOOL isPeersContainsKeyFrom = [self isPeersContainsKeyFrom:from peers:self.peers];
    
    if(!isPeersContainsKeyFrom){
        
        // new connection
        
        Peer *peer = [self addPeer:from];
        [peer.pc addStream:self.localMS];
        
        [self executeCommandByType:type peerId:from payload:payloadDict];
        
//        NSDictionary* customDetails = json[@"custom_details"];
//        NSString *identifier = customDetails[@"caller"];
//
//        if ([self.callbacks objectForKey:identifier]) {
//            void(^onAnswer)(BOOL) = [self.callbacks objectForKey:identifier];
//            [self.callbacks removeObjectForKey:identifier];
//            onAnswer(YES);
//        }

    } else {
        [self executeCommandByType:type peerId:from payload:payloadDict];
    }
    
    
    NSDictionary* customDetails = json[@"custom_details"];
    NSString *identifier = customDetails[@"caller"];
    
    // callbacks are answered per type
    NSString *callbackIdentifier = nil;
    
    if ([type isEqualToString:KEY_INIT]){
        
        
    } else if ([type isEqualToString:KEY_OFFER]) {
    
        
    } else if ([type isEqualToString:KEY_ANSWER]) {
        
    } else if ([type isEqualToString:KEY_CANDIDATE]) {
        
    }
}

-(void)socketIOManager:(SocketIOManagerCall*)manager didReceiveIdentifier:(NSString*)identifier {
    self.callIdentifier = identifier;
    
    if (self.delegate) {
        [self.delegate onStatusChanged:kWebRTCClientStateConnected];
    }
}

#pragma mark - message handler

- (BOOL)isPeersContainsKeyFrom:(NSString *)from peers:(NSMutableDictionary *)peers {
    NSArray *allKeys = [self.peers allKeys];
    
    for(int i = 0; i < allKeys.count ; i++){
        if([allKeys[i] isEqualToString:from]){
            return YES;
        }
    }
    
    return NO;
}


- (void)executeCommandByType:(NSString *)type peerId:(NSString *)peerId payload:(NSDictionary *)payload {
    
    if([type isEqualToString:KEY_INIT]){
        [self createOfferCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_OFFER]){
        [self createAnswerCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_ANSWER]){
        [self setRemoteSDPCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_CANDIDATE]){
        [self addIceCandidateCommand:peerId payload:payload];
    }
}

#pragma mark - execute command

// offer to make a call
-(void)createOfferCommand:(NSString *)peerId payload:(NSDictionary *)payload {
    Peer *peer = [self.peers objectForKey:peerId];
    [peer.pc createOfferWithDelegate:peer constraints:[self defaultOfferConstraints]];
    
}

// answer to an incoming call
-(void)createAnswerCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    Peer *peer = [self.peers objectForKey:peerId];
    
    NSString *type = [payload objectForKey:@"type"];
    NSString *sdpPayload = [payload objectForKey:@"sdp"];
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdpPayload];
    
    [peer.pc setRemoteDescriptionWithDelegate:peer sessionDescription:sdp];
    [peer.pc createAnswerWithDelegate:peer constraints:[self defaultAnswerConstraints]];
}


// when answered
-(void)setRemoteSDPCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    Peer *peer = [self.peers objectForKey:peerId];
    
    NSString *type = [payload objectForKey:@"type"];
    NSString *sdpPayload = [payload objectForKey:@"sdp"];
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdpPayload];
    [peer.pc setRemoteDescriptionWithDelegate:peer sessionDescription:sdp];
}

// dont touch
-(void)addIceCandidateCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    Peer *peer = [self.peers objectForKey:peerId];
    RTCPeerConnection *pc = peer.pc;
    
    if(pc.remoteDescription){
        
        NSString *ID = [payload objectForKey:@"id"];
        NSInteger label = [[payload objectForKey:@"label"] integerValue];
        NSString *candidatePayload = [payload objectForKey:KEY_CANDIDATE];
        
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:ID index:label sdp:candidatePayload];
        [pc addICECandidate:candidate];
        
    }
}

#pragma mark - Audio mute/unmute
- (void)muteAllAudioIn {
    NSLog(@"all keys in peers: %@", [self.peers allKeys].description);
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer muteAudioIn];
    }
    
    
}

- (void)unmuteAllAudioIn {
    
    NSLog(@"all keys in peers: %@", [self.peers allKeys].description);
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer unmuteAudioIn];
    }

}

#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"false"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

- (RTCICEServer *)defaultSTUNServer {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

- (RTCICEServer *)defaultSTUNServer2 {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:@"stun:23.21.150.121"];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

@end
