//
//  DiningPhilosophicalLogic.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "DiningPhilosophicalLogic.h"
#import "CJoin.h"


@interface DiningPhilosophicalLogic()
@property (copy, nonatomic) CjM_id stopJoin;
//@property (copy, nonatomic) CjM_empty resumeJoin;
@end

@implementation DiningPhilosophicalLogic


- (void) initializePhilosophersAndThen:(void (^)(void))continuation {
    
    // stop the previous join if possible. Otherwise start right away.
    if (self.stopJoin) {
        [continuation copy];
        [self initializePhilosopherStates];
        self.stopJoin(^{
            [self startAndThen:continuation];
        });
        
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
          
          cjStopJoin(stop)
//          cjResumeJoin(resume)
          
          self.stopJoin = stop;
//          self.resumeJoin = resume;
          
          cjSlowEmpty(tA)
          cjSlowEmpty(tB)
          cjSlowEmpty(tC)
          cjSlowEmpty(tD)
          cjSlowEmpty(tE)
          
          cjSlowEmpty(hA)
          cjSlowEmpty(hB)
          cjSlowEmpty(hC)
          cjSlowEmpty(hD)
          cjSlowEmpty(hE)
          
          cjSlowEmpty(fAB)
          cjSlowEmpty(fBC)
          cjSlowEmpty(fCD)
          cjSlowEmpty(fDE)
          cjSlowEmpty(fEA)
          
          cjSlow(State, int) // int value = 10*philosopher + state
          
          cjReact3(hA, empty, ta, fEA, empty, fab, fAB, empty, fea,
                   State(Eating+10*0); [self randomWait]; tA(), fEA(), fAB(), State(Thinking + 10*0); )
          cjReact3(hB, empty, ta, fAB, empty, fab, fBC, empty, fea,
                   State(Eating+10*1); [self randomWait]; tB(), fAB(), fBC(), State(Thinking + 10*1); )
          cjReact3(hC, empty, ta, fBC, empty, fab, fCD, empty, fea,
                   State(Eating+10*2); [self randomWait]; tC(), fBC(), fCD(), State(Thinking + 10*2); )
          cjReact3(hD, empty, ta, fCD, empty, fab, fDE, empty, fa,
                   State(Eating+10*3); [self randomWait]; tD(), fCD(), fDE(), State(Thinking + 10*3); )
          cjReact3(hE, empty, ta, fDE, empty, fab, fEA, empty, fea,
                   State(Eating+10*4); [self randomWait]; tE(), fDE(), fEA(), State(Thinking + 10*4); )
          
          cjReact1(tA, empty, _, [self randomWait]; hA(), State(Hungry+10*0);)
          cjReact1(tB, empty, _, [self randomWait]; hB(), State(Hungry+10*1);)
          cjReact1(tC, empty, _, [self randomWait]; hC(), State(Hungry+10*2);)
          cjReact1(tD, empty, _, [self randomWait]; hD(), State(Hungry+10*3);)
          cjReact1(tE, empty, _, [self randomWait]; hE(), State(Hungry+10*4);)
                                                               
          
          cjReact1UI(State, int, s, {
            
            [self.viewController philosopher:(int)(s / 10) inState:(s % 10)];
   
            })
          
          );
    
    
    // inject everything
    tA(); tB(); tC(); tD(); tE();
    fAB(); fBC(); fCD(); fDE(); fEA();
    
    [self initializePhilosopherStates];
    
    if (continuation) {
        continuation();
    }
    
}

- (void) initializePhilosopherStates {
    // tell the view controller what the initial states are.
    [self.viewController philosopher:0 inState:Thinking];
    [self.viewController philosopher:1 inState:Thinking];
    [self.viewController philosopher:2 inState:Thinking];
    [self.viewController philosopher:3 inState:Thinking];
    [self.viewController philosopher:4 inState:Thinking];

}

@end
