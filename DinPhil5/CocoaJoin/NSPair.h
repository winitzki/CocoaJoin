//
//  NSPair.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPair : NSObject
+ :(id)first :(id)second;
@property (strong, nonatomic) id first;
@property (strong, nonatomic) id second;
@end
