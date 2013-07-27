//
//  DDRedeemCode.m
//  DDRedeemCode
//
//  Created by Dominik Hádl on 7/26/13.
//  Copyright (c) 2013 DynamicDust s.r.o. All rights reserved.
//--------------------------------------------------------------

#import "DDRedeemCode.h"
#import <CommonCrypto/CommonDigest.h>
#import "zlib.h"

// Thanks to JeremyP on SO - http://stackoverflow.com/a/7792687/1001803
#define AntiARCRetain(...) void *retainedThing = (__bridge_retained void *)__VA_ARGS__; retainedThing = retainedThing
#define AntiARCRelease(...) void *retainedThing = (__bridge void *) __VA_ARGS__; id unretainedThing = (__bridge_transfer id)retainedThing; unretainedThing = nil


#define DD_BUNDLE_ID            [[NSBundle mainBundle] bundleIdentifier]
#define DD_CURRENT_TIME         CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(), CFTimeZoneCopySystem())
#define DD_CURRENT_TIME_WEEK    CFAbsoluteTimeGetWeekOfYear(CFAbsoluteTimeGetCurrent(), CFTimeZoneCopySystem())

#ifdef DEBUG
#define DD_LOGGING              1
#endif

@implementation NSData (CRC)

static uint32_t defPoly = 0xEDB88320L;
static uint32_t defSeed = 0xFFFFFFFFL;

void CRC32Table(uint32_t *table, uint32_t poly)
{
    for (uint32_t i = 0; i <= 255; i++)
    {
        uint32_t CRC = i;
        
        for (uint32_t j = 8; j > 0; j--)
        {
            if ((CRC & 1) == 1) {
                
                CRC = (CRC >> 1) ^ poly;
                
            } else {
                
                CRC >>= 1;
                
            }
        }
        
        table[i] = CRC;
        
    }
}

-(uint32_t)CRC32
{
    return [self CRC32WithSeed:defSeed andPoly:defPoly];
}

-(uint32_t)CRC32WithSeed:(uint32_t)seed
{
    return [self CRC32WithSeed:seed andPoly:defPoly];
}

-(uint32_t)CRC32WithPoly:(uint32_t)poly
{
    return [self CRC32WithSeed:defSeed andPoly:poly];
}

-(uint32_t)CRC32WithSeed:(uint32_t)seed andPoly:(uint32_t)poly
{
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    CRC32Table(table, poly);
    
    uint32_t CRC        = seed;
    uint8_t *bytes     = (uint8_t *)[self bytes];
    uint32_t length     = [self length];
    
    while (length--)
    {
        CRC = (CRC>>8) ^ table[(CRC & 0xFF) ^ *bytes++];
    }
    
    free(table);
    return CRC ^ defSeed;
}

@end


@implementation DDRedeemCode {
    DDRedeemCodeType _codeType;
}

+ (void)showPressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType))completionBlock {
    DDRedeemCode *pressCode = [[self alloc] initWithCompletionBlock:completionBlock];
    AntiARCRetain(pressCode);
    [pressCode showRedeemAlert];
}

+ (instancetype)pressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType))completionBlock {
    DDRedeemCode *pressCode = [[self alloc] initWithCompletionBlock:completionBlock];
    AntiARCRetain(pressCode);
    return pressCode;
}


- (instancetype)initWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType))completionBlock {
    self = [super init];
    
    if (self) {
        self.completionBlock = completionBlock;
    }
    return self;
}

- (void)showRedeemAlert {
    UIAlertView *redeemView = [[UIAlertView alloc] initWithTitle: @"Redeem Press Code"
                                                         message: @"Enter your redeem code to unlock press version of this application."
                                                        delegate: self
                                               cancelButtonTitle: @"Cancel"
                                               otherButtonTitles: @"Redeem", nil];
    
    redeemView.alertViewStyle = UIAlertViewStylePlainTextInput;
    redeemView.delegate = self;
    [redeemView show];
}

