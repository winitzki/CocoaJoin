//
//  WeakRef.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "WeakRef.h"
@interface WeakRef()
@end
@implementation WeakRef
+ (instancetype)value:(id)value {
    WeakRef *result = [[WeakRef alloc] init];
    result.weakRef = value;
    return result;
}
@end
