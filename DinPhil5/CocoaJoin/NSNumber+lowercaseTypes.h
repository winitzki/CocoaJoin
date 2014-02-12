//
//  NSNumber+NSNumber_lowercaseTypes.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <Foundation/Foundation.h>


/// A trivial replacement for [NSNumber numberWithAbc:...] through [NSNumber abcWrap:...] to allow uniform macros.

#define longlong long long

@interface NSNumber (lowercaseTypes)

+ (instancetype) BOOLWrap:(BOOL)value;
+ (instancetype) charWrap:(char)value;
+ (instancetype) doubleWrap:(double)value;
+ (instancetype) floatWrap:(float)value;
+ (instancetype) intWrap:(int)value;
+ (instancetype) integerWrap:(NSInteger)value;
+ (instancetype) longWrap:(long)value;
+ (instancetype) longlongWrap:(longlong)value;
+ (instancetype) shortWrap:(short)value;

- (BOOL) BOOLValue;
- (longlong) longlongValue;
@end

