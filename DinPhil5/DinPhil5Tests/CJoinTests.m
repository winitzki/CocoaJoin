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
- (void) testExample0 {
    // Here is the full code we would need to write if we don't use any macros.
    
    // declare some molecule names
    
    
    
        CJoin *j = [CJoin joinOnMainThread:NO reactionPriority:Default];
        CjM_empty inc = ^{ [j emptyPutName:@"int"]; };
        CjM_int counter = ^(int n){ [j intPut:n name:@"counter"]; };
        CjM_empty_int get = ^int() { return [j empty_intPutName:@"counter"]; };
        
        // declare reactions using these radicals
        [j defineReactionWithInputNames:@[@"inc", @"counter"] payload:^(NSArray *inputs) {
            CjR_empty *_cj_inc_M = [inputs objectAtIndex:0];
            empty d = _cj_inc_M.value;
            (void)d;
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
            empty_int d = _cj_get_M.value;
            (void)d;
            
            counter(n), [CJoin intReply:n to:_cj_get_M];
        } runOnMainThread:NO];
        j = nil; // make the variable j unusable now.
    
    counter(0), inc(), inc();
    [CJoin cycleMainLoopForSeconds:0.2];
    
    int v = get();
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2");
}
/*
- (void)testExample
{
    // Here is the full code we would need to write if we don't use any macros.
    
    // declare some reagents / radicals
    CjR_empty *inc;
    CjR_int *counter;
    CjR_empty_int *get;
    {
        CJoin *j = [CJoin joinOnMainThread:NO reactionPriority:Default];
        inc = [CjR_empty name:@"inc" join:j];
        counter = [CjR_int name:@"counter" join:j];
        
        // declare reactions using these radicals
        [j defineReactionWithInputs:@[inc,counter] payload:^(NSArray *inputs) {
            CjR_empty *incR = [inputs objectAtIndex:0];
            empty d = incR.value;
            (void)d;
            CjR_int *counterR = [inputs objectAtIndex:1];
            int n = counterR.value;
            (void)n;
            { [counter put:n+1]; } // block given by user in macro
        } runOnMainThread:NO];
        // second reaction; some molecules can be repeated.
        counter = [CjR_int name:@"counter" join:j];
        get = [CjR_empty_int name:@"get" join:j];
        
        [j defineReactionWithInputs:@[counter,get] payload:^(NSArray *inputs) {
            CjR_int *_cj_counter_R = [inputs objectAtIndex:0];
            int n = _cj_counter_R.value;
            (void)n;
            CjR_empty_int *_cj_get_R = [inputs objectAtIndex:1];
            empty_int d = _cj_get_R.value;
            (void)d;
            
            [counter put:n], [_cj_get_R reply:n];
        } runOnMainThread:NO];
        j = nil; // make the variable j unusable now.
    }
    [counter put:0], [inc put], [inc put];
    [self cycleMainLoopForSeconds:0.2];
    
    int v = [get put];
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2");
}
- (void) testExample2 {
    // same with macros:
    
    cjDef(
          
          cjAsync(inc, empty)
          cjAsync(counter, int)
          cjSync(int, getValue, empty)
          
          cjReact2(inc, empty, _, counter, int, n, [counter put:n+1]; );
          cjReact2(counter, int, n, getValue, empty_int, _, [counter put:n], cjReply(getValue, n); );
    );
    [counter put:0], [inc put], [inc put];
    [self cycleMainLoopForSeconds:0.2];
    
    int v = [getValue put];
    
    XCTAssertEqual(v, 2, @"async counter increased twice yields 2");
}*/
@end
