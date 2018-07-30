//
//  DM12LiveStreamListenerViewController.m
//  DM12NetworkDesktop-Example
//
//  Created by YuYang on 2018/7/29.
//  Copyright © 2018 yuyangit. All rights reserved.
//

#import "DM12LiveStreamListenerViewController.h"
#import <Network/Network.h>
#include <err.h>
#include <getopt.h>

#define DM12LiveStreamNetworkType = "_networklivestream._udp."
#define DM12LiveStreamNetworkDomain = "local"


@interface DM12LiveStreamListenerViewController ()

@property (weak) IBOutlet NSImageView *imageView;

@property ( nonatomic, strong ) nw_connection_t connection;

@property ( nonatomic, strong ) nw_listener_t listener;

@property ( nonatomic, strong ) NSMutableData *data;

@property ( nonatomic, strong ) dispatch_queue_t listenerQueue;

@property ( nonatomic, assign ) NSInteger dataTotalSize;

@end

@implementation DM12LiveStreamListenerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    __weak DM12LiveStreamListenerViewController *weakSelf = self;
    self.listenerQueue = dispatch_queue_create("listener.queue", DISPATCH_QUEUE_SERIAL);
    nw_parameters_t parameters = NULL;
    
    nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
    parameters = nw_parameters_create_secure_udp(configure_tls, NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
    nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
    nw_ip_options_set_version(ip_options, nw_ip_version_4);
    nw_endpoint_t local_endpoint = nw_endpoint_create_host("192.168.31.237", "8882");
    nw_parameters_set_local_endpoint(parameters, local_endpoint);
    self.listener = nw_listener_create(parameters);
    nw_listener_set_queue(self.listener, self.listenerQueue);
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
            
        }
    });
    nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
        if (weakSelf.connection != NULL) {
            nw_connection_cancel(weakSelf.connection);
            weakSelf.connection = nil;
        }
        
        weakSelf.connection = connection;
        [weakSelf start_connection:connection];
        [weakSelf receive_loop:connection];
    });
    
    nw_listener_start(self.listener);
}

- (NSMutableData *)data {
    
    if (_data == nil) {
        _data = [NSMutableData data];
    }
    
    return _data;
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
                if (data) {
                    NSImage *image = [[NSImage alloc] initWithData:data];
//                    self.imageView.image = image;
                    self.imageView.layer = [[CALayer alloc] init];
                    self.imageView.layer.contentsGravity = kCAGravityResizeAspectFill;
                    self.imageView.layer.contents = image;
                    self.imageView.wantsLayer = YES;
                }
                
                return true;
            });
        }
        schedule_next_receive();
    });
}

- (void)start_connection:(nw_connection_t)connection {
    
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t  _Nullable error) {
    });
    nw_connection_start(connection);
}


@end
