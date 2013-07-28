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

//--------------------------------------------------------------
#pragma mark Macros -
//--------------------------------------------------------------

// Thanks to JeremyP on SO - http://stackoverflow.com/a/7792687/1001803
#define AntiARCRetain(...)      void *retainedThing = (__bridge_retained void *)__VA_ARGS__; retainedThing = retainedThing
#define AntiARCRelease(...)     void *retainedThing = (__bridge void *) __VA_ARGS__; id unretainedThing = (__bridge_transfer id)retainedThing; unretainedThing = nil


#define DD_BUNDLE_ID            [[NSBundle mainBundle] bundleIdentifier]
#define DD_CURRENT_TIME         CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(), CFTimeZoneCopySystem())
#define DD_CURRENT_TIME_WEEK    CFAbsoluteTimeGetWeekOfYear(CFAbsoluteTimeGetCurrent(), CFTimeZoneCopySystem())

#ifdef DEBUG
#define DD_LOGGING              1
#else
#define DD_LOGGING              0
#endif

//--------------------------------------------------------------
#pragma mark - NSData CRC Extension -
//--------------------------------------------------------------
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

//--------------------------------------------------------------
#pragma mark - DDRedeem Code -
//--------------------------------------------------------------
@implementation DDRedeemCode {
    DDRedeemCodeType            _codeType;
    DDRedeemCodeStatus          _codeStatus;
}

//--------------------------------------------------------------
#pragma mark - Class Methods -
//--------------------------------------------------------------

+ (void)showPressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock {
    DDRedeemCode *pressCode = [[self alloc] initWithCompletionBlock:completionBlock];
    AntiARCRetain(pressCode);
    [pressCode showRedeemAlert];
}

+ (instancetype)pressCodeAlertWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock {
    DDRedeemCode *pressCode = [[self alloc] initWithCompletionBlock:completionBlock];
    AntiARCRetain(pressCode);
    return pressCode;
}

//--------------------------------------------------------------
#pragma mark - Init -
//--------------------------------------------------------------

- (instancetype)initWithCompletionBlock:(void (^)(BOOL validCode, DDRedeemCodeType codeType, DDRedeemCodeStatus codeStatus))completionBlock {
    self = [super init];
    
    if (self) {
        self.completionBlock = completionBlock;
    }
    return self;
}

//--------------------------------------------------------------
#pragma mark - Public Methods -
#pragma mark Code Verification
//--------------------------------------------------------------

