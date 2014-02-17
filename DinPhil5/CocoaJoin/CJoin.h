//
//  CJoin.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//


@class CJoin;

typedef NSNull *empty;

#define _cjMkSimpleE(t) typedef NSNull* empty_##t;
_cjMkSimpleE(empty)
_cjMkSimpleE(id)
_cjMkSimpleE(int)
_cjMkSimpleE(float)

#define _cjMkSimpleT(s,t) typedef s s##_##t;
_cjMkSimpleT(id,empty)
_cjMkSimpleT(id,id)
_cjMkSimpleT(id,int)
_cjMkSimpleT(id,float)
_cjMkSimpleT(int,empty)
_cjMkSimpleT(int,id)
_cjMkSimpleT(int,int)
_cjMkSimpleT(int,float)
_cjMkSimpleT(float,empty)
_cjMkSimpleT(float,id)
_cjMkSimpleT(float,int)
_cjMkSimpleT(float,float)

typedef void (^CjM_empty)(void);

#define _cjMkTypedef(t) \
typedef void(^CjM_##t)(t);

_cjMkTypedef(id)
_cjMkTypedef(int)
_cjMkTypedef(float)

typedef void(^CjM_empty_empty)(void);

#define _cjMkTypedefE(t) \
typedef t (^CjM_empty_##t)(void);

_cjMkTypedefE(id)
_cjMkTypedefE(int)
_cjMkTypedefE(float)

#define _cjMkTypedefTE(t) \
typedef void (^CjM_##t##_empty)(t);

_cjMkTypedefTE(id)
_cjMkTypedefTE(int)
_cjMkTypedefTE(float)

#define _cjMkTypedefS(s,t) typedef t (^CjM_##s##_##t)(s);

_cjMkTypedefS(id, id)
_cjMkTypedefS(id, int)
_cjMkTypedefS(id, float)
_cjMkTypedefS(int, id)
_cjMkTypedefS(int, int)
_cjMkTypedefS(int, float)
_cjMkTypedefS(float, id)
_cjMkTypedefS(float, int)
_cjMkTypedefS(float, float)

// more to come

/// convenience type name for priorities used in GCD dispatch queues
typedef enum {
    High = DISPATCH_QUEUE_PRIORITY_HIGH,
    Default = DISPATCH_QUEUE_PRIORITY_DEFAULT,
    Low = DISPATCH_QUEUE_PRIORITY_LOW,
    LowestBackground = DISPATCH_QUEUE_PRIORITY_BACKGROUND}
ReactionPriority;

/// Abstract class representing a fully constructed molecule name. Its subclasses represent molecule names with specific types of values.
@interface CjR_A : NSObject
+ (instancetype)name:(NSString *)name join:(CJoin *)join;
@end
@interface CjS_A : CjR_A
@end

@interface CjR_empty : CjR_A
- (void) put;
- (empty) value;
@end

#define _cjMkRClass(t) \
@interface CjR_##t : CjR_A \
- (t) value;\
- (void) put:(t)value; \
@end

_cjMkRClass(int)
_cjMkRClass(id)
_cjMkRClass(float)

#define _cjMkSEClass(t) \
@interface CjR_empty_##t : CjS_A \
- (t)put; \
- (empty) value; \
- (void)reply:(t)value; \
@end

@interface CjR_empty_empty : CjS_A
- (void)put;
- (empty) value;
- (void)reply;
@end

#define _cjMkSClass(in,out) \
@interface CjR_##in##_##out : CjS_A \
- (out)put:(in)value; \
- (in) value; \
- (void)reply:(out)value; \
@end

// empty -> t
_cjMkSEClass(int)
_cjMkSEClass(id)
_cjMkSEClass(float)

// s -> t
_cjMkSClass(float, float)
_cjMkSClass(float, id)
_cjMkSClass(float, int)
_cjMkSClass(id, float)
_cjMkSClass(id, id)
_cjMkSClass(id, int)
_cjMkSClass(int, float)
_cjMkSClass(int, id)
_cjMkSClass(int, int)

typedef void(^ReactionPayload)(NSArray *inputs);

@interface CJoin : NSObject
+ (instancetype) joinOnMainThread:(BOOL)onMainThread reactionPriority:(ReactionPriority)priority;
- (void) defineReactionWithInputNames:(NSArray *)inputs payload:(ReactionPayload)payload runOnMainThread:(BOOL)onMainThread;
+ (void) stopAndThen:(void (^)(void))continuation;
+ (void) cycleMainLoopForSeconds:(CGFloat)seconds;

/// convenience functions to convert between id and primitive types: do we need them all?
+ (BOOL) unwrap_BOOL:(id)value;
+ (int) unwrap_int:(id)value;
+ (id) unwrap_id:(id)value;
+ (float) unwrap_float:(id)value;
+ (empty) unwrap_empty:(id)value;
//+ (empty) unwrap_empty_empty:(id)value;
//+ (empty) unwrap_empty_id:(id)value;
//+ (empty) unwrap_empty_int:(id)value;
+ (id) wrap_BOOL:(BOOL)value;
+ (id) wrap_int:(int)value;
+ (id) wrap_id:(id)value;
+ (id) wrap_float:(float)value;

@end

// Todo: implement the special reaction with JoinControl

// Syntactic sugar

#define cjSlow(m,t) CjM_##t m = ^(t value){ [[CjR_##t name:@#m join:_cj_LocalJoin] put:value]; };
#define cjSlowEmpty(m) CjM_empty m = ^(void){ [[CjR_empty name:@#m join:_cj_LocalJoin] put]; };
#define cjFast(t_out,m,t_in) CjM_##t_in##_##t_out m = ^t_out(t_in value){ return [[CjR_##t_in##_##t_out name:@#m join:_cj_LocalJoin] put:value]; };
#define cjFastEmpty(t_out,m) CjM_empty_##t_out m = ^t_out(void){ return [[CjR_empty_##t_out name:@#m join:_cj_LocalJoin] put]; };
#define cjReply(m, v) [_cj_##m##_R reply:v]

#define cjJoinControlFast(m) cjFast(id,m,id)
#define cjJoinControlSlow(m) cjSlow(m,id)

#define cjDefUIPriority(ui,p,r...)   \
CJoin *_cj_LocalJoin = [CJoin joinOnMainThread:ui reactionPriority:p]; \
r \
_cj_LocalJoin = nil;

#define cjDef(r...) cjDefUIPriority(NO, Default, r)
#define cjDefUI(r...) cjDefUIPriority(YES, Default, r)

#define _cjDefineVars(m,t,n,a,i) \
CjR_##t *_cj_##m##_R = [a objectAtIndex:i]; \
t n = _cj_##m##_R.value; (void) n; (void) m;

#define _cjBeginDefiningReaction(m...) [_cj_LocalJoin defineReactionWithInputNames:@[m] payload:^(NSArray *inputs) {

#define cjReact1(m0, t0, n0, body...) \
_cjBeginDefiningReaction(@#m0) \
_cjDefineVars(m0,t0,n0,inputs,0) \
body \
} runOnMainThread:NO];

#define cjReact1UI(m0, t0, n0, body...) \
_cjBeginDefiningReaction(@#m0) \
_cjDefineVars(m0,t0,n0,inputs,0) \
body \
} runOnMainThread:YES];

#define cjReact2(m0, t0, n0, m1, t1, n1, body...) \
_cjBeginDefiningReaction(@#m0,@#m1) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
body \
} runOnMainThread:NO];

#define cjReact2UI(m0, t0, n0, m1, t1, n1, body...) \
_cjBeginDefiningReaction(@#m0,@#m1) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
body \
} runOnMainThread:YES];

#define cjReact3(m0, t0, n0, m1, t1, n1, m2, t2, n2, body...) \
_cjBeginDefiningReaction(@#m0,@#m1,@#m2) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
body \
} runOnMainThread:NO];

#define cjReact3UI(m0, t0, n0, m1, t1, n1, m2, t2, n2, body...) \
_cjBeginDefiningReaction(@#m0,@#m1,@#m2) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
body \
} runOnMainThread:YES];

#define cjReact4(m0, t0, n0, m1, t1, n1, m2, t2, n2, m3, t3, n3, body...) \
_cjBeginDefiningReaction(@#m0,@#m1,@#m2,@#m3) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
_cjDefineVars(m3,t3,n3,inputs,3) \
body \
} runOnMainThread:NO];

#define cjReact4UI(m0, t0, n0, m1, t1, n1, m2, t2, n2, m3, t3, n3, body...) \
_cjBeginDefiningReaction(@#m0,@#m1,@#m2,@#m3) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
_cjDefineVars(m3,t3,n3,inputs,3) \
body \
} runOnMainThread:YES];

