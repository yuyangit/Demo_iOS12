//
//  DM12NetworkClient.m
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/25.
//  Copyright © 2018 com.babybus. All rights reserved.
//

#import <Network/Network.h>
#include <err.h>
#include <getopt.h>

#import "DM12NetworkClient.h"

@interface DM12NetworkClient ()

@property ( nonatomic, strong ) nw_connection_t connection;

@property ( nonatomic, strong ) DM12CancelCompleteBlock cancelCompleteBlock;

@property ( nonatomic, strong ) DM12RequestBlock requestBlock;

@property ( nonatomic, strong ) NSData *requestData;

@property ( nonatomic, strong ) dispatch_queue_t dataQueue;

@end

@implementation DM12NetworkClient

- (instancetype)init {
    
    if (self = [super init]) {
        self.dataQueue = dispatch_queue_create("com.echoServer.data.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)connect:(NSString *)host port:(NSString *)port {
    self.host = host;
    self.port = port;
    [self create_connection];
}

- (void)cancel:(nullable DM12CancelCompleteBlock)completeBlock {
    
    if (self.connection) {
        nw_connection_cancel(self.connection);
        self.connection = nil;
    }
    __block DM12NetworkClient *weakSelf = self;
    [self setCancelCompleteBlock:^{
        if (
            weakSelf.state == nw_connection_state_cancelled
            ) {
            if (completeBlock) {
                completeBlock();
            }
            weakSelf.state = nw_listener_state_invalid;
            weakSelf.cancelCompleteBlock = nil;
        }
    }];
}

- (void)reconnect:(DM12CancelCompleteBlock)completeBlock {
    
    [self cancel:^{
        if (completeBlock) {
            completeBlock();
        }
    }];
    [self connect:self.host port:self.port];
}

- (void)request:(NSData *)data completeBlock:(DM12SendCompleteBlock)completeBlock {
    
    self.requestData = data;
    __weak DM12NetworkClient *weakSelf = self;
    if (self.state == nw_connection_state_ready) {
        self.requestBlock = nil;
        [self sendWithCompleteBlock:completeBlock];
    }
    else {
        self.requestBlock = ^{
            if (weakSelf.state == nw_connection_state_ready) {
                [weakSelf sendWithCompleteBlock:completeBlock];
                weakSelf.requestBlock = nil;
            }
        };
    }
}

- (void)test1 {

    
}

- (void)test {
    
    // 设置主机和端口
    nw_endpoint_t endpoint = nw_endpoint_create_host("example.com", "8881");
    // 使用系统默认tcp配置
    nw_parameters_t parameters = nw_parameters_create_secure_tcp(
                                                                 NW_PARAMETERS_DISABLE_PROTOCOL,
                                                                 NW_PARAMETERS_DEFAULT_CONFIGURATION);
    
    // 设置接口类型  为 蜂窝网络
    nw_parameters_prohibit_interface_type(parameters, nw_interface_type_cellular);
    nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
    nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
    // 设置ip版本
    nw_ip_options_set_version(ip_options, nw_ip_version_6);
    // 防止代理
    nw_parameters_set_prefer_no_proxy(parameters, true);
    
    // 建立连接
    nw_connection_t connection = nw_connection_create(endpoint, parameters);
    // 监听connection状态变化
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t  _Nullable error) {
        switch (state) {
            case nw_connection_state_ready:
//                连接已建立（connection establish）
                break;
            case nw_connection_state_waiting:
//                等待网络连接
                break;
            case nw_connection_state_failed:
//                连接失败
                break;
            case nw_connection_state_cancelled:
//                连接取消
                break;
            case nw_connection_state_invalid:
//                连接不合法
                break;
            case nw_connection_state_preparing:
//                连接准备中
                break;
            default:
                break;
        }
    });
//    启动connection
    nw_connection_start(connection);
    
    
    // 处理连接的变化
    nw_connection_set_viability_changed_handler(connection, ^(bool value) {
        if (value) {
            // 处理临时失效的连接
        }
        else {
            // 处理恢复的连接
        }
    });

    // 处理更佳的连接
    nw_connection_set_better_path_available_handler(connection, ^(bool value) {
        
        if (value) {
            // 在更加的路径上 创建新的connection 并且迁移到新的connection
        }
        else {
            // 停止迁移
        }
    });
    
}

- (void)create_connection {
    
    nw_endpoint_t endpoint = nw_endpoint_create_host(self.host.UTF8String, self.port.UTF8String);
    nw_parameters_t parameters = NULL;
    nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
    parameters = nw_parameters_create_secure_tcp(configure_tls,
                                                 NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
    nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
    nw_ip_options_set_version(ip_options, nw_ip_version_4);
    self.connection = nw_connection_create(endpoint, parameters);
    [self start_connection];
}

- (void)start_connection {
    
    nw_connection_set_queue(self.connection, dispatch_get_main_queue());
    __weak DM12NetworkClient *weakSelf = self;
    nw_connection_set_state_changed_handler(self.connection, ^(nw_connection_state_t state, nw_error_t  _Nullable error) {
        if (weakSelf.state != state) {
            weakSelf.state = state;
            if (weakSelf.cancelCompleteBlock) {
                weakSelf.cancelCompleteBlock();
            }
            if (weakSelf.requestBlock) {
                weakSelf.requestBlock();
            }
        }
    });
    
    nw_connection_start(self.connection);
}

- (void)sendWithCompleteBlock:(DM12SendCompleteBlock)completeBlock {
    
    dispatch_data_t content = dispatch_data_create(self.requestData.bytes, self.requestData.length, self.dataQueue, ^{
        
    });
    // 批量传送Block
    nw_connection_batch(self.connection, ^{
        nw_connection_send(self.connection, content, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, ^(nw_error_t  _Nullable error) {
            if (error != NULL) {
                NSError *sendError = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"%d", nw_error_get_error_domain(error)] code:nw_error_get_error_code(error) userInfo:nil];
                if (completeBlock) {
                    completeBlock(NO, sendError);
                }
            }
            else {
                if (completeBlock) {
                    completeBlock(YES, nil);
                }
            }
        });
    });
}

@end
