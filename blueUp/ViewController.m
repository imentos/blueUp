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
#import "CounterView.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface ViewController () <PTDBeanManagerDelegate, PTDBeanDelegate, PFLogInViewControllerDelegate> {
    NSNumber *startTime;
    NSNumber *endTime;
    NSTimer *timer;
    BOOL isDown;
    BOOL isUp;
}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBtn;
@property (strong, nonatomic) IBOutlet CounterView *counter;
@property (strong, nonatomic) IBOutlet UITextView *infoTextView;
@property (strong, nonatomic) IBOutlet UIButton *logoutBtn;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet FBSDKProfilePictureView *userPhoto;
@property (strong, nonatomic) IBOutlet UIButton *connectBtn;
@property (strong, nonatomic) IBOutlet UILabel *infoText;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, strong) NSMutableDictionary *beans;
@end

@implementation ViewController

-(IBAction)unwind:(UIStoryboardSegue *)segue {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.beans = [NSMutableDictionary dictionary];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    self.beanManager.delegate = self;
    
    self.connectBtn.enabled = NO;
    [self.connectBtn setImage:[[UIImage imageNamed:@"up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    self.nameLabel.font = [UIFont fontWithName:@"Geogrotesque-Regular" size:20];
    self.infoTextView.text = @"Click UP button above, wait for GO, and throw your bean from your hand as high as possible to break the records";
    
    self.userPhoto.layer.borderWidth = 0;
    self.userPhoto.layer.masksToBounds = YES;
    self.userPhoto.layer.cornerRadius = self.userPhoto.bounds.size.height / 2;
    
    self.toolbar.clipsToBounds = YES;
    
    UIImage *image = [[UIImage imageNamed:@"logout"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.logoutBtn setImage:image forState:UIControlStateNormal];
    
    //    [self.counter start];
}

- (void)viewDidAppear:(BOOL)animated {
    [self presentPFLogInViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self showUserInfo];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)presentPFLogInViewController {
    if (![PFUser currentUser] || // Check if user is cached
        ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) { // Check if user is linked to Facebook
        
        PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
        logInController.delegate = self;
        logInController.fields = (PFLogInFieldsFacebook);
        logInController.logInView.backgroundColor = UIColorFromRGB(0x009AED);
        UIImageView* logoView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo"]];
        logoView.contentMode = UIViewContentModeScaleAspectFill;
        logInController.logInView.logo = logoView;
        [self presentViewController:logInController animated:YES completion:nil];
    } else {
        NSLog(@"User is cached and showing content.");
        
        [self showUserInfo];
    }
}

- (IBAction)logout:(id)sender {
    [PFUser logOut];
    [self presentPFLogInViewController];
}

- (void)showUserInfo {
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error) {
                 NSLog(@"fetched user:%@", result);
                 PFObject *user = [PFUser currentUser];
                 user[@"facebookId"] = result[@"id"];
                 self.nameLabel.text = [NSString stringWithFormat:@"Welcome %@", result[@"name"]];
                 [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                     if (succeeded) {
                         // The object has been saved.
                     } else {
                         // There was a problem, check error.description
                     }
                 }];
             }
         }];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.bean != nil) {
        [self.beanManager disconnectBean:self.bean error:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connect:(id)sender {
    if (self.bean.state == BeanState_Discovered) {
        self.bean.delegate = self;
        [self.beanManager connectToBean:self.bean error:nil];
        self.beanManager.delegate = self;
        
        self.infoText.text = @"Connecting...";
        self.connectBtn.enabled = NO;
        //        [self.counter start];
        
    } else {
        self.bean.delegate = self;
        [self.beanManager disconnectBean:self.bean error:nil];
    }
}

- (void)update {
    if (self.bean.state == BeanState_Discovered) {
        //        [self.connectBtn setTitle:@"Connect" forState:UIControlStateNormal];
        self.connectBtn.enabled = YES;
        
        [timer invalidate];
    }
    else if (self.bean.state == BeanState_ConnectedAndValidated) {
        //        [self.connectBtn setTitle:@"Disconnect" forState:UIControlStateNormal];
        self.connectBtn.enabled = NO;
        
        [self startReadAccelerationAxes];
    }
}

-(void)drawRect:(CGRect)rect{
    NSLog(@"draw");
}

-(void)startReadAccelerationAxes {
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
    isDown = NO;
    isUp = NO;
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

/////////////////////////
// MAIN LOGIC
/////////////////////////
-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {
    NSString *msg = [NSString stringWithFormat:@"x:%f y:%f z:%f", acceleration.x,acceleration.y,acceleration.z];
    
    float sum = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2));
    //    self.infoText.text = [NSString stringWithFormat:@"%f", sum];
    NSLog(@"sum: %f", sum);
    
    // blue is thrown up (2g)
    if (isUp == NO && sum > 2.0) {
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        startTime = [NSNumber numberWithDouble: timeStamp];
        NSLog(@"up: %f", sum);
        isUp = YES;
        
    }
    // blue is weightless (0g)
    else if (isUp && sum < 0.098) {
        NSLog(@"top: %f", sum);
        isDown = YES;
    }
    
    // blue is on your hand now (1g)
    else if (isDown && sum > 0.98) {
        NSLog(@"ground: %f", sum);
        isDown = NO;
        
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        endTime = [NSNumber numberWithDouble: timeStamp];
        NSNumber* total = [NSNumber numberWithDouble:[endTime doubleValue] - [startTime doubleValue]];
        NSLog(@"total: %@", total);
        
        float t = [total floatValue];
        float height = pow(t, 2) * 9.8 / 8;
        NSLog(@"height:%f", height);
        
        PFObject *score = [PFObject objectWithClassName:@"Score"];
        score[@"height"] = @(height);
        score[@"user"] = [PFUser currentUser];
        [score saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                self.infoText.text = [NSString stringWithFormat:@"Height: %.02fm", height];
                
                [self.beanManager disconnectFromAllBeans:nil];
            } else {
                // There was a problem, check error.description
            }
        }];
    }
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
        
        self.connectBtn.enabled = NO;
        self.infoText.text = @"Turn on bluetooth to continue";
        [self.beans removeAllObjects];
        return;
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    NSUUID * key = bean.identifier;
    if (![self.beans objectForKey:key]) {
        // New bean
        self.infoText.text = [NSString stringWithFormat:@"Your bean '%@'", bean.name];
        NSLog(@"BeanManager:didDiscoverBean:error %@", bean);
        [self.beans setObject:bean forKey:key];
        self.bean = bean;
        
        self.connectBtn.enabled = YES;
    }
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
    [self update];
    
    self.infoText.text = @"GO";
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    if (bean == self.bean) {
        [self update];
    }
}

