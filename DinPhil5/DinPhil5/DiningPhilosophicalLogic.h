//
//  DiningPhilosophicalLogic.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Thinking=0, Hungry=1, Eating=2
} PhilosopherState;

@protocol PhilosophersView <NSObject>

- (void) philosopher:(NSUInteger)philosopherNumber inState:(PhilosopherState)state;

@end

@interface DiningPhilosophicalLogic : NSObject
@property (strong, nonatomic) IBOutlet id<PhilosophersView> viewController;
- (void) initializePhilosophersAndThen:(void(^)(void))continuation;
@end
