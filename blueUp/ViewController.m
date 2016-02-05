//
//  ViewController.m
//  blueUp
//
//  Created by Kuo, Ray on 2/4/16.
//  Copyright © 2016 Kuo, Ray. All rights reserved.
//

#import "ViewController.h"
#import <PTDBeanManager.h>

@interface ViewController () <PTDBeanManagerDelegate, PTDBeanDelegate> {
    NSNumber *startTime;
    NSNumber *endTime;
    BOOL isDown;
    BOOL isEnd;
}
@property (strong, nonatomic) IBOutlet UIButton *connectBtn;
@property (strong, nonatomic) IBOutlet UILabel *infoText;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSMutableDictionary *beans;
@end

@implementation ViewController

-(void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // draw sky
    // draw mountains
    // draw grass
    // draw flowers
    
    CGColorSpaceRelease(colorSpace);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.beans = [NSMutableDictionary dictionary];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)readAccelerometer:(id)sender {
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
    isDown = NO;
}

-(void)onTick:(NSTimer *)timer {
    PTDBean* bean = [self.beans.allValues objectAtIndex:0];
    [bean readAccelerationAxes];
}


#pragma mark BeanDelegate
-(void)bean:(PTDBean*)device error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}

-(void)bean:(PTDBean*)device receivedMessage:(NSData*)data {
}

-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {
    NSString *msg = [NSString stringWithFormat:@"x:%f y:%f z:%f", acceleration.x,acceleration.y,acceleration.z];
    
    float sum = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2));
    self.infoText.text = [NSString stringWithFormat:@"%f", sum];
//    NSLog(@"sum: %f", sum);
    
    if (isDown == NO && sum > 2.0) {
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        startTime = [NSNumber numberWithDouble: timeStamp];
        NSLog(@"up: %f", sum);
        isDown = NO;

    } else if (sum < 0.098) {
        NSLog(@"top: %f", sum);
        isDown = YES;
    }
    
    if (isDown && sum > 0.98) {
        NSLog(@"ground: %f", sum);
        isDown = NO;
    
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        endTime = [NSNumber numberWithDouble: timeStamp];
        NSNumber* total = [NSNumber numberWithDouble:[endTime doubleValue] - [startTime doubleValue]];
        NSLog(@"total: %@", total);
        
        float t = [total floatValue];
        float height = pow(t, 2) * 9.8 / 8;
        NSLog(@"height:%f", height);
              
    }
    
    //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    //    [alert show];
}




#pragma mark - BeanManagerDelegate Callbacks
- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        self.infoText.text = @"Scanning...";
        [self.beanManager startScanningForBeans_error:nil];
    }
    else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Turn on bluetooth to continue" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    NSUUID * key = bean.identifier;
    if (![self.beans objectForKey:key]) {
        // New bean
        self.infoText.text = [NSString stringWithFormat:@"Discover bean %@", bean];
        NSLog(@"BeanManager:didDiscoverBean:error %@", bean);
        [self.beans setObject:bean forKey:key];
        
        [self.beanManager connectToBean:bean error:nil];
        self.beanManager.delegate = self;
        bean.delegate = self;
    }
    //    [self.tableView reloadData];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    //    [self.tableView reloadData];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    //    [self.tableView reloadData];
}


@end
