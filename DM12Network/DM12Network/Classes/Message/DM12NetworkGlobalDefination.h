//
//  DM12NetworkGlobalDefination.h
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/25.
//  Copyright © 2018 com.babybus. All rights reserved.
//

#ifndef DM12NetworkGlobalDefination_h
#define DM12NetworkGlobalDefination_h

typedef void(^DM12ReceiveBlock)(NSData *data, NSError *error);
typedef NSData *(^DM12ResponseBlock)(void);
typedef void(^DM12RequestBlock)(void);

typedef void(^DM12SendCompleteBlock)(BOOL finish, NSError *error);
typedef void(^DM12ClientReadyBlock)(void);
typedef void(^DM12CancelCompleteBlock)(void);

#define DM12_DEFAULT_HOST @"10.1.6.162"
#define DM12_DEFAULT_PORT @"8881"

#endif /* DM12NetworkGlobalDefination_h */
