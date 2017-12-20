//
//  SocketIOManager.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/9/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
@import SocketIO;

@class SocketIOManagerCall;

@protocol SocketIOManagerCallDelegate <NSObject>
@required
-(void)socketIOManager:(SocketIOManagerCall*)manager didReceiveMessage:(NSDictionary*)message;
-(void)socketIOManager:(SocketIOManagerCall*)manager didReceiveIdentifier:(NSString*)identifier;
@end

@interface SocketIOManagerCall : NSObject
@property (nonatomic, weak) id<SocketIOManagerCallDelegate> delegate;

/**
 Initializer.
 
 @param socket  A connected SocketIO.
 */
- (instancetype)initWithSocket:(SocketIOClient*)socket;

- (void)emitMessage:(NSDictionary *)messageDict;
- (void)emitReadyToStream:(NSDictionary *)messageDict;

@end
