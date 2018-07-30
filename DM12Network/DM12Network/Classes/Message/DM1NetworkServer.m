//
//  DM1NetworkServer.m
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/25.
//  Copyright © 2018 com.babybus. All rights reserved.
//

#import "DM1NetworkServer.h"

@interface DM1NetworkServer()

@property ( nonatomic, strong ) nw_connection_t connection;

@property ( nonatomic, strong ) nw_listener_t listener;

@property ( nonatomic, strong ) NSData *responseData;

@property ( nonatomic, strong ) dispatch_queue_t dataQueue;

@property ( nonatomic, strong ) DM12CancelCompleteBlock cancelCompleteBlock;

@property ( nonatomic, strong ) DM12ClientReadyBlock readyBlock;

@end

@implementation DM1NetworkServer

- (instancetype)init {
    
    if (self = [super init]) {
         self.dataQueue = dispatch_queue_create("com.echoServer.data.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - Listener

- (void)start:(NSString *)host port:(NSString *)port {
    
    self.host = host;
    self.port = port;
    [self configListener];
}

- (void)cancel:(nullable DM12CancelCompleteBlock)completeBlock {
    
    if (self.connection) {
        nw_connection_cancel(self.connection);
        self.connection = nil;
    }
    
    if (self.listener) {
        nw_listener_cancel(self.listener);
        self.listener = nil;
    }
    
    [self setCancelCompleteBlock:^{
        if (
            self.listenerState == nw_listener_state_cancelled
            ) {
            if (completeBlock) {
                completeBlock();
            }
        }
    }];
}

- (void)configListener {
    
    if (
        self.host != nil && self.host.length > 0 &&
        self.port != nil && self.port.length > 0) {
        __weak DM1NetworkServer *weakSelf = self;
        nw_parameters_t parameters = NULL;
        
        nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
        parameters = nw_parameters_create_secure_tcp(configure_tls, NW_PARAMETERS_DEFAULT_CONFIGURATION);
        nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
        nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
        nw_ip_options_set_version(ip_options, nw_ip_version_4);
        nw_endpoint_t local_endpoint = nw_endpoint_create_host(self.host.UTF8String, self.port.UTF8String);
        nw_parameters_set_local_endpoint(parameters, local_endpoint);
        self.listener = nw_listener_create(parameters);
        nw_listener_set_queue(self.listener, dispatch_get_main_queue());
        nw_listener_set_state_changed_handler(self.listener, ^(nw_listener_state_t state, nw_error_t error) {
            if (state == nw_listener_state_waiting) {
                fprintf(stderr, "Listener on port %u (%s) waiting\n", nw_listener_get_port(self.listener), "tcp");
            }
            else if (state == nw_listener_state_failed) {
                warn("listener (%s) failed", "tcp");
            }
            else if (state == nw_listener_state_ready) {
                fprintf(stderr, "Listener on port %u (%s) ready!\n",
                        nw_listener_get_port(self.listener),
                        "tcp");
            }
            else if (state == nw_listener_state_cancelled) {
                if (self.cancelCompleteBlock) {
                    self.cancelCompleteBlock();
                }
            }
            self.listenerState = state;
        });
        nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
            if (weakSelf.connection != NULL) {
                nw_connection_cancel(weakSelf.connection);
                weakSelf.connection = nil;
            }
            
            weakSelf.connection = connection;
            [weakSelf start_connection:connection];
            [weakSelf setReadyBlock:^{
                if (weakSelf.connectionState == nw_connection_state_ready) {
                    [weakSelf receive_loop:weakSelf.connection];
                    weakSelf.readyBlock = nil;
                }
            }];
        });
        
        nw_listener_start(self.listener);
    }
}

- (void)receive_loop:(nw_connection_t)connection {
    
    nw_connection_receive(connection, 1, UINT32_MAX, ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t receive_error) {
        dispatch_block_t schedule_next_receive = ^{
            if (
                is_complete &&
                context != NULL &&
                nw_content_context_get_is_final(context)
                ) {
                nw_connection_cancel(self.connection);
                self.connection = nil;
                return;
            }
            if (receive_error == NULL) {
                [self receive_loop:connection];
            }
        };
        
        if (content != NULL) {
            dispatch_data_apply(content, ^bool(dispatch_data_t  _Nonnull region, size_t offset, const void * _Nonnull buffer, size_t size) {
                NSData *data = [[NSData alloc] initWithBytes:buffer length:size];
                NSError *error = nil;
                if (receive_error != nil) {
                    error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"%d", nw_error_get_error_domain(receive_error)]
                                                       code:nw_error_get_error_code(receive_error)
                                                   userInfo:nil];
                }
                
                if (self.receiveBlock) {
                    self.receiveBlock(data, error);
                }
                
                return true;
            });
        }
        schedule_next_receive();
    });
}


#pragma mark - Connection

- (void)disconnect {
    
    if (self.connection) {
        nw_connection_cancel(self.connection);
        self.connection = nil;
    }
}

- (void)start_connection:(nw_connection_t)connection {
    
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t  _Nullable error) {
        if (self.connectionState != state) {
            self.connectionState = state;
            if (self.readyBlock) {
                self.readyBlock();
            }
        }
    });
    nw_connection_start(connection);
}


- (NSString *)connectionAddress {
    
    nw_endpoint_t endPoint = nw_connection_copy_endpoint(self.connection);
    const char *address = nw_endpoint_copy_address_string(endPoint);
    return [NSString stringWithUTF8String:address];
}

@end
