//
//  ViewController.m
//  DM12NetworkFramework
//
//  Created by YuYang on 2018/7/24.
//  Copyright © 2018 com.babybus. All rights reserved.
//
#import <DM12Network/DM12Network.h>

#import "DM12MessageViewController.h"

@interface DM12MessageViewController()
<
UITextFieldDelegate
>

@property ( nonatomic, strong ) DM12NetworkClient *client;

@property ( nonatomic, assign ) NSInteger count;

@property (weak, nonatomic) IBOutlet UITextField *hostTextView;

@property (weak, nonatomic) IBOutlet UITextField *portTextView;

@property (weak, nonatomic) IBOutlet UIButton *connectionButton;

@property (weak, nonatomic) IBOutlet UIView *connectionStatusView;

@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;

@property (weak, nonatomic) IBOutlet UITextView *sendTextView;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation DM12MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.client addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    [self.client connect:DM12_DEFAULT_HOST port:DM12_DEFAULT_PORT];
    
    self.hostTextView.text = DM12_DEFAULT_HOST;
    self.portTextView.text = DM12_DEFAULT_PORT;
    
    self.sendTextView.delegate = self;
    
    self.client.host = self.hostTextView.text;
    self.client.port = self.portTextView.text;
    
    self.view.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:1.0];
}

- (DM12NetworkClient *)client {
    
    if (_client == nil) {
        _client = [[DM12NetworkClient alloc] init];
    }
    
    return _client;
}

- (IBAction)sendButtonAction:(id)sender {
    
    self.client.host = self.hostTextView.text;
    self.client.port = self.portTextView.text;
    
    NSString *textBase64 = [[self.sendTextView.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    __block NSData *data = [textBase64 dataUsingEncoding:NSUTF8StringEncoding];
    __weak DM12MessageViewController *weakSelf = self;
    if (self.client.state == nw_connection_state_cancelled ||
        self.client.state == nw_connection_state_failed ||
        self.client.state == nw_connection_state_invalid) {
        [self.client reconnect:^{
            [weakSelf.client request:data completeBlock:^(BOOL finish, NSError *error) {
            }];
        }];
    }
    else {
        [self.client request:data completeBlock:^(BOOL finish, NSError *error) {}];
    }
}

- (IBAction)connectionButtonAction:(id)sender {
    
    if (
        self.client.state == nw_connection_state_ready ||
        self.client.state == nw_connection_state_waiting ||
        self.client.state == nw_connection_state_preparing
        ) {
        [self.client cancel:nil];
    }
    else {
        [self.client connect:self.hostTextView.text port:self.portTextView.text];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:@"state"]) {
        nw_connection_state_t state = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
        switch (state) {
            case nw_connection_state_ready:
                self.connectionStatusLabel.text = @"连接成功";
                self.connectionStatusView.backgroundColor = [UIColor greenColor];
                [self.connectionButton setTitle:@"断开连接" forState:UIControlStateNormal];
                self.connectionButton.enabled = YES;
                break;
            case nw_connection_state_waiting:
                self.connectionStatusLabel.text = @"连接中...";
                self.connectionStatusView.backgroundColor = [UIColor yellowColor];
                [self.connectionButton setTitle:@"断开连接" forState:UIControlStateNormal];
                break;
            case nw_connection_state_preparing:
                self.connectionStatusLabel.text = @"连接准备中...";
                self.connectionStatusView.backgroundColor = [UIColor yellowColor];
                [self.connectionButton setTitle:@"断开连接" forState:UIControlStateNormal];
                break;
            case nw_connection_state_failed:
                self.connectionStatusLabel.text = @"连接失败了！";
                self.connectionStatusView.backgroundColor = [UIColor redColor];
                [self.connectionButton setTitle:@"重新连接" forState:UIControlStateNormal];
                self.connectionButton.enabled = YES;
                break;
            case nw_connection_state_invalid:
                self.connectionStatusLabel.text = @"连接断开！";
                self.connectionStatusView.backgroundColor = [UIColor redColor];
                [self.connectionButton setTitle:@"连接" forState:UIControlStateNormal];
                self.connectionButton.enabled = YES;
                break;
                
            case nw_connection_state_cancelled:
                self.connectionStatusLabel.text = @"连接已经取消了";
                self.connectionStatusView.backgroundColor = [UIColor grayColor];
                [self.connectionButton setTitle:@"重新连接" forState:UIControlStateNormal];
                break;
            default:
                self.connectionStatusLabel.text = @"当前无连接";
                self.connectionStatusView.backgroundColor = [UIColor darkGrayColor];
                [self.connectionButton setTitle:@"连接" forState:UIControlStateNormal];
                self.connectionButton.enabled = YES;
                break;
        }
    }
}

- (IBAction)tapGestureAction:(id)sender {
    
    [self.sendTextView resignFirstResponder];
    [self.portTextView resignFirstResponder];
    [self.hostTextView resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    
    
    return YES;
}

- (IBAction)closeButtonAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
