//
//  CounterView.m
//  blueUp
//
//  Created by Kuo, Ray on 2/11/16.
//  Copyright © 2016 Kuo, Ray. All rights reserved.
//

#import "CounterView.h"

@interface CounterView() {
    int count;
    NSTimer* timer;
}
@end

@implementation CounterView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.alpha = 0.0;
        
    }
    return self;
}

-(void)start {
    count = 3;
    timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
    [self setAlpha:1.0];
    [UIView animateWithDuration:0.5 animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    }];
}

-(void)onTick:(NSTimer *)timer {
    if (count > 1) {
        [UIView animateWithDuration:0.5 animations:^{
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);

        } completion:^(BOOL finished) {
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);

        }];
        
    } else {
        [timer invalidate];
//        [self setAlpha:0.0];
    }
    [self setNeedsDisplay];
    count--;
}

-(void)drawRect:(CGRect)rect {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:80.0f];
    NSString* text = count == 0 ? @"Go" : @(count).stringValue;
    [text drawAtPoint:CGPointMake(30, 30) withAttributes:@{NSFontAttributeName: font}];
}

@end
