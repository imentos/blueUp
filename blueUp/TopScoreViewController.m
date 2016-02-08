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
    scoreArray = [query findObjects];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return scoreArray.count;
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
    heightLabel.text = @(height).stringValue;

    return cell;
}

@end
