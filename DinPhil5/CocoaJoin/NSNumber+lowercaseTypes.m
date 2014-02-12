//
//  NSNumber+NSNumber_lowercaseTypes.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "NSNumber+lowercaseTypes.h"

@implementation NSNumber (lowercaseTypes)

+ (instancetype) BOOLWrap:(BOOL)value { return [self numberWithBool:value]; }
+ (instancetype) charWrap:(char)value { return [self numberWithChar:value]; }
+ (instancetype) doubleWrap:(double)value { return [self numberWithDouble:value]; }
+ (instancetype) floatWrap:(float)value { return [self numberWithFloat:value]; }
+ (instancetype) intWrap:(int)value { return [self numberWithInt:value]; }
+ (instancetype) integerWrap:(NSInteger)value { return [self numberWithInteger:value]; }
+ (instancetype) longWrap:(long)value { return [self numberWithLong:value]; }
+ (instancetype) longlongWrap:(longlong)value { return [self numberWithLongLong:value]; }
+ (instancetype) shortWrap:(short)value { return [self numberWithShort:value]; }

- (BOOL)BOOLValue {
    return [self boolValue];
}

- (long long)longlongValue {
    return [self longLongValue];
}

@end
