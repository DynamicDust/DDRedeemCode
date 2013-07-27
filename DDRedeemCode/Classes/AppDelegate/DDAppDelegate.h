//
//  DDAppDelegate.h
//  DDRedeemCode
//
//  Created by Dominik Hádl on 7/26/13.
//  Copyright (c) 2013 DynamicDust s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDViewController;

@interface DDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DDViewController *viewController;

@end