- (BOOL)isRedeemCodeValid:(NSString *)redeemCode {
    
    uint32_t redeemCodeInt = [redeemCode intValue];
    
    // Base data
    NSData *data = [DD_BUNDLE_ID dataUsingEncoding:NSUTF8StringEncoding];
    
    
    // hour-code seed
    uint32_t hourSeed       = [DD_MASTER_SECRET intValue] + DD_CURRENT_TIME.hour + DD_CURRENT_TIME.day + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
    
    // day-code seed
    uint32_t daySeed        = [DD_MASTER_SECRET intValue] + DD_CURRENT_TIME.day + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
    
    // week-code seed
    uint32_t weekSeed       = [DD_MASTER_SECRET intValue] + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
    
    // month-code seed
    uint32_t monthSeed      = [DD_MASTER_SECRET intValue] + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
    
    // year-code seed
    uint32_t yearSeed       = [DD_MASTER_SECRET intValue] + DD_CURRENT_TIME.year;
    
    // master-code seed
    uint32_t masterSeed     = [DD_MASTER_SECRET intValue];
    
    if (DD_LOG_CODES == 1) {
        NSLog(@"Valid code for this hour: %u.", [data CRC32WithSeed:hourSeed]);
        NSLog(@"Valid code for this day: %u.", [data CRC32WithSeed:daySeed]);        
        NSLog(@"Valid code for this week: %u.", [data CRC32WithSeed:weekSeed]);
        NSLog(@"Valid code for this month: %u.", [data CRC32WithSeed:monthSeed]);
        NSLog(@"Valid code for this year: %u.", [data CRC32WithSeed:yearSeed]);
        NSLog(@"Valid master code: %u.", [data CRC32WithSeed:masterSeed]);
        NSLog(@"Valid custom codes:");
        for (NSString *code in DD_CUSTOM_CODES) {
            NSLog(@"%@", code);
        }
    }
    
    for (int i = 1; i < (DDRedeemCodeTypeCount + DD_CUSTOM_CODES_ENABLED); i++) {
        switch (i) {
                
            // 1. Check hour-valid code
            case DDRedeemCodeTypeHourly:
                if (redeemCodeInt == [data CRC32WithSeed:hourSeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key for date (d/m/y): %i. %i. %i %i:00 -> %i:00.",
                              DD_CURRENT_TIME.day, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.hour, DD_CURRENT_TIME.hour+1);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeHourly;
                    return YES;
                }
                break;
                
            // 2. Check day-valid code
            case DDRedeemCodeTypeDaily:
                if (redeemCodeInt == [data CRC32WithSeed:daySeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key for date (d/m/y): %i. %i. %i 00:00 -> %i. %i. %i 00:00.",
                              DD_CURRENT_TIME.day, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.day+1, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeDaily;
                    return YES;
                }
                break;
                
            // 3. Check week-valid code
            case DDRedeemCodeTypeWeekly:
                if (redeemCodeInt == [data CRC32WithSeed:weekSeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key for week number: %i of year: %i.",
                              (int)DD_CURRENT_TIME_WEEK, (int)DD_CURRENT_TIME.year);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeWeekly;
                    return YES;
                }
                break;
                
            // 4. Check month-valid code
            case DDRedeemCodeTypeMonthly:
                if (redeemCodeInt == [data CRC32WithSeed:monthSeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key for date (m/y): %i. %i -> %i. %i.",
                              DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.month+1, (int)DD_CURRENT_TIME.year);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeMonthly;
                    return YES;
                }
                break;
                
            // 5. Check year-valid code
            case DDRedeemCodeTypeYearly:
                if (redeemCodeInt == [data CRC32WithSeed:yearSeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key for date (y): %i -> %i.",
                              (int)DD_CURRENT_TIME.year, (int)DD_CURRENT_TIME.year+1);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeYearly;
                    return YES;
                }
                break;
                
            // 5. Check master code
            case DDRedeemCodeTypeMaster:
                if (redeemCodeInt == [data CRC32WithSeed:masterSeed]) {
                    if (DD_LOGGING == 1)
                        NSLog(@"Valid key forever, or until you change the master secret (%@).",
                              DD_MASTER_SECRET);
                    
                    // Valid !
                    _codeType = DDRedeemCodeTypeMaster;
                    return YES;
                }
                break;
                
            // 6. Check custom code
            case 7:
                if (DD_CUSTOM_CODES_ENABLED) {
                    for (NSString *code in DD_CUSTOM_CODES) {
                        if ([redeemCode isEqualToString:code]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid CUSTOM key.");
                            
                            // Valid !
                            _codeType = DDRedeemCodeTypeCustom;
                            return YES;
                        }
                    }
                }
                break;
            default:
                break;
        }
    }
    
    if (DD_LOGGING == 1)
        NSLog(@"Redeem code is invalid or expired.");
    // Invalid !
    return NO;
}


- (BOOL)redeemProvidedCode:(NSString *)redeemCode {
    /*
     save code as redemeed if using backend
     */
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *redeemCode = [alertView textFieldAtIndex:0].text;
        BOOL isCodeValid = NO;
        _codeType = DDRedeemCodeTypeNone;
        if ([self isRedeemCodeValid:redeemCode]) {
            isCodeValid = YES;
        }
        self.completionBlock(isCodeValid, _codeType);
    }
    alertView.delegate = nil;
    AntiARCRelease(self);
}


@end
