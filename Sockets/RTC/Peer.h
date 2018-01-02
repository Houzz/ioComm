//
//  Peer.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Peer : NSObject
@property (nonatomic, strong, readonly) NSUUID *uuid;

- (void)disconnect;

- (void)muteAudioIn;
- (void)unmuteAudioIn;
@end
