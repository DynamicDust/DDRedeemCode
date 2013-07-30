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

/**
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
#if DD_SECURITY_TYPE == DDRedeemCodeSecurityTypeLocalSimple
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

/* Security check */
#if DD_SIMPLE_LOG_CODES == 1
    #ifdef NDEBUG
        #error For security purposes, please set DD_SIMPLE_LOG_CODES to 0 before building for Release.
    #endif
#endif
#endif
//--------------------------------------------------------------
// Complex Verification
#if DD_SECURITY_TYPE == DDRedeemCodeSecurityTypeLocalComplex
//--------------------------------------------------------------

/*
 *
 */
#define DD_COMPLEX_SEED_BLACKLIST                   @[@"", @""]

/*
 *
 *
 */
#define DD_COMPLEX_CHECK_KEY                        01

/*
 *
 *
 */
#define DD_COMPLEX_CODE_BYTES                       {   24,     3,      200,    \
                                                        10,     0,      56,     \
                                                        1,      2,      91,     \
                                                        7,      1,      100     }

#endif
//--------------------------------------------------------------
// Server-Side Based Verification
#if DD_SECURITY_TYPE == DDRedeemCodeSecurityTypeServerSide
//--------------------------------------------------------------

#define DD_SERVER_ADDRESS                           @"http://www.example.com/redeem-code-server/"

#define DD_SERVER_APP_ID                            @""
#define DD_SERVER_APP_SECRET                        @""



#endif
//--------------------------------------------------------------
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif
//--------------------------------------------------------------
#pragma mark - NSData Category (CRC) -
//--------------------------------------------------------------


/** 
 *The NSData class category, which adds `CRC32` support for checking codes. It is used in the most simplest code verification.
 *
 * - Cons of this approach are that the `CRC32` is not very secure and doesn't have perfect accuracy.
 * - Pros, that it produces a short 10 characters long decimal or 8 characters long hexadecimal string, that is very easy to enter.
 * @bug Implement something more secure than `CRC32` for complex security.
 */
@interface NSData (CRC)
/**
 * Calculates the CRC32 with default seed and polynomial values.
 *
 * The default values are:
 * - `0xFFFFFFFFL` for seed
 * - `0xEDB88320L` for seed
 */
-(uint32_t) calculateCRC32;
/**
 Calculates the CRC32 based on the seed, but with default polynomial.
 
 The default value of the polynomial is `0xEDB88320L`.
 @param seed This seed will be used to generate the CRC32. It is an `uint32_t`.
 */
-(uint32_t) calculateCRC32WithSeed:(uint32_t)seed;
/**
 Calculates the CRC32 using specified polynomial, but with default seed.
 
 The default value of the seed is `0xFFFFFFFFL`.
 @param poly This polynomial will be used while calculating the CRC32. 
 */
-(uint32_t) calculateCRC32WithPoly:(uint32_t)poly;

/**
 Calculate the CRC32 based on the specified seed and using the specified polynomial.
 @param seed This seed will be used to generate the CRC32.
 @param poly This polynomial will be used while calculating the CRC32.
 */
-(uint32_t) calculateCRC32WithSeed:(uint32_t)seed andPoly:(uint32_t)poly;
@end

//--------------------------------------------------------------
#pragma mark - Redeem Code Enums
//--------------------------------------------------------------

/**
 * This type definition is used to determine current verification mode. 
 *
 * Before starting, set the `DD_SECURITY_TYPE` macro in the beginning of this header file to the corespodning type.
 * 
 * **A.** Local Verification
 *
 *      - **Simple**, which uses CRC32 and has much shorter numeric codes. Ability to generate temporary codes *(hour, day, week, month and year)*, besides master and custom codes.
 *      - **Complex**, which uses partial serial number verification and generates 20-character alpha-numeric keys. Valid keys have no time limitation.
 * 
 * **B.** Server Side Verification
 *
 *      - **Remote Server**, which verifies the code against it's database of allowed codes.
 *
 * If you have chosen the server side verification, then **don't forget to configure** all macros starting with **`DD_SERVER_`**. 
 * @warning The macro `DD_SECURITY_TYPE` has to be set to a proper value before building your project with **DDRedeemCode**.
 */
typedef NS_ENUM(NSUInteger, DDRedeemCodeSecurityType) {
    /** 
     * Simple security type using CRC32 to check code.
     */
    DDRedeemCodeSecurityTypeLocalSimple,
    /** 
     * Complex security type using partial code verification to verify provided code.
     */
    DDRedeemCodeSecurityTypeLocalComplex,
    /** 
     * This security type verifies the code against a specified server.
     */
    DDRedeemCodeSecurityTypeServerSide
};