- (void)composePost:(float)height type:(NSString*)type {
    if ([SLComposeViewController isAvailableForServiceType:type]) {
        SLComposeViewController *sheet = [SLComposeViewController composeViewControllerForServiceType:type];
        [sheet setInitialText:[NSString stringWithFormat:@"I threw my LightBlue Bean up to %0.2fm height. Do you want to challenge me?", height]];
        [sheet addURL:@""];
        [sheet addImage:[UIImage imageNamed:@"AppIcon40x40"]];
        [sheet setCompletionHandler:^(SLComposeViewControllerResult result) {
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    NSLog(@"Post Canceled");
                    break;
                case SLComposeViewControllerResultDone:
                    NSLog(@"Post Sucessful");
                    break;
                default:
                    break;
            }
        }];
        [self presentViewController:sheet animated:YES completion:nil];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Facebook" message:@"Facebook not available" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)shareSocial:(id)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"Score"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable scores, NSError * _Nullable error) {
        if (scores.count == 0) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:@"You don't have any scores yet." preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        float height = [[[scores objectAtIndex:0] objectForKey:@"height"] floatValue];
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:@"Tell Your Friends!"preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Share on Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self composePost:height type:SLServiceTypeFacebook];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Post on Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self composePost:height type:SLServiceTypeTwitter];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
