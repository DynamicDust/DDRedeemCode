//
//  DDViewController.m
//  DDRedeemCode
//
//  Created by Dominik Hádl on 7/26/13.
//  Copyright (c) 2013 DynamicDust s.r.o. All rights reserved.
//

#import "DDViewController.h"
#import "DDRedeemCode.h"

@interface DDViewController ()

@end

@implementation DDViewController

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        
        // Create Redeem Button
        _redeemButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_redeemButton setFrame:CGRectMake(0, 0, (self.view.frame.size.width/2), (self.view.frame.size.height*0.1))];
        [_redeemButton setTitle:@"Redeem Press Code" forState:UIControlStateNormal];
        [_redeemButton addTarget:self action:@selector(redeemPressCode) forControlEvents:UIControlEventTouchUpInside];
        [_redeemButton setCenter:CGPointMake((self.view.frame.size.width/2), (self.view.frame.size.height/2))];
        [self.view addSubview:_redeemButton];
    }
    return self;
}

- (void)redeemPressCode {
    [DDRedeemCode showPressCodeAlertWithCompletionBlock:^(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus){
        NSLog(@"Block works! Code is valid: %@. Code type: %s and status: %s.", validCode ? @"YES!" : @"NO!", stringFromDDRedeemCodeType(codeType), stringFromDDRedeemCodeStatus(codeStatus));
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