static inline const char *stringFromDDRedeemCodeSecurityType(DDRedeemCodeSecurityType secType)
{
    static const char *strings[] = {"DDRedeemCodeSecurityTypeLocalSimple", "DDRedeemCodeSecurityTypeLocalComplex", "DDRedeemCodeSecurityTypeServerSide"};
    return strings[secType];
}

/**
 This enum is used to check the code type.
 */
typedef NS_ENUM(NSUInteger, DDRedeemCodeType) {
    /** */
    DDRedeemCodeTypeSimpleHourly,
    /** */
    DDRedeemCodeTypeSimpleDaily,
    /** */
    DDRedeemCodeTypeSimpleWeekly,
    /** */
    DDRedeemCodeTypeSimpleMonthly,
    /** */
    DDRedeemCodeTypeSimpleYearly,
    /** */
    DDRedeemCodeTypeSimpleMaster,
    /** */
    DDRedeemCodeTypeSimpleCount,
    /** */
    DDRedeemCodeTypeSimpleCustom,
    /** */
    DDRedeemCodeTypeNone,
    /** */    
    DDRedeemCodeTypeComplex
};

static inline const char *stringFromDDRedeemCodeType(DDRedeemCodeType codeType)
{
    static const char *strings[] = {"DDRedeemCodeTypeSimpleHourly", "DDRedeemCodeTypeSimpleDaily", "DDRedeemCodeTypeSimpleWeekly", "DDRedeemCodeTypeSimpleMonthly", "DDRedeemCodeTypeSimpleYearly", "DDRedeemCodeTypeSimpleMaster", "6", "DDRedeemCodeTypeSimpleCustom", "DDRedeemCodeTypeNone", "DDRedeemCodeTypeComplex"};
    return strings[codeType];
}

/**
 This enum is used to set a status of a code. Mainly useful for server-side validation and partial serial number verification.
 */
typedef NS_ENUM(NSUInteger, DDRedeemCodeStatus) {
    /** */
    DDRedeemCodeStatusValid,
    /** */
    DDRedeemCodeStatusInvalid,
    /** */
    DDRedeemCodeStatusBlacklisted,
    /** */    
    DDRedeemCodeStatusForged
};

static inline const char *stringFromDDRedeemCodeStatus(DDRedeemCodeStatus codeStatus)
{
    static const char *strings[] = {"DDRedeemCodeStatusValid", "DDRedeemCodeStatusInvalid", "DDRedeemCodeStatusBlacklisted", "DDRedeemCodeStatusForged"};
    return strings[codeStatus];
}

//--------------------------------------------------------------
#pragma mark - DDRedeemCode -
//--------------------------------------------------------------
/**
 * This class adds missing feature to the Apple's In-App Purchases - ability to create redeem codes.
 *
 * It is mainly useful when, for example, sending your application to press for review.
 */
@interface DDRedeemCode : NSObject <UIAlertViewDelegate, UITextFieldDelegate>

/**
 @description This block will be executed after the code has been checked.
 
 */
@property (nonatomic, assign) void (^completionBlock)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus);

/**
 @param completionBlock This is the block that will be executed upon completion of the showRedeemAlert: method.
 */
+ (void)showPressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;

/**
 @param completionBlock This is the block that will be executed upon completion of the showRedeemAlert: method.
 @returns An instance of DDRedeemCode with completionBlock property set.
 */
+ (instancetype)pressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;

/**
 Designated initalizer
 @param completionBlock This is the block that will be executed upon completion of the showRedeemAlert: method.
 @returns A DDRedeemCode instance with completionBlock property set.
 */
- (instancetype)initWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock;

/**
 Shows UIAlertView, which contains an UITextView for redeem code enter.

 Example Usage:
 
    [[[DDRedeemCode alloc] initWithCompletionBlock:^(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus){}] showRedeemAlert];
 */
- (void)showRedeemAlert;

/**
 Check if a code is valid. If DEBUG flag is set, then also prints out the information about code validity.
 @param redeemCode The redeem code you want to validate.
 @returns BOOL
 */
- (BOOL)isRedeemCodeValid:(NSString *)redeemCode;

/**
 This method redeems the provided code on the server and returns back the answer.
 @param redeemCode The redeem code you want to redeem.
 @warning If the code was redeemed once, it cannot be redeemed again.
 */
- (BOOL)redeemProvidedCode:(NSString *)redeemCode; // Returns YES if code redeemed, returns NO if not redeemed


@end
