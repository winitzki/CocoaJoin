//
//  WeakRef.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeakRef : NSObject
@property (weak, nonatomic) id weakRef;
+ (instancetype) value:(id)value;
@end
