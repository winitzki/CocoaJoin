//
//  CJoinTests.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CJoin.h"
#import "NSNumber+lowercaseTypes.h"
@interface CJoinTests : XCTestCase

@end

@implementation CJoinTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.

    }

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testControl1 {
    CJoin *j = [CJoin joinOnMainThread:NO reactionPriority:Default];
    
    CjM_id jStop = [j makeStop];
    CjM_empty jResume = [j makeResume];
    
    // stop
    jStop(jResume);
    // we must be resumed here
    
}

- (CjM_empty) makeEmptyMoleculeWithBlock:(void(^)(void))blk {
    cjDef(
          cjSlowEmpty(stopped)
          
          cjReact1(stopped, empty, dummy, { blk(); });
    )
    return [stopped copy];
}

- (void) testControl2 {
    cjDef(
          
          cjStopJoin(jStop)
//          cjResumeJoin(jResume)
          
          cjSlowEmpty(inc)
          cjSlow(counter, int)
          cjFastEmpty(int, getValue)
          
          cjReact2(inc, empty, dummy, counter, int, n, { counter(n+1); } )
          cjReact2(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } )
    )
    counter(0);
    CjM_empty stopped = [self makeEmptyMoleculeWithBlock:^{
        
    }];
    jStop(stopped);
    inc(), inc(); // these must be ignored
    [CJoin cycleMainLoopForSeconds:0.2]; // make sure the inc() molecules have been consumed...
    
    int v = getValue();
    
    XCTAssertEqual(v, 0, @"async counter increased twice but has no effect in stopped state");
}
- (void) testControl3 {
    cjDef(
          
          cjStopJoin(jStop)
//          cjResumeJoin(jResume)
          
          cjSlowEmpty(inc)
          cjSlow(counter, int)
          cjFastEmpty(int, getValue)
          
          cjReact2(inc, empty, dummy, counter, int, n, { counter(n+1); } )
          cjReact2(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } )
          )
    counter(0);
    
    jStop(nil);
    inc(), inc(); // these must be ignored
    [CJoin cycleMainLoopForSeconds:0.2]; // make sure the inc() molecules have been consumed...
    int v1 = getValue();
    XCTAssertEqual(v1, 0, @"fast molecule returns zero for a stopped join");
    
}
- (void) testControl4 {
    cjDef(
          
          cjStopJoin(jStop)
          cjResumeJoin(jResume)
          
          cjSlowEmpty(inc)
          cjSlow(counter, int)
          cjFastEmpty(int, getValue)
          
          cjReact2(inc, empty, dummy, counter, int, n, { counter(n+1); } )
          cjReact2(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } )
          )
    counter(0);
    
    jStop(nil);
    inc(), inc(); // these must be ignored
    [CJoin cycleMainLoopForSeconds:0.2]; // make sure the inc() molecules have been consumed...
    
    // let's resume now
    jResume();
    counter(0); // need to inject everything again.
    inc(), inc(); // these must not be ignored now
    [CJoin cycleMainLoopForSeconds:0.2]; // make sure the inc() molecules have been consumed...
    
    int v = getValue();
    
    XCTAssertEqual(v, 2, @"async counter increased twice works again after resuming");
}
- (void) testExample1 {
    // Here is the full code we would need to write if we don't use any macros.
    
    // create a new join object.
    
    CJoin *j = [CJoin joinOnMainThread:NO reactionPriority:Default];
    
    // create new molecule names.
    
    CjM_empty inc = ^{ [[CjR_empty name:@"inc" join:j] put]; };
    CjM_int counter = ^(int value){ [[CjR_int name:@"counter" join:j] put:value]; };
    CjM_empty_int getValue = ^int{ return [[CjR_empty_int name:@"getValue" join:j] put]; };
    
    // declare reactions using these molecule names.
    
    [j defineReactionWithInputNames:@[@"inc", @"counter"] payload:^(NSArray *inputs) {
        CjR_empty *_cj_inc_M = [inputs objectAtIndex:0];
        empty dummy = _cj_inc_M.value;
        (void)dummy;
        CjR_int *_cj_counter_M = [inputs objectAtIndex:1];
        int n = _cj_counter_M.value;
        (void)n;
        { counter(n+1); } // code given by user in macro
    } runOnMainThread:NO];
    
    [j defineReactionWithInputNames:@[@"counter", @"getValue"] payload:^(NSArray *inputs) {
        CjR_int *_cj_counter_M = [inputs objectAtIndex:0];
        int n = _cj_counter_M.value;
        (void)n;
        CjR_empty_int *_cj_getValue_M = [inputs objectAtIndex:1];
        empty_int dummy = _cj_getValue_M.value;
        (void)dummy;
        
        { counter(n), [_cj_getValue_M reply:n]; }
    } runOnMainThread:NO];
    
    j = nil; // make the local variable j unusable now.
    
    // now we can inject the molecules and observe the results.
    
    counter(0);
    inc();
    inc();
    [CJoin cycleMainLoopForSeconds:0.2];
    
    int v = getValue();
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2 (using no macros)");
}

- (void) testExample2 {
    // same with macros:
    
    cjDef(
          
          cjSlowEmpty(inc)
          cjSlow(counter, int)
          cjFastEmpty(int, getValue)
          
          cjReact2(inc, empty, dummy, counter, int, n, { counter(n+1); } )
          cjReact2(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } )
    )
    
    counter(0), inc(), inc();
    [CJoin cycleMainLoopForSeconds:0.2]; // make sure the inc() molecules have been consumed...
    
    int v = getValue();
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2 (using macros and background threads)");
}
- (void) testExample3 {
    cjDefUI(cjSlowEmpty(inc)
            cjSlow(counter, int)
            cjFastEmpty(int, getValue)
            
            cjReact2UI(inc, empty, dummy, counter, int, n, { counter(n+1); } )
            cjReact2UI(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } )
            )
    counter(0), inc(), inc();
    // we should not need to cycle the UI thread because all reactions and the join are running on the UI thread.
    int v = getValue();
    
    XCTAssertEqual(v, 2, @"sync counter increased twice yields 2, all on UI thread");
}
- (void) testExample4 { // run 20 concurrent tasks
    int total = 20;
    cjDef(cjSlow(begin, int)
          cjSlow(done, int)
          cjSlow(acc, int)
          cjSlow(all_done, int)
          cjSlow(counter, int)
          cjFastEmpty(int, getValue)
          
          cjReact1(begin, int, x, { done(x); } );
          cjReact2(all_done, int, x, getValue, empty_int, _, cjReply(getValue, x);)
          cjReact3(done, int, n, acc, int, p, counter, int, m, { int newCounter=m+1; int newValue = p+n; if (newCounter==total) all_done(newValue); else acc(newValue), counter(newCounter); } )
          )
    counter(0); acc(0);
    for (int i=1; i <= total; i++) begin(i);

    // we have scheduled some background reactions, now let's block this thread and wait for the final results.
    // since all reactions are on non-UI thread, we do not need to cycle the UI thread here.
    int v = getValue();
    
    XCTAssertEqual(v, total*(total+1)/2, @"adding numbers asynchronously is correct");
    
}

@end
