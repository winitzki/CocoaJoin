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

/// useful for testing an asynchronous operation. Schedule an operation on main thread, then call this, then wait for results. (Otherwise, the main thread will block while waiting for results, because background operations will not be started until the main thread yields control to the runloop.)
- (void) testExample1 {
    // Here is the full code we would need to write if we don't use any macros.
    
    // create a new join object.
    
    CJoin *j = [CJoin joinOnMainThread:NO reactionPriority:Default];
    
    // create new molecule names.
    
    CjM_empty inc = ^{ [j emptyPutName:@"int"]; };
    CjM_int counter = ^(int value){ [j intPut:value name:@"counter"]; };
    CjM_empty_int get = ^int() { return [j empty_intPutName:@"counter"]; };
    
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
    
    [j defineReactionWithInputNames:@[@"counter", @"get"] payload:^(NSArray *inputs) {
        CjR_int *_cj_counter_M = [inputs objectAtIndex:0];
        int n = _cj_counter_M.value;
        (void)n;
        CjR_empty_int *_cj_get_M = [inputs objectAtIndex:1];
        empty_int dummy = _cj_get_M.value;
        (void)dummy;
        
        { counter(n), [CJoin intReply:n to:_cj_get_M]; }
    } runOnMainThread:NO];
    
    j = nil; // make the local variable j unusable now.
    
    // now we can inject the molecules and observe the results.
    
    counter(0), inc(), inc();
    [CJoin cycleMainLoopForSeconds:0.2];
    
    int v = get();
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2");
}

- (void) testExample2 {
    // same with macros:
    
    cjDef(
          
          cjAsyncEmpty(inc)
          cjAsync(counter, int)
          cjSyncEmpty(int, getValue)
          
          cjReact2(inc, empty, dummy, counter, int, n, { counter(n+1); } );
          cjReact2(counter, int, n, getValue, empty_int, dummy, { counter(n); cjReply(getValue, n); } );
    );
    
    counter(0), inc(), inc();
    [CJoin cycleMainLoopForSeconds:0.2];
    
    int v = get();
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2");
}
@end
