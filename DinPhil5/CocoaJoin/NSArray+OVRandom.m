//
// Created by yaakaito on 2012/12/22.
// https://github.com/yaakaito/Overline
//
// Adding a convenience method, `reshuffleThisArray`
//
//



#import "NSArray+OVRandom.h"


@implementation NSArray (OVRandom)

- (NSArray *)shuffle {
    return [self shuffledArray];
}

- (NSArray *)shuffledArray {
    NSMutableArray *shuffled = [self mutableCopy];
    for (NSInteger i = [shuffled count] - 1; i > 0; i--) {
        [shuffled exchangeObjectAtIndex:arc4random() % (i + 1)
                      withObjectAtIndex:i];
    }
    return shuffled;
}

- (id)anyObject {
    return [self count] ?
        [self objectAtIndex:arc4random() % [self count]] :
        nil;
}

@end

// Unbiased random rounding thingy.
static NSUInteger random_below(NSUInteger n) {
    NSUInteger m = 1;
	
    do {
        m <<= 1;
    } while(m < n);
	
    NSUInteger ret;
	
    do {
        ret = arc4random() % m;
    } while(ret >= n);
	
    return ret;
}


@implementation NSMutableArray (Random)

- (void)reshuffleThisArray {
    // http://en.wikipedia.org/wiki/Knuth_shuffle
	
    for(NSUInteger i = [self count]; i > 1; i--) {
        NSUInteger j = random_below(i);
        [self exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
}

@end
