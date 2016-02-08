//
//  ViewController.m
//  blueUp
//
//  Created by Kuo, Ray on 2/4/16.
//  Copyright © 2016 Kuo, Ray. All rights reserved.
//

#import "ViewController.h"
#import <PTDBeanManager.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>
#import <ParseUI/PFLogInViewController.h>

@interface ViewController () <PTDBeanManagerDelegate, PTDBeanDelegate, PFLogInViewControllerDelegate> {
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

- (void)viewDidAppear:(BOOL)animated {
    [self presentPFLogInViewController];
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)presentPFLogInViewController {
    if (![PFUser currentUser] || // Check if user is cached
        ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) { // Check if user is linked to Facebook
        
        PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
        logInController.delegate = self;
        logInController.fields = (PFLogInFieldsUsernameAndPassword
                                  | PFLogInFieldsFacebook
                                  | PFLogInFieldsDismissButton);
        [self presentViewController:logInController animated:YES completion:nil];
    } else {
        NSLog(@"User is cached and showing content.");
    }
}

- (IBAction)logout:(id)sender {
    [PFUser logOut];
    [self presentPFLogInViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.beans = [NSMutableDictionary dictionary];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    
    
    
//    PFObject *gameScore = [PFObject objectWithClassName:@"GameScore"];
//    gameScore[@"score"] = @1337;
//    gameScore[@"user"] = [PFUser currentUser];
//    [gameScore saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            // The object has been saved.
//        } else {
//            // There was a problem, check error.description
//        }
//    }];
    
    
//    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
//    loginButton.center = self.view.center;
//    [self.view addSubview:loginButton];
//    
//    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
//    
//    // Login PFUser using Facebook
//    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
//        if (!user) {
//            NSLog(@"Uh oh. The user cancelled the Facebook login.");
//        } else if (user.isNew) {
//            NSLog(@"User signed up and logged in through Facebook!");
//        } else {
//            NSLog(@"User logged in through Facebook!");
//        }
//    }];
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
