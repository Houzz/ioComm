//
//  SocketIOManager.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/9/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "SocketIOManagerCall.h"
#import <SocketIO/SocketIO-Swift.h>

@interface SocketIOManagerCall ()
@property (nonatomic, strong) NSString* callIdentifier;

@property (nonatomic, retain) SocketIOClient *socket;
@property (nonatomic, strong) SocketManager *manager;
@end

@implementation SocketIOManagerCall

#pragma mark - LifeCycle

- (instancetype)initWithSocket:(SocketIOClient *)socket {
    if (self = [super init]) {
        self.socket = socket;
        [self registerCallbacks];
    }
    return self;
}

#pragma mark - Callbacks

- (void)registerCallbacks {
    __weak typeof(self) welf = self;
    
    [self.socket on:@"message" callback:^(NSArray * arrayResponse, SocketAckEmitter * ack) {
        [welf onMessageWithResponse:arrayResponse];
    }];
    
    [self.socket on:@"id" callback:^(NSArray * arrayResponse, SocketAckEmitter * ack) {
        [welf onIDWithResponse:arrayResponse];
    }];
}

- (void)onMessageWithResponse:(NSArray*)response {
    if (self.delegate) {
        [self.delegate socketIOManager:self didReceiveMessage:response[0]];
    }
}

- (void)onIDWithResponse:(NSArray*)response {
    if (self.delegate) {
        [self.delegate socketIOManager:self didReceiveIdentifier:response[0]];
    }
}

#pragma mark - Public

- (void)emitMessage:(NSDictionary *)messageDict {
    
    if(!messageDict){
        return;
    }
    
    [self.socket emit:@"message" with:@[messageDict]];
}

- (void)emitReadyToStream:(NSDictionary *)messageDict {
    
    if(!messageDict){
        return;
    }
    
    [self.socket emit:@"readyToStream" with:@[messageDict]];

}

@end
