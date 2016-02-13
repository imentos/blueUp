//
//  TopScoreViewController.m
//  blueUp
//
//  Created by Kuo, Ray on 2/8/16.
//  Copyright © 2016 Kuo, Ray. All rights reserved.
//

#import "TopScoreViewController.h"
#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface TopScoreViewController () {
    NSArray* scoreArray;
}

@end

@implementation TopScoreViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Score"];
    [query orderByDescending:@"height"];
    query.limit = 5;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        scoreArray = objects;
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return scoreArray.count;
}

-(void)updateUserPhoto:(FBSDKProfilePictureView*)userPhoto fid:(NSString *)fid {
    userPhoto.layer.borderWidth = 0;
    userPhoto.layer.masksToBounds = YES;
    userPhoto.layer.cornerRadius = userPhoto.bounds.size.height / 2;
    [userPhoto setProfileID:fid];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject* score = [scoreArray objectAtIndex:indexPath.row];
    float height = [[score objectForKey:@"height"] floatValue];
    NSLog(@"height:%f", height);
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"score" forIndexPath:indexPath];
    
    UILabel* userLabel = [cell viewWithTag:101];
    PFUser* user = [score objectForKey:@"user"];
    [user fetchIfNeeded];
    NSString* fid = user[@"facebookId"];
    [self updateUserPhoto:[cell viewWithTag:201] fid:fid];

    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:fid parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error) {
                 NSLog(@"fetched user:%@", result);
                 userLabel.text = result[@"name"];
             }
         }];
    }
    
    UILabel* heightLabel = [cell viewWithTag:102];
    heightLabel.text = [NSString stringWithFormat:@"%.02fm", height];

    return cell;
}

@end
