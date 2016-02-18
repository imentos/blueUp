//
//  InfoViewController.m
//  Blue Up
//
//  Created by Kuo, Ray on 2/17/16.
//  Copyright © 2016 Kuo, Ray. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController() <UIPageViewControllerDataSource, UIPageViewControllerDelegate> {
}
@property (retain, nonatomic) NSArray *pages;

@end

@implementation InfoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.delegate = self;
    self.dataSource = self;
    
    UIViewController* page1 = [self.storyboard instantiateViewControllerWithIdentifier:@"page1"];
    UIViewController* page2 = [self.storyboard instantiateViewControllerWithIdentifier:@"page2"];
    UIViewController* page3 = [self.storyboard instantiateViewControllerWithIdentifier:@"page3"];
    self.pages = [NSArray arrayWithObjects:page1,page2,page3,nil];

    [self setViewControllers:[NSArray arrayWithObject:page1] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        //
    }];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger currentIndex = [self.pages indexOfObject:viewController];
    NSInteger previousIndex = ((currentIndex - 1) % self.pages.count);
    return self.pages[previousIndex];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger currentIndex = [self.pages indexOfObject:viewController];
    NSInteger nextIndex = ((currentIndex + 1) % self.pages.count);
    return self.pages[nextIndex];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController NS_AVAILABLE_IOS(6_0) {
    return self.pages.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController NS_AVAILABLE_IOS(6_0) {
    return 0;
}

@end
