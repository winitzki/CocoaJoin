//
// Created by yaakaito on 2012/12/22.
// https://github.com/yaakaito/Overline
//
// Adding a convenience method, `reshuffleThisArray`
//
//


#import <Foundation/Foundation.h>

@interface NSArray (OVRandom)
- (NSArray *)shuffle;
- (NSArray *)shuffledArray;
- (id)anyObject;
@end

@interface NSMutableArray (OVRandom)
- (void) reshuffleThisArray;
@end
