//
//  NSPair.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "NSPair.h"

@implementation NSPair
+ :(id)first :(id)second {
    NSPair *result = [[NSPair alloc] init];
    result.first = first;
    result.second = second;
    return result;
}
@end
