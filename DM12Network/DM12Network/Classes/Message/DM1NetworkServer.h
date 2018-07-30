//
//  DM1NetworkServer.h
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/25.
//  Copyright © 2018 com.babybus. All rights reserved.
//
#import <Network/Network.h>
#include <err.h>
#include <getopt.h>

#import <Foundation/Foundation.h>
#import "DM12NetworkGlobalDefination.h"

NS_ASSUME_NONNULL_BEGIN

@interface DM1NetworkServer : NSObject

#pragma mark - Listener

@property ( nonatomic, strong ) NSString *host;

@property ( nonatomic, strong ) NSString *port;

@property ( nonatomic, assign ) nw_listener_state_t listenerState;

@property ( nonatomic, strong ) DM12ReceiveBlock receiveBlock;

- (void)start:(NSString *)host port:(NSString *)port;

- (void)cancel:(nullable DM12CancelCompleteBlock)completeBlock;

- (void)receive_loop:(nw_connection_t)connection;

#pragma mark - Connection

@property ( nonatomic, assign ) nw_connection_state_t connectionState;

- (void)disconnect;

- (NSString *)connectionAddress;

@end

NS_ASSUME_NONNULL_END