- (BOOL)isRedeemCodeValid:(NSString *)redeemCode {
    
    switch (DD_SECURITY_TYPE)
    {
        case DDRedeemCodeSecurityTypeLocalSimple:
        {
            uint32_t redeemCodeInt = [redeemCode intValue];
            
            // Base data
            NSData *data = [DD_BUNDLE_ID dataUsingEncoding:NSUTF8StringEncoding];
            
            
            // hour-code seed
            uint32_t hourSeed       = [DD_SIMPLE_MASTER_SECRET intValue] + DD_CURRENT_TIME.hour + DD_CURRENT_TIME.day + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
            
            // day-code seed
            uint32_t daySeed        = [DD_SIMPLE_MASTER_SECRET intValue] + DD_CURRENT_TIME.day + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
            
            // week-code seed
            uint32_t weekSeed       = [DD_SIMPLE_MASTER_SECRET intValue] + DD_CURRENT_TIME_WEEK + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
            
            // month-code seed
            uint32_t monthSeed      = [DD_SIMPLE_MASTER_SECRET intValue] + DD_CURRENT_TIME.month + DD_CURRENT_TIME.year;
            
            // year-code seed
            uint32_t yearSeed       = [DD_SIMPLE_MASTER_SECRET intValue] + DD_CURRENT_TIME.year;
            
            // master-code seed
            uint32_t masterSeed     = [DD_SIMPLE_MASTER_SECRET intValue];
            
            if (DD_SIMPLE_LOG_CODES == 1) {
                NSLog(@"Valid code for this hour: %u.", [data CRC32WithSeed:hourSeed]);
                NSLog(@"Valid code for this day: %u.", [data CRC32WithSeed:daySeed]);
                NSLog(@"Valid code for this week: %u.", [data CRC32WithSeed:weekSeed]);
                NSLog(@"Valid code for this month: %u.", [data CRC32WithSeed:monthSeed]);
                NSLog(@"Valid code for this year: %u.", [data CRC32WithSeed:yearSeed]);
                NSLog(@"Valid master code: %u.", [data CRC32WithSeed:masterSeed]);
                NSLog(@"Valid custom codes:");
                for (NSString *code in DD_SIMPLE_CUSTOM_CODES) {
                    NSLog(@"%@", code);
                }
            }
            
            for (int i = 1; i < (DDRedeemCodeTypeSimpleCount + DD_SIMPLE_CUSTOM_CODES_ENABLED); i++) {
                switch (i) {
                        
                        // 1. Check hour-valid code
                    case DDRedeemCodeTypeSimpleHourly:
                        if (redeemCodeInt == [data CRC32WithSeed:hourSeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key for date (d/m/y): %i. %i. %i %i:00 -> %i:00.",
                                      DD_CURRENT_TIME.day, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.hour, DD_CURRENT_TIME.hour+1);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleHourly;
                            return YES;
                        }
                        break;
                        
                        // 2. Check day-valid code
                    case DDRedeemCodeTypeSimpleDaily:
                        if (redeemCodeInt == [data CRC32WithSeed:daySeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key for date (d/m/y): %i. %i. %i 00:00 -> %i. %i. %i 00:00.",
                                      DD_CURRENT_TIME.day, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.day+1, DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleDaily;
                            return YES;
                        }
                        break;
                        
                        // 3. Check week-valid code
                    case DDRedeemCodeTypeSimpleWeekly:
                        if (redeemCodeInt == [data CRC32WithSeed:weekSeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key for week number: %i of year: %i.",
                                      (int)DD_CURRENT_TIME_WEEK, (int)DD_CURRENT_TIME.year);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleWeekly;
                            return YES;
                        }
                        break;
                        
                        // 4. Check month-valid code
                    case DDRedeemCodeTypeSimpleMonthly:
                        if (redeemCodeInt == [data CRC32WithSeed:monthSeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key for date (m/y): %i. %i -> %i. %i.",
                                      DD_CURRENT_TIME.month, (int)DD_CURRENT_TIME.year, DD_CURRENT_TIME.month+1, (int)DD_CURRENT_TIME.year);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleMonthly;
                            return YES;
                        }
                        break;
                        
                        // 5. Check year-valid code
                    case DDRedeemCodeTypeSimpleYearly:
                        if (redeemCodeInt == [data CRC32WithSeed:yearSeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key for date (y): %i -> %i.",
                                      (int)DD_CURRENT_TIME.year, (int)DD_CURRENT_TIME.year+1);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleYearly;
                            return YES;
                        }
                        break;
                        
                        // 5. Check master code
                    case DDRedeemCodeTypeSimpleMaster:
                        if (redeemCodeInt == [data CRC32WithSeed:masterSeed]) {
                            if (DD_LOGGING == 1)
                                NSLog(@"Valid key forever, or until you change the master secret (%@).",
                                      DD_SIMPLE_MASTER_SECRET);
                            
                            // Valid !
                            _codeStatus = DDRedeemCodeStatusValid;                            
                            _codeType = DDRedeemCodeTypeSimpleMaster;
                            return YES;
                        }
                        break;
                        
                        // 6. Check custom code
                    case 7:
                        if (DD_SIMPLE_CUSTOM_CODES_ENABLED) {
                            for (NSString *code in DD_SIMPLE_CUSTOM_CODES) {
                                if ([redeemCode isEqualToString:code]) {
                                    if (DD_LOGGING == 1)
                                        NSLog(@"Valid CUSTOM key.");
                                    
                                    // Valid !
                                    _codeStatus = DDRedeemCodeStatusValid;
                                    _codeType = DDRedeemCodeTypeSimpleCustom;
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
            _codeStatus = DDRedeemCodeStatusInvalid;
            // Invalid !
            return NO;
        }
            
        case DDRedeemCodeSecurityTypeLocalComplex: 
        {
            DDRedeemCodeStatus status = [self checkCode:redeemCode];
            switch (status) {
                case DDRedeemCodeStatusInvalid:
                    _codeStatus = DDRedeemCodeStatusInvalid;
                    return NO;
                case DDRedeemCodeStatusBlacklisted:
                    _codeStatus = DDRedeemCodeStatusBlacklisted;
                    return NO;
                case DDRedeemCodeStatusForged:
                    _codeStatus = DDRedeemCodeStatusForged;
                    return NO;
                case DDRedeemCodeStatusValid:
                    _codeStatus = DDRedeemCodeStatusValid;
                    _codeType = DDRedeemCodeTypeComplex;
                    return YES;
                default:                                return NO;
            }
        }
            
        case DDRedeemCodeSecurityTypeServerSide: 
        {
            
            
            
            return NO;
        }
            
        default: return NO;
    }
}

//--------------------------------------------------------------
#pragma mark Redeem Code
//--------------------------------------------------------------

- (BOOL)redeemProvidedCode:(NSString *)redeemCode {
    /*
     save code as redemeed if using backend
     */
    return NO;
}

//--------------------------------------------------------------
#pragma mark - Partial Redeem Code Verification -
//--------------------------------------------------------------

- (Byte) getCodeByteWithSeed:(int64_t)seed andByteA:(Byte)a byteB:(Byte)b byteC:(Byte)c {
    
    Byte result;
    a = a % 25;
    b = b % 3;
    
    if ((a % 2) == 0)
        result = ((seed >> a) & 0x000000FF) ^ ((seed >> b) | c);
    else
        result = ((seed >> a) & 0x000000FF) ^ ((seed >> b) & c);
    
    return result;
}

//--------------------------------------------------------------

- (NSString *) getCodeChecksum:(NSString *)code {
    short left, right;
    unsigned short sum;
    int i;
    const char *s = [code UTF8String];
    
    left = 0x0056;
    right = 0x00AF;
    
    if (strlen(s) > 0) {
        for (i = 1; i <= strlen(s); i++) {
            right = right + (Byte)s[i];
            if (right > 0x00FF) {
                right -= 0x00FF;
            }
            left += right;
            if (left > 0x0FF) {
                left -= 0x00FF;
            }
        }
    }
    sum = (left << 8) + right;
    return [NSString stringWithFormat:@"%04x", (int)sum];
}

//--------------------------------------------------------------

- (BOOL)checkCodeChecksum:(NSString *)code {
    code = [code stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (code.length != 20) return NO;
    
    NSString *sum = [code substringWithRange:NSMakeRange(16, 4)];
    code = [code substringToIndex:16];
    
    if ([[self getCodeChecksum:code] isEqualToString:sum]) {
        return YES;
    }
    return NO;
}

//--------------------------------------------------------------

- (DDRedeemCodeStatus)checkCode:(NSString *)code {
    unsigned int seed, codeByte;
    Byte b;
    DDRedeemCodeStatus result = DDRedeemCodeStatusInvalid;
    
    if ([self checkCodeChecksum:code] == NO) return result;
    
    code = [code stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    if ([DD_COMPLEX_SEED_BLACKLIST count] > 0) {
        for (int i = 0; i < [DD_COMPLEX_SEED_BLACKLIST count]; i++) {
            if ([code isEqualToString:DD_COMPLEX_SEED_BLACKLIST[i]]) {
                result = DDRedeemCodeStatusBlacklisted;
                return result;
            }
        }
    }
    
    result = DDRedeemCodeStatusForged;
    
    [[NSScanner scannerWithString:[code substringWithRange:NSMakeRange(0, 8)]] scanHexInt:&seed];
    
#if DD_COMPLEX_CHECK_KEY == 00
    [[NSScanner scannerWithString:[code substringWithRange:NSMakeRange(8, 2)]] scanHexInt:&codeByte];
    Byte kb = (Byte)codeByte;
    b = [self getCodeByteWithSeed:seed andByteA:24 byteB:3 byteC:200];
    if (kb != b) {
        return result;
    }
#elif DD_COMPLEX_CHECK_KEY == 01
    [[NSScanner scannerWithString:[code substringWithRange:NSMakeRange(10, 2)]] scanHexInt:&codeByte];
    Byte kb = (Byte)codeByte;
    b = [self getCodeByteWithSeed:seed andByteA:10 byteB:0 byteC:56];
    if (kb != b) {
        return result;
    }
#elif DD_COMPLEX_CHECK_KEY == 02
    [[NSScanner scannerWithString:[code substringWithRange:NSMakeRange(12, 2)]] scanHexInt:&codeByte];
    Byte kb = (Byte)codeByte;
    b = [self getCodeByteWithSeed:seed andByteA:1 byteB:2 byteC:91];
    if (kb != b) {
        return result;
    }
#elif DD_COMPLEX_CHECK_KEY == 03
    [[NSScanner scannerWithString:[code substringWithRange:NSMakeRange(14, 2)]] scanHexInt:&codeByte];
    Byte kb = (Byte)codeByte;
    b = [self getCodeByteWithSeed:seed andByteA:7 byteB:1 byteC:100];
    if (kb != b) {
        return result;
    }
#endif
    
    result = DDRedeemCodeStatusValid;
    return result;
}

//--------------------------------------------------------------

#ifdef DEBUG
- (NSString *)makeRedeemCodeWithSeed:(int64_t)seed {

    Byte keyBytes[4];
    int i;
    
    keyBytes[0] = [self getCodeByteWithSeed: seed
                                   andByteA: 24
                                      byteB: 3
                                      byteC: 200];
    
    keyBytes[1] = [self getCodeByteWithSeed: seed
                                   andByteA: 10
                                      byteB: 0
                                      byteC: 56];
    
    keyBytes[2] = [self getCodeByteWithSeed: seed
                                   andByteA: 1
                                      byteB: 2
                                      byteC: 91];
    
    keyBytes[3] = [self getCodeByteWithSeed: seed
                                   andByteA: 7
                                      byteB: 1
                                      byteC: 100];
    
    NSMutableString *result = [NSMutableString stringWithFormat:@"%08x", (int)seed];
    
    for (i = 0; i < 4; i++) {
        [result appendString:[NSString stringWithFormat:@"%02x", (int) keyBytes[i]]];
    }
    [result appendString:[self getCodeChecksum:result]];
    
    i = [result length] - 4;
    while (i > 1) {
        [result insertString:@"-" atIndex:i];
        i -= 4;
    }
    return result;
}
#endif

//--------------------------------------------------------------
#pragma mark - UIAlertView -
//--------------------------------------------------------------

- (void)showRedeemAlert {
    UIAlertView *redeemView = [[UIAlertView alloc] initWithTitle: @"Redeem Press Code"
                                                         message: @"Enter your redeem code to unlock press version of this application."
                                                        delegate: self
                                               cancelButtonTitle: @"Cancel"
                                               otherButtonTitles: @"Redeem", nil];
    
    redeemView.alertViewStyle = UIAlertViewStylePlainTextInput;
    redeemView.delegate = self;
    if (DD_SECURITY_TYPE == DDRedeemCodeSecurityTypeLocalComplex) {
        [redeemView textFieldAtIndex:0].delegate = self;
    }
    [redeemView show];
}

//--------------------------------------------------------------
#pragma mark - UIAlertView Delegate -
//--------------------------------------------------------------

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *redeemCode = [alertView textFieldAtIndex:0].text;
        BOOL isCodeValid = NO;
        _codeType = DDRedeemCodeTypeNone;
        if ([self isRedeemCodeValid:redeemCode]) {
            isCodeValid = YES;
        }
        self.completionBlock(isCodeValid, _codeType, _codeStatus);
    }
    alertView.delegate = nil;
    AntiARCRelease(self);
}

//--------------------------------------------------------------
#pragma mark - UITextView Delegate -
//--------------------------------------------------------------

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.text.length < 4) return YES;
    if ([textField.text stringByReplacingOccurrencesOfString:@"-" withString:@""].length == 20) return NO;
    if  ([[textField.text substringWithRange:NSMakeRange(textField.text.length-4, 4)] rangeOfString:@"-"].location == NSNotFound) {
        textField.text = [textField.text stringByAppendingFormat:@"-"];
    }
    
    return YES;
}

//--------------------------------------------------------------
@end
//--------------------------------------------------------------