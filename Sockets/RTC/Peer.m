//
//  Peer.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "Peer.h"
#import "WebRTCClient+Private.h"

@class RTCMediaConstraints;

static NSString *kARDAppClientErrorDomain = @"WebRTCClient";
static NSInteger kARDAppClientErrorSetSDP = -4;
static NSInteger kARDAppClientErrorCreateSDP = -3;

@interface Peer () 
@property (nonatomic) RTCPeerConnection *pc;
@property (nonatomic) NSString *ID;
@property (nonatomic) NSInteger endPoint;

@property (nonatomic, weak) WebRTCClient *webRTCClient;

@property (nonatomic) RTCAudioTrack *defaultAudioTrack;
@end

@implementation Peer


-(instancetype) initWithWithId:(NSString *)ID
                      endPoint:(NSInteger)endPoint
               andWebRTCClient:(WebRTCClient *)webRTCClient {
    
    
    if(self = [super init]){
        
        NSLog(@"new Peer id: %@",ID);
        
        self.webRTCClient = webRTCClient;
        
        self.pc = [webRTCClient.factory peerConnectionWithICEServers:webRTCClient.iceServers constraints:[self defaultPeerConnectionConstraints] delegate:self];
        
        self.ID = ID;
        
        [self.pc addStream:webRTCClient.localMS];
        
        if (webRTCClient.delegate && [webRTCClient.delegate respondsToSelector:@selector(onStatusChanged:)]) {
            
            [webRTCClient.delegate onStatusChanged:kWebRTCClientStateConnecting];
        }
        
    }
    
    return self;
}


// Called when creating a session.
//method นี้อาจเทียบเท่ากับ onCreateSuccess in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
    if(error){ //code from apprtc
        
        NSLog(@"error in didCreateSessionDescription: %@", error);
        
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Failed to create session description.",
                                   };
        NSError *sdpError =
        [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                   code:kARDAppClientErrorCreateSDP
                               userInfo:userInfo];
        [self.webRTCClient notifyError:sdpError];
        NSLog(@"sdpError: %@", sdpError);
        return;
        
        
    }//else{ //success
    
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    
    NSDictionary *payload = @{ @"type":sdp.type,
                               @"sdp":sdp.description};
    
    [self.webRTCClient sendMessage:self.ID type:sdp.type payload:payload];
    NSLog(@"didCreateSessionDescription Sending: SDP \n %@", sdp.description);
    // }
    
    
    });
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"Failed to set session description. Error: %@", error);
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: @"Failed to set session description.",
                                       };
            NSError *sdpError =
            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                       code:kARDAppClientErrorSetSDP
                                   userInfo:userInfo];
            [self.webRTCClient notifyError:sdpError];
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        //
        //        if (!_isInitiator && !_peerConnection.localDescription) {
        //            RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        //            [_peerConnection createAnswerWithDelegate:self
        //                                          constraints:constraints];
        //
        //        }
        
        
    });
}




//RTCPeerConnectionDelegate

// Triggered when the SignalingState changed.
//onSignalingChange() in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged{
    NSLog(@"Signaling state changed: %d", stateChanged);
}


//onAddStream() in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream{
    
    if (!peerConnection) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webRTCClient notifyRemoteStream:stream];
    });
    
}


// Triggered when a remote peer close a stream.

//onRemoveStream in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream{
    
    NSLog(@"onRemoveStream: %@", stream.label);
    [self.webRTCClient removePeer:self.ID];
    
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection{
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState{
    
    if(newState == RTCICEConnectionDisconnected){
        [self.webRTCClient removePeer:self.ID];
        [self.webRTCClient.delegate onStatusChanged:kWebRTCClientStateDisconnected];
        NSLog(@"ICEConnection State Disconnected");
    }
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState{
    
    if(newState == RTCICEGatheringNew){
        NSLog(@"ICE gathering state changed: new");
    }else if(newState == RTCICEGatheringGathering){
        NSLog(@"ICE gathering state changed: gathering");
    }else if(newState == RTCICEGatheringComplete){
        NSLog(@"ICE gathering state changed: complete");
    }
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate{
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(candidate){
            
            NSLog(@"iceCandidate: %@", candidate.description);
            
            NSDictionary *payload = @{@"label":@(candidate.sdpMLineIndex),
                                      @"id":candidate.sdpMid,
                                      KEY_CANDIDATE:candidate.sdp
                                      };
            
            [self.webRTCClient sendMessage:self.ID type:KEY_CANDIDATE payload:payload];
            
        }else{
            NSLog(@"End of candidates");
        }
    });
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel{
}




#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    NSLog(@"peer -> audio muted");
    
    RTCMediaStream *localStream = self.pc.localStreams[0];
    
    //remove old stream from peerconnection
    [self.pc removeStream:localStream];
    
    //keep it for unmute later
    self.defaultAudioTrack = localStream.audioTracks[0];
    
    //remove audio from stream
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    
    
    [self.pc addStream:localStream];
}

- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    RTCMediaStream *localStream = self.pc.localStreams[0];
    
    //clear old stream from peerconnection
    [self.pc removeStream:localStream];
    
    //add audio again
    [localStream addAudioTrack:self.defaultAudioTrack];
    
    //add new stream
    [self.pc addStream:localStream];
    
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:optionalConstraints];
    return constraints;
}


@end
