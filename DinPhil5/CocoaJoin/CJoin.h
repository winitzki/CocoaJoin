//
//  CJoin.h
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import <Foundation/Foundation.h>


@class CJoin;

typedef NSNull *empty;
typedef NSNull *empty_empty;
typedef NSNull *empty_id;
typedef NSNull *empty_int;

typedef void (^CjM_empty)(void);
typedef void(^CjM_int)(int);
typedef int (^CjM_empty_int)(void);

#define _cjMkProt(t) \
@protocol CjM_##t \
- (t) value; \
@end
#define _cjMkSProt(s,t) \
@protocol CjM_##s##_##t \
- (s) value; \
@end

_cjMkProt(empty)
_cjMkProt(id)
_cjMkProt(int)
_cjMkProt(float)

_cjMkSProt(empty,int)
_cjMkSProt(id,id)
_cjMkSProt(int,empty)
_cjMkSProt(id,float)
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

- (void) emptyPutName:(NSString *)name;
- (void) idPut:(id)value name:(NSString *)name;
- (void) intPut:(int)value name:(NSString *)name;
- (void) floatPut:(float)value name:(NSString *)name;

- (int) empty_intPutName:(NSString *)name;
- (id) id_idPut:(id)value name:(NSString *)name;
- (void) empty_emptyPutName:(NSString *)name;
- (float) id_floatPut:(id)value name:(NSString *)name;

+ (void) intReply:(int)value to:(CjR_A*)molecule;
+ (void) emptyReply:(empty)value to:(CjR_A*)molecule;
+ (void) idReply:(id)value to:(CjR_A*)molecule;

/// convenience functions to convert between id and primitive types: do we need them all?
+ (int) unwrap_int:(id)value;
+ (id) unwrap_id:(id)value;
+ (float) unwrap_float:(id)value;
//+ (empty) unwrap_empty_empty:(id)value;
//+ (empty) unwrap_empty_id:(id)value;
//+ (empty) unwrap_empty_int:(id)value;
+ (id) wrap_int:(int)value;
+ (id) wrap_id:(id)value;
+ (id) wrap_float:(float)value;

@end

// Todo: implement the special reaction with JoinControl

// Syntactic sugar
#define cjFuncVar(out,m,in)  out(^m)(in)
#define cjSlow(m,t)       cjFuncVar(void,m,t)
#define cjFast(out, m, t)      cjFuncVar(out,m,t)

#define _cjAssignRadical(m,t) m = [CjR_##t name:@#m join:_cj_LocalJoin]; (void)m;

//#define cjDef(j, r...)   \
//CJoin *_cj_LocalJoin = [CJoin joinOnMainThread:NO reactionPriority:Default]; \
//cjSync(id,j,id) \
//r
#define cjDef(r...)   \
CJoin *_cj_LocalJoin = [CJoin joinOnMainThread:NO reactionPriority:Default]; \
r \
_cj_LocalJoin = nil;

#define cjDefUI(r...)   \
CJoin *_cj_LocalJoin = [CJoin joinOnMainThread:YES reactionPriority:Default]; \
r \
_cj_LocalJoin = nil;

#define cjAsync(m,t) CjR_##t * _cjAssignRadical(m,t)
#define cjSync(out,m,in) CjR_##in##_##out * _cjAssignRadical(m,in##_##out)

#define cjReply(m, v) [_cj_##m##_R reply:v]

#define _cjDefineVars(m,t,n,a,i) \
CjR_##t *_cj_##m##_R = [a objectAtIndex:i]; \
t n = _cj_##m##_R.value; (void) n;

#define _cjBeginDefiningReaction(m...) [_cj_LocalJoin defineReactionWithInputs:@[m] payload:^(NSArray *inputs) {

#define cjReact1(m0, t0, n0, body...) \
_cjBeginDefiningReaction(m0) \
_cjDefineVars(m0,t0,n0,inputs,0) \
body \
} runOnMainThread:NO];

#define cjReact1UI(m0, t0, n0, body...) \
_cjBeginDefiningReaction(m0) \
_cjDefineVars(m0,t0,n0,inputs,0) \
body \
} runOnMainThread:YES];

#define cjReact2(m0, t0, n0, m1, t1, n1, body...) \
_cjBeginDefiningReaction(m0,m1) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
body \
} runOnMainThread:NO];

#define cjReact2UI(m0, t0, n0, m1, t1, n1, body...) \
_cjBeginDefiningReaction(m0,m1) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
body \
} runOnMainThread:YES];

#define cjReact3(m0, t0, n0, m1, t1, n1, m2, t2, n2, body...) \
_cjBeginDefiningReaction(m0,m1,m2) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
body \
} runOnMainThread:NO];

#define cjReact3UI(m0, t0, n0, m1, t1, n1, m2, t2, n2, body...) \
_cjBeginDefiningReaction(m0,m1,m2) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
body \
} runOnMainThread:YES];

#define cjReact4(m0, t0, n0, m1, t1, n1, m2, t2, n2, m3, t3, n3, body...) \
_cjBeginDefiningReaction(m0,m1,m2,m3) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
_cjDefineVars(m3,t3,n3,inputs,3) \
body \
} runOnMainThread:NO];

#define cjReact4UI(m0, t0, n0, m1, t1, n1, m2, t2, n2, m3, t3, n3, body...) \
_cjBeginDefiningReaction(m0,m1,m2,m3) \
_cjDefineVars(m0,t0,n0,inputs,0) \
_cjDefineVars(m1,t1,n1,inputs,1) \
_cjDefineVars(m2,t2,n2,inputs,2) \
_cjDefineVars(m3,t3,n3,inputs,3) \
body \
} runOnMainThread:YES];

