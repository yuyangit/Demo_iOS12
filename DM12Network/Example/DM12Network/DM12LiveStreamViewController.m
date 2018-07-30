//
//  DM12LiveStreamViewController.m
//  DM12Network_Example
//
//  Created by YuYang on 2018/7/29.
//  Copyright © 2018 yuyangit. All rights reserved.
//

#import "DM12LiveStreamViewController.h"
#import <AVKit/AVKit.h>
#import <Network/Network.h>

@interface CameraView : UIView

@property ( nonatomic, strong ) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation CameraView

+ (Class)layerClass {
    
    return AVCaptureVideoPreviewLayer.class;
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

@end
@interface DM12LiveStreamViewController ()
<
AVCaptureVideoDataOutputSampleBufferDelegate,
NSStreamDelegate
>

@property ( nonatomic, strong ) AVCaptureSession *session;

@property ( nonatomic, strong ) AVCaptureVideoDataOutput *videoDataOutput;

@property ( nonatomic, strong ) AVCaptureVideoPreviewLayer  *captureVideoPreviewLayer;

@property ( nonatomic, strong ) dispatch_source_t timer;

@property ( nonatomic, strong ) dispatch_queue_t queue;

@property ( nonatomic, strong ) CameraView *cameraView;

@property ( nonatomic, strong ) nw_connection_t connection;

@property ( nonatomic, strong ) dispatch_queue_t dataQueue;

@property ( nonatomic, strong ) dispatch_queue_t connectionQueue;

@end

@implementation DM12LiveStreamViewController

- (void)dealloc {
    [self.session stopRunning];
}

- (CameraView *)cameraView {
    
    if (_cameraView == nil) {
        _cameraView = [[CameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    }
    
    return _cameraView;
}

// 初始化视频输入输出
- (void)setupVideoInputOutput {
    // 添加视频输入源
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInMicrophone, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    AVCaptureDevice *videoDevice = [[discoverySession devices] firstObject];
    if (videoDevice) {
        if (!self.session) {
            self.session = [[AVCaptureSession alloc] init];
        }
        NSError *error = Nil;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (deviceInput) {
            if ([self.session canAddInput:deviceInput]) {
                [self.session addInput:deviceInput];
                self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
                dispatch_queue_t queue = dispatch_queue_create("myQueue",DISPATCH_QUEUE_CONCURRENT);
                [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey]];

                // 实现其代理方法 并实时得到数据
                [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
                if ([self.session canAddOutput:self.videoDataOutput]) {
                    [self.session addOutput:self.videoDataOutput];
                    [self.cameraView.videoPreviewLayer setSession:self.session];
                    self.cameraView.videoPreviewLayer.frame = self.cameraView.bounds;
                    self.cameraView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    [self.session startRunning];
                }
                else {
                    NSLog(@"ERROR: Session cannot add output");
                }
            }
            else {
                NSLog(@"ERROR: Session cannot add input");
            }
        }
        else {
            NSLog(@"ERROR: Create Device Input error: %@",error);
        }
    }
    else {
        NSLog(@"ERROR: Cannot find video Device");
    }
}

- (void)viewWillLayout {
    
    self.captureVideoPreviewLayer.frame = CGRectMake(0, 0, self.view.window.frame.size.width, self.view.window.frame.size.height);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.cameraView];
    [self setupVideoInputOutput];
    self.dataQueue = dispatch_queue_create("com.echoServer.data.queue", DISPATCH_QUEUE_SERIAL);
    self.connectionQueue = dispatch_queue_create("com.echoServer.connection.queue", DISPATCH_QUEUE_SERIAL);

    nw_endpoint_t endpoint = nw_endpoint_create_host("", "8882");
    nw_parameters_t parameters = NULL;
    nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
    parameters = nw_parameters_create_secure_udp(configure_tls, NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
    nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
    nw_ip_options_set_version(ip_options, nw_ip_version_4);
    nw_parameters_set_fast_open_enabled(parameters, true);
    self.connection = nw_connection_create(endpoint, parameters);
    nw_connection_set_queue(self.connection, self.connectionQueue);
    nw_connection_set_state_changed_handler(self.connection, ^(nw_connection_state_t state, nw_error_t  _Nullable error) {
        
    });

    nw_connection_start(self.connection);
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-100, self.view.frame.size.width, 100)];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"关闭" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    [self.view addSubview:button];
}

- (void)buttonAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.captureVideoPreviewLayer.frame = CGRectMake(0,
                                                     0,
                                                     self.view.window.frame.size.width,
                                                     self.view.window.frame.size.height);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    @autoreleasepool {
//        __block CGImageRef imageRef = [self dataFromCMSampleBufferRef:sampleBuffer];
        __block UIImage *image = [self imageFromCMSampleBufferRef:sampleBuffer];
        __block NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
        [self sendWithData:imageData];
        
        // 帧开始
//        NSData *startData = [[NSString stringWithFormat:@"udp.frame.start.%@", @(imageData.length)] dataUsingEncoding:NSUTF8StringEncoding];
//        [self sendWithData:startData];
//        dispatch_sync(dispatch_get_global_queue(0, 0), ^{
//            BOOL isEnd = NO;
//            NSInteger readSize = 0;
//            NSInteger fileSie = imageData.length;
//            NSInteger sendSize = 2019; // udp传输默认大小
//            NSInteger page = 0;
//            while (!isEnd) {
//                NSData *data = nil;
//                NSInteger subleng = fileSie - readSize;
//                if (subleng < sendSize) {
//                    isEnd = YES;
//                    data = [imageData subdataWithRange:NSMakeRange(readSize, subleng)];
//                }
//                else
//                {
//                    data = [imageData subdataWithRange:NSMakeRange(readSize, sendSize)];
//                    readSize += sendSize;
//                }
//
//                if (data) {
//                    data = [[[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength] stringByAppendingString:[NSString stringWithFormat:@".%@", @(page)]] dataUsingEncoding:NSUTF8StringEncoding];
//
//                    [self sendWithData:data];
//                }
//            }
//        });
//        //帧结束
//        NSData *endData = [@"udp.frame.end" dataUsingEncoding:NSUTF8StringEncoding];
//        [self sendWithData:endData];
    }
}

- (void)sendWithData:(NSData *)sendData {
    
    nw_protocol_metadata_t meta = nw_udp_create_metadata();
    nw_ip_metadata_set_service_class(meta, nw_service_class_interactive_video);
    nw_content_context_t context = nw_content_context_create("Signaling");
    nw_content_context_set_metadata_for_protocol(context, meta);
    dispatch_data_t content = dispatch_data_create(sendData.bytes, sendData.length, self.dataQueue, nil);
    nw_connection_send(self.connection, content, context, true, ^(nw_error_t  _Nullable error) {
        if (error != NULL) {
            NSError *sendError = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"%d", nw_error_get_error_domain(error)] code:nw_error_get_error_code(error) userInfo:nil];
            NSLog(@"sendError:%@", sendError);
        }
        else {
        }
    });

}

- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

// CMSampleBufferRef –> CVImageBufferRef –> CGContextRef –> CGImageRef –> UIImage
- (UIImage *)imageFromCMSampleBufferRef:(CMSampleBufferRef)sampleBuffer {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    
    UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    image = [self imageWithImage:image scaledToSize:CGSizeMake(image.size.width*0.05, image.size.height*0.05)];
    CGImageRelease(newImage);
    
    return image;
}

@end
