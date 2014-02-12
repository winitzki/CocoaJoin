//
//  DiningPhilosophicalLogic.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "DiningPhilosophicalLogic.h"
#import "CJoin.h"


@interface DiningPhilosophicalLogic()
@property (strong, nonatomic) CjR_id_id *joinControl; // control molecule: stop_and_clear, pause, resume, get_stats, etc. Not implemented.
@end

@implementation DiningPhilosophicalLogic


- (void) initializePhilosophersAndThen:(void (^)(void))continuation {
    
    // stop the previous join, if possible
    if (self.joinControl) {
        [continuation copy];
        [self.joinControl put:@{@"stop_and_then": continuation}];// stopAndThen:^{[self startAndThen:continuation];}];
    } else {
        [self startAndThen:continuation];
    }
    
}
- (void) randomWait {
    usleep((2000000 + arc4random() % 5000000 ));
}
- (void) startAndThen:(void (^)(void))continuation {
    
    // define molecules
    
    
    cjDef(
          cjAsync(tA, empty)
          cjAsync(tB, empty)
          cjAsync(tC, empty)
          cjAsync(tD, empty)
          cjAsync(tE, empty)
          
          cjAsync(hA, empty)
          cjAsync(hB, empty)
          cjAsync(hC, empty)
          cjAsync(hD, empty)
          cjAsync(hE, empty)
          
          cjAsync(fAB, empty)
          cjAsync(fBC, empty)
          cjAsync(fCD, empty)
          cjAsync(fDE, empty)
          cjAsync(fEA, empty)
          
          cjAsync(State, int) // int value = 10*philosopher + state
          
          cjReact3(hA, empty, ta, fEA, empty, fab, fAB, empty, fea,
                   [State put:Eating+10*0]; [self randomWait]; [tA put], [fEA put], [fAB put], [State put:Thinking + 10*0]; )
          cjReact3(hB, empty, ta, fAB, empty, fab, fBC, empty, fea,
                   [State put:Eating+10*1]; [self randomWait]; [tB put], [fAB put], [fBC put], [State put:Thinking + 10*1]; )
          cjReact3(hC, empty, ta, fBC, empty, fab, fCD, empty, fea,
                   [State put:Eating+10*2]; [self randomWait]; [tC put], [fBC put], [fCD put], [State put:Thinking + 10*2]; )
          cjReact3(hD, empty, ta, fCD, empty, fab, fDE, empty, fea,
                   [State put:Eating+10*3]; [self randomWait]; [tD put], [fCD put], [fDE put], [State put:Thinking + 10*3]; )
          cjReact3(hE, empty, ta, fDE, empty, fab, fEA, empty, fea,
                   [State put:Eating+10*4]; [self randomWait]; [tE put], [fDE put], [fEA put], [State put:Thinking + 10*4]; )
          
          cjReact1(tA, empty, _, [self randomWait]; [hA put], [State put:Hungry+10*0];)
          cjReact1(tB, empty, _, [self randomWait]; [hB put], [State put:Hungry+10*1];)
          cjReact1(tC, empty, _, [self randomWait]; [hC put], [State put:Hungry+10*2];)
          cjReact1(tD, empty, _, [self randomWait]; [hD put], [State put:Hungry+10*3];)
          cjReact1(tE, empty, _, [self randomWait]; [hE put], [State put:Hungry+10*4];)
                                                               
          
          cjReact1UI(State, int, s, {
            
            [self.viewController philosopher:(int)(s / 10) inState:(s % 10)];
   
            })
          
          );
    
    
    // inject everything
    [tA put]; [tB put]; [tC put]; [tD put]; [tE put];
    [fAB put]; [fBC put]; [fCD put]; [fDE put]; [fEA put];
    // tell the view controller what the initial states are.
    [self.viewController philosopher:0 inState:Thinking];
    [self.viewController philosopher:1 inState:Thinking];
    [self.viewController philosopher:2 inState:Thinking];
    [self.viewController philosopher:3 inState:Thinking];
    [self.viewController philosopher:4 inState:Thinking];
    
    if (continuation) {
        continuation();
    }
    
}


@end
