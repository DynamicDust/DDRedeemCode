//
//  DDRedeemCode.h
//  DDRedeemCode
//
//  Created by Dominik Hádl on 7/26/13.
//  Copyright (c) 2013 DynamicDust s.r.o. All rights reserved.
//--------------------------------------------------------------
#import <Foundation/Foundation.h>
//--------------------------------------------------------------
#pragma mark Setup -
//--------------------------------------------------------------

/*
 * @description This is used to set a security level of the redeem code verification. The options are specified below. 
 *              If you've chosen the DDRedeemCodeSecurityTypeServerSide, then also edit the DD_SERVER_ macros for your server.
 *
 * @options     1. DDRedeemCodeSecurityTypeLocalSimple
 *              2. DDRedeemCodeSecurityTypeLocalComplex
 *              3. DDRedeemCodeSecurityTypeServerSide
 */
#define DD_SECURITY_TYPE DDRedeemCodeSecurityTypeLocalComplex

//--------------------------------------------------------------
// Simple Verification
//--------------------------------------------------------------
/*
 * @description This is the master secret which is used for redeem code generation. You have to change it to something secure. I suggest and md5 of a file, or use some password generator.
 */
#define DD_SIMPLE_MASTER_SECRET                     @"04564564842ab8486c46"

/*
 * @description Set this macro to 1 if you want to provide your own codes, that will be valid forever. Then insert the codes into the array macro beneath, each as a string delimited with a colon. Ideally, the code should be 10 characters long and should contain both upper and lowercase letters and numbers.
 */
#define DD_SIMPLE_CUSTOM_CODES_ENABLED              0
#define DD_SIMPLE_CUSTOM_CODES                      @[@"abcd", @"efgh"]

/*
 * @description This will log all valid codes for this application. It will also throw an error if you'll try building Release with this enabled. It will log the codes after you'll press the "Redeem" button on the UIAlertView.
 */
#define DD_SIMPLE_LOG_CODES                         0

// Security check
#if DD_SIMPLE_LOG_CODES == 1
    #ifdef NDEBUG
        #error For security purposes, please set DD_SIMPLE_LOG_CODES to 0 before building for Release.
    #endif
#endif

//--------------------------------------------------------------
// Complex Verification
//--------------------------------------------------------------

#define DD_COMPLEX_SEED_BLACKLIST                   @[@"123456789", @"987654321"]

#define DD_COMPLEX_CHECK_KEY                        01

//--------------------------------------------------------------
// Server-Side Based Verification
//--------------------------------------------------------------








//--------------------------------------------------------------
#pragma mark - NSData Category (CRC) -
//--------------------------------------------------------------

/*
 * @description NSData class category, which adds CRC32 support for checking codes.
 * @todo Implement something more secure than CRC32 for complex security.
 */
@interface NSData (CRC)
-(uint32_t) CRC32;
-(uint32_t) CRC32WithSeed:(uint32_t)seed;
-(uint32_t) CRC32WithPoly:(uint32_t)poly;
-(uint32_t) CRC32WithSeed:(uint32_t)seed andPoly:(uint32_t)poly;
@end

//--------------------------------------------------------------
#pragma mark - Redeem Code Enums
//--------------------------------------------------------------

/*
 * @description Levels of security/validation.
 *              A. Local Verification
 *                  1. Simple uses CRC32 and has much shorter numeric codes.
 *                  2. Complex uses partial serial number verification and has 12-character alpha-numeric keys.
 *              B. Server Side Verification
 *                  Verifies the redeem code against a specified remote server.
 */
typedef enum {
    DDRedeemCodeSecurityTypeLocalSimple,
    DDRedeemCodeSecurityTypeLocalComplex,
    DDRedeemCodeSecurityTypeServerSide
} DDRedeemCodeSecurityType;

static inline const char *stringFromDDRedeemCodeSecurityType(DDRedeemCodeSecurityType secType)
{
    static const char *strings[] = {"DDRedeemCodeSecurityTypeLocalSimple", "DDRedeemCodeSecurityTypeLocalComplex", "DDRedeemCodeSecurityTypeServerSide"};
    return strings[secType];
}

/*
 * @description This enum is used to check the code type.
 */
typedef enum {
    DDRedeemCodeTypeSimpleHourly,
    DDRedeemCodeTypeSimpleDaily,
    DDRedeemCodeTypeSimpleWeekly,
    DDRedeemCodeTypeSimpleMonthly,
    DDRedeemCodeTypeSimpleYearly,
    DDRedeemCodeTypeSimpleMaster,
    DDRedeemCodeTypeSimpleCount,
    DDRedeemCodeTypeSimpleCustom,
    DDRedeemCodeTypeNone,
    DDRedeemCodeTypeComplex
} DDRedeemCodeType;

static inline const char *stringFromDDRedeemCodeType(DDRedeemCodeType codeType)
{
    static const char *strings[] = {"DDRedeemCodeTypeSimpleHourly", "DDRedeemCodeTypeSimpleDaily", "DDRedeemCodeTypeSimpleWeekly", "DDRedeemCodeTypeSimpleMonthly", "DDRedeemCodeTypeSimpleYearly", "DDRedeemCodeTypeSimpleMaster", "6", "DDRedeemCodeTypeSimpleCustom", "DDRedeemCodeTypeNone", "DDRedeemCodeTypeComplex"};
    return strings[codeType];
}

/*
 * @description This enum is used to set a status of a code. Mainly useful for server-side validation and partial serial number verification.
 */
typedef enum {
    DDRedeemCodeStatusValid,
    DDRedeemCodeStatusInvalid,
    DDRedeemCodeStatusBlacklisted,
    DDRedeemCodeStatusForged
} DDRedeemCodeStatus;

static inline const char *stringFromDDRedeemCodeStatus(DDRedeemCodeStatus codeStatus)
{
    static const char *strings[] = {"DDRedeemCodeStatusValid", "DDRedeemCodeStatusInvalid", "DDRedeemCodeStatusBlacklisted", "DDRedeemCodeStatusForged"};
    return strings[codeStatus];
}

//--------------------------------------------------------------
#pragma mark - DDRedeemCode -
//--------------------------------------------------------------

@interface DDRedeemCode : NSObject <UIAlertViewDelegate, UITextFieldDelegate>

/*
 * @description This block will be executed after the code has been checked.
 *
 */
@property (nonatomic, assign) void (^completionBlock)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus);

+ (void)showPressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;
+ (instancetype)pressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;

/*
 * @description
 * @returns A DDRedeemCode instance with completionBlock property set.
 */
- (instancetype)initWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;

/*
 * @description Shows UIAlertView, which contains an UITextView for redeem code enter.
 * @usage [[[DDRedeemCode alloc] initWithCompletionBlock:^(BOOL validCode){}] showRedeemAlert];
 */
- (void)showRedeemAlert;

/*
 * @description Check if a code is valid. If DEBUG flag is set, then also prints out the information about code validity.
 *
 */
- (BOOL)isRedeemCodeValid:(NSString *)redeemCode;
- (BOOL)redeemProvidedCode:(NSString *)redeemCode; // Returns YES if code redeemed, returns NO if not redeemed


@end
