//
//  DM12NetworkClient.h
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/25.
//  Copyright © 2018 com.babybus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DM12NetworkGlobalDefination.h"

NS_ASSUME_NONNULL_BEGIN

@interface DM12NetworkClient : NSObject

@property ( nonatomic, strong ) NSString *host;

@property ( nonatomic, strong ) NSString *port;

@property ( nonatomic, assign ) nw_connection_state_t state;

- (void)connect:(NSString *)host port:(NSString *)port;

- (void)cancel:(nullable DM12CancelCompleteBlock)completeBlock;

- (void)reconnect:(DM12CancelCompleteBlock)completeBlock;

- (void)request:(NSData *)data completeBlock:(DM12SendCompleteBlock)completeBlock;

@property ( nonatomic, strong ) DM12ReceiveBlock receiveBlock;
@property ( nonatomic, strong ) DM12ResponseBlock responseBlock;

@end

NS_ASSUME_NONNULL_END
