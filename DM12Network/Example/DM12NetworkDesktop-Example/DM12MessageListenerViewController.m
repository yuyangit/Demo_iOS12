//
//  ViewController.m
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/24.
//  Copyright © 2018 com.babybus. All rights reserved.
//
#import "DM12Network.h"

#import "DM12MessageListenerViewController.h"

@interface DM12MessageListenerViewController()

@property ( nonatomic, strong ) DM1NetworkServer *server;

@property (unsafe_unretained) IBOutlet NSTextView *receiveTextView;

@property (weak) IBOutlet NSTextField *ipAddressTextField;

@property (weak) IBOutlet NSTextField *portTextField;

#pragma mark - 监听UI

@property (weak) IBOutlet NSBox *listenerStatusBox;

@property (weak) IBOutlet NSTextField *listenerStatusLabel;

@property (weak) IBOutlet NSButton *bindButton;

#pragma mark - 连接UI

@property (weak) IBOutlet NSBox *connectionStatusBox;

@property (weak) IBOutlet NSTextField *connectionStatusLabel;

@property (weak) IBOutlet NSButton *connectionButton;

@end

@implementation DM12MessageListenerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"服务";
    // Do any additional setup after loading the view.
    [self.server addObserver:self
                  forKeyPath:@"listenerState"
                     options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                     context:nil];
    [self.server addObserver:self
                  forKeyPath:@"connectionState"
                     options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                     context:nil];
    
    [self.server start:DM12_DEFAULT_HOST port:DM12_DEFAULT_PORT];
    self.ipAddressTextField.stringValue = DM12_DEFAULT_HOST;
    self.portTextField.stringValue = DM12_DEFAULT_PORT;
    
    self.listenerStatusBox.fillColor = [NSColor darkGrayColor];
}

- (DM1NetworkServer *)server {
    
    if (_server == nil) {
        _server = [[DM1NetworkServer alloc] init];
        __weak DM12MessageListenerViewController *weakSelf = self;
        [_server setReceiveBlock:^(NSData *data, NSError *error) {
            NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            text = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:text options:NSDataBase64DecodingIgnoreUnknownCharacters] encoding:NSUTF8StringEncoding];
            if (text) {
                [weakSelf.receiveTextView setString:text];
            }
        }];
    }
    
    return _server;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:@"listenerState"]) {
        nw_listener_state_t listenerState= [[change objectForKey:NSKeyValueChangeNewKey] intValue];
        switch (listenerState) {
            case nw_listener_state_ready:
                self.listenerStatusLabel.stringValue = @"绑定成功";
                self.listenerStatusBox.fillColor = [NSColor greenColor];
                [self.bindButton setTitle:@"取消绑定"];
                self.bindButton.enabled = YES;
                break;
            case nw_listener_state_waiting:
                self.listenerStatusLabel.stringValue = @"绑定启动中...";
                self.listenerStatusBox.fillColor = [NSColor yellowColor];
                [self.bindButton setTitle:@"取消绑定"];
                break;
            case nw_listener_state_failed:
                self.listenerStatusLabel.stringValue = @"绑定失败了！";
                self.listenerStatusBox.fillColor = [NSColor redColor];
                [self.bindButton setTitle:@"重新绑定"];
                self.bindButton.enabled = YES;
                break;
            case nw_listener_state_invalid:
                self.listenerStatusLabel.stringValue = @"绑定出现错误了！";
                self.listenerStatusBox.fillColor = [NSColor redColor];
                [self.bindButton setTitle:@"重新绑定"];
                self.bindButton.enabled = YES;
                break;
            case nw_listener_state_cancelled:
                self.listenerStatusLabel.stringValue = @"绑定已经取消了";
                self.listenerStatusBox.fillColor = [NSColor grayColor];
                [self.bindButton setTitle:@"重新绑定"];
                break;
            default:
                self.listenerStatusLabel.stringValue = @"当前无绑定";
                self.listenerStatusBox.fillColor = [NSColor darkGrayColor];
                [self.bindButton setTitle:@"绑定"];
                self.bindButton.enabled = YES;
                break;
        }
    }
    else if ([keyPath isEqualToString:@"connectionState"]) {
        
        nw_connection_state_t conectionState = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
        switch (conectionState) {
            case nw_connection_state_preparing:
                [self hideConnectionInfo];
                break;
                
            case nw_connection_state_waiting:
                [self hideConnectionInfo];
                break;
                
            case nw_connection_state_ready:
                [self showConnectionInfo];
                break;
                
            case nw_connection_state_invalid:
                [self hideConnectionInfo];
                break;
                
            case nw_connection_state_failed:
                [self hideConnectionInfo];
                break;
                
            case nw_connection_state_cancelled:
                [self hideConnectionInfo];
                break;
                
            default:
                break;
        }
        
    }
}

- (IBAction)bindButtonAction:(id)sender {
    
    if (
        self.server.listenerState == nw_listener_state_ready ||
        self.server.listenerState == nw_listener_state_waiting
        ) {
        [self.server cancel:nil];
    }
    else {
        [self.server start:self.ipAddressTextField.stringValue port:self.portTextField.stringValue];
    }
}

- (IBAction)connectionButtonAction:(id)sender {
    
    [self.server disconnect];
}


- (void)showConnectionInfo {
    
    self.connectionStatusBox.hidden = NO;
    self.connectionStatusLabel.hidden = NO;
    self.connectionButton.hidden = NO;
    
    self.connectionStatusLabel.stringValue = self.server.connectionAddress;
}

- (void)hideConnectionInfo {
    
    self.connectionStatusBox.hidden = YES;
    self.connectionStatusLabel.hidden = YES;
    self.connectionButton.hidden = YES;
}

@end
