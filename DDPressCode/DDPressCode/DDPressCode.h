//
//  DDPressCode.h
//  DDPressCode
//
//  Created by Dominik Hádl on 7/26/13.
//  Copyright (c) 2013 DynamicDust s.r.o. All rights reserved.
//--------------------------------------------------------------

#import <Foundation/Foundation.h>

/*
 * @description Levels of security/validation.
 *              A. Local Verification
 *                  1. Simple uses CRC32 and has much shorter numeric codes.
 *                  2. Complex uses partial serial number verification and has 12-character alpha-numeric keys.
 *              B. Server Side Verification
 *                  Verifies the redeem code against a specified remote server.
 */
typedef enum {
    DDPressCodeSecurityTypeLocalSimple,
    DDPressCodeSecurityTypeLocalComplex,
    DDPressCodeSecurityTypeServerSide
} DDPressCodeSecurityType;


/*
 * @description This is used to set a security level of the redeem code verification.
 *              If you've chosen the DDPressCodeSecurityTypeServerSide, then also edit the DD_SERVER_ macros for your server.
 */
#define DD_SECURITY_TYPE DDPressCodeSecurityTypeLocalSimple

/*
 * This is the master secret which is used for redeem code generation.
 * You have to change it to something secure. I suggest and md5 of a file, or use some password generator.
 */
#define DD_MASTER_SECRET @"supersecret"

/*
 * Set this macro to 1 if you want to provide your own codes, that will be valid forever.
 * Then insert the codes into the array macro beneath, each as a string delimited with a colon.
 * Ideally, the code should be 10 characters long and should contain both upper and lowercase letters and numbers.
 */
#define DD_CUSTOM_CODES_ENABLED 0
#define DD_CUSTOM_CODES @[@"abcd", @"efgh"]

/*
 * @description This will log all codes
 *
 *
 */
#define DD_LOG_CODES 0

/*
 * @description NSData class category, which adds CRC32 support for checking codes.
 * @todo TODO: Use something more secure than CRC32.
 */
@interface NSData (CRC)
-(uint32_t) CRC32;
-(uint32_t) CRC32WithSeed:(uint32_t)seed;
-(uint32_t) CRC32WithPoly:(uint32_t)poly;
-(uint32_t) CRC32WithSeed:(uint32_t)seed andPoly:(uint32_t)poly;
@end

typedef enum {
    DDPressCodeTypeHourly,
    DDPressCodeTypeDaily,
    DDPressCodeTypeWeekly,
    DDPressCodeTypeMonthly,
    DDPressCodeTypeYearly,
    DDPressCodeTypeMaster,
    DDPressCodeTypeCount
} DDPressCodeType;

/*
 * @description This enum is used to set a status of a code. Mainly useful for server-side validation and partial serial number verification.
 */
typedef enum {
    DDPressCodeStatusValid,
    DDPressCodeStatusInvalid,
    DDPressCodeStatusBlacklisted,
    DDPressCodeStatusForged
} DDPressCodeStatus;

@interface DDPressCode : NSObject <UIAlertViewDelegate>

/*
 * @description This block will be executed after the code has been checked.
 *
 */
@property (nonatomic, assign) void (^completionBlock)(BOOL validCode);

+ (void)showPressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode))completionBlock;
+ (instancetype)pressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode))completionBlock;

/*
 * @description
 * @returns A DDPressCode instance with completionBlock property set.
 */
- (instancetype)initWithCompletionBlock:(void (^)(BOOL validCode))completionBlock;

/*
 * @description Shows UIAlertView, which contains an UITextView for redeem code enter.
 * @usage [[[DDPressCode alloc] initWithCompletionBlock:^(BOOL validCode){}] showRedeemAlert];
 */
- (void)showRedeemAlert;

/*
 * @description Check if a code is valid. If DEBUG flag is set, then also prints out the information about code validity.
 *
 */
- (BOOL)isRedeemCodeValid:(NSString *)redeemCode;
- (BOOL)redeemProvidedCode:(NSString *)redeemCode; // Returns YES if code redeemed, returns NO if not redeemed


@end
