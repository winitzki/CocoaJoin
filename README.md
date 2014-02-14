CocoaJoin
=========

An experimental implementation of join calculus in Objective-C.

Join calculus is a formal model for purely functional, concurrent computations. Join calculus is somewhat similar to "actor model" but it is "more" purely functional.

There are a few implementations of join calculus in functional programming languages such as OCaml (JoCaml), F# ("joinads"), and Scala.

For a tutorial introduction to join calculus using JoCaml, see https://sites.google.com/site/winitzki/tutorial-on-join-calculus-and-its-implementation-in-ocaml-jocaml

Overview of join calculus
-------------------------

Join calculus realizes asynchronous computations through an "abstract chemical machine". The chemical machine performs computations by simulating "chemical reactions" between "molecules". Molecules are objects labeled by a name (`a`, `b`, `c`, `incr`, `counter` and so on). Each molecule carries a _value_ on itself (an integer, a string, an object, etc.). In join calculus, this is denoted by `a(123)`, `b("yes")`, etc.

The programmer defines the names of allowed molecules and the type of value carried by each molecule (say, `a` carries integer, `b` carries string, etc.). The programmer also defines reactions that are allowed between the molecules. Each reaction consumes one or more input molecules, then performs some computation using the values carried by the input molecules, and finally can produce some output molecules with some new values. The input molecules disappear from the "chemical soup" while the reaction is running, and at the end the new output molecules are injected into the "soup".

Reactions start asynchronously and concurrently, whenever the input molecules become available. For example, suppose we define a reaction like this,

	consume a(x), b(y) => print x; print y; inject b(x+y)

and inject 5 copies of the molecule `a` and 3 copies of the molecule `b`, so that the "chemical soup" initially contains, say, the following molecules,

	a(10), a(2), a(4), a(21), a(156), b(1), b(1), b(1)

Then the chemical machine will start 3 concurrent reactions between some (randomly chosen) copies of `a` and `b`. A possible result will be that the machine prints (in random order)

	21 1
	2 1
	156 1

and the soup then contains

	a(10), b(3), a(4), b(22), b(157)

The chemical machine will not stop here, because some more reactions between `a` and `b` are possible. Reactions will continue to run concurrently in random order. In the present example, two more reactions are possible between some `a` and `b` molecules. A possible result is that the machine prints

	10 22
	4 3

and the soup now contains

	b(32), b(7), b(157)

At this point, no more reactions are possible, and the "chemical machine" will wait. If more `a` molecules are injected, further reactions will start.

Remarks
-------

By default all reactions start _asynchronously_ (in a different thread). For this reason, injecting a molecule `a` does not immediately start a reaction even if some molecules `b` are already present in the soup. Also, reactions start in random order; if there are several reactions involving the same input molecules, a randomly chosen reaction will start. So it is the responsibility of the programmer to design the "chemistry" such that the desired values are computed in the right order, while other values are computed concurrently.

Reactions do not _have_ to inject any output molecules. If a reaction does not inject any output, the input molecules will be consumed and will disappear from the soup. However, a reaction _must_ consume at least one input molecule.

The reaction's "body" is written as a pure function that takes each input molecule's value as an argument. For now, we write reactions using pseudocode with keywords such as `consume`, `inject`, etc. These keywords are used here just for clarity; they do not correspond to the syntax of any existing implementation of join calculus.

For instance, consider the reaction

	consume a(x), b(y) => 
		let r = compute_whatever(x,y) in
		inject c(r),a(x),a(y),a(22); // whatever

This reaction takes `x` and `y` as arguments and computes a function, then injects some new molecules back into the soup. The values carried by the output molecules are pure functions of the values carried by the input molecules.

The names of the input molecules of a reaction must be all different, and the argument names also must be all different. Thus it is not allowed to define reactions such as

	consume a(x), a(y), a(z) => ... (wrong)

or

	consume a(x), b(x), c(x) => ... (wrong)

This limitation ("reactions must be _linear_ in the input") is not really restricting the computational power of join calculus.

The definition of a set of reactions that use the same input molecules is called a *join definition*. More precisely, a join definition defines at the same time the names of the input molecules and all the reactions involving these input molecules. The names of the input molecules are treated as _new_ local values, shadowing any previously visible definition of these names.

Reactions involving the same input molecules always have to be defined together in a single join definition. For example, consider the following two reactions,

	consume a(x), b(y) => ...
	consume b(y), c(z) => ...

Both reactions have the molecule `b` as an input molecule, so we need to define these reactions together with declaring the new molecule names `a`, `b`, `c`.


	consume a(x), b(y) => inject b(x+y)
	consume c(x), d(y) => inject a(x-y)

These two reactions do not have a common input molecule. For this reason, we do not necessarily have to define them together in a single join definition. However, note that the first reaction defines the name `a` for the molecule that is used in the second reaction. For this reason, the second reaction needs to be defined _after_ the first one, and the definition of the second reaction must be made within a scope where the name `a` is still visible.

Once a join definition is made that involves some new molecules as inputs, the "chemistry" of the new molecules is set in stone - no further reactions can be added to the same input molecules. In other words, reactions and molecule names are defined _statically_.

In join calculus, the molecule names (`a`, `b`, etc.) are syntactically function names and play the role of "injectors" for molecules. By writing `a(2)`, the programmer performs an injection of the molecule `a` with value `2` into the soup. The construction `a(2)` is, in fact, _not_ a value in the program, because it represents the "fully constructed molecule" that exists only within the "chemical soup". On the other hand, the molecule name `a` is a local value in the program, it can be given as an argument to a function, stored in an array, and so on.

It is important to realize that molecule names are _local_ values in join calculus. These values are created whenever a new reaction is defined that uses these names as input molecules. For this reason, it is possible to encapsulate reactions safely within a local scope (say, within the scope of a function). The reactions defined for these molecules are encapsulated within the local scope and are not visible outside that scope. The outside scope cannot modify these reactions or directly access all the molecules defined inside. If some of these new molecules are needed outside the local scope, their names must be returned to the outer scope, say as return values of the function. The outer scope will then be able only to _inject_ these new molecules into the soup, but not define any new reactions for them. There is an example of this functionality below.

Synchronous molecules
---------------------

In addition to the molecules that start reactions asynchronously, there is a second type of molecules that are "synchronous" or "fast". A fast molecule, when injected into the soup, behaves like an ordinary function: it blocks the execution thread and returns a value to the caller.

Injecting a "slow" molecule returns right away (whether reactions can start or not) and does not block the execution thread. In contrast, injecting a "fast" molecule will try starting a reaction with this molecule right away (or as soon as possible). In other words, injecting a "fast" molecule will _block_ the execution thread until the machine can run some reaction involving this fast molecule. In the course of the reaction, a special operator "reply" can be used on the "fast" molecule. The operator "reply" looks like this, 

	reply x to m

This assigns the return value `x` to the "fast" molecule `m`. This cannot be used on a "slow" molecule.

Once the `reply` operator is called, the injecting thread unblocks and the value is returned from the injection call. The reaction, meanwhile, continues (perhaps asynchronously) and may inject other molecules into the soup or "reply" to other fast molecules.

Example 1: asynchronous counter
-------------------------------

Here is how one can implement an "asynchronous counter".

Define molecule `inc` with empty value and `counter` with integer value. Define a fast molecule `get` with empty value, returning int. Define two reactions:

 	consume inc(), counter(n) => inject counter(n+1)
    consume get(), counter(n) => inject counter(n), reply n to get

Initially, we inject `counter(0)`. Then, at any time inject `inc()` to increment the counter and `get()` to obtain the current value.

This pair of reactions works as follows. Whenever a molecule `inc()` is injected, the `counter` molecule is consumed and then injected into the soup with a new value. Whenever the `get` molecule is injected, the current value of `n` is returned.

For example,

	inc(); inc(); 
	usleep(200000); // wait until counter is asynchronously incremented 
	int x = get();

will assign `2` to `x`, as long as we wait long enough for the reactions to start.

The operational semantics of join calculus guarantees that the molecule `counter` disappears from the soup whenever each reaction starts. For this reason, it is possible to inject many copies of `inc()` simultaneously; there is no problem with concurrent updates of the `counter` value, and it does not matter in which order the reactions are started.

Nevertheless, this implementation is brittle because the user could forget to inject the `counter(0)` molecule at the beginning of the program, and then no reactions will ever run and the call to `get` will block forever. The user could also, by mistake, inject several copies of `counter` into the soup, and then the results of `get` will be unpredictable.

In order to fix this problem, we can define the reactions within a local scope. Pseudocode:

	define_counter = function(initial_value) {
		define counter(int), inc(); define synchronous get();
		define reactions
			consume inc(), counter(n) => inject counter(n+1)
			consume get(), counter(n) => inject counter(n), reply n to get
		inject counter(initial_value)
		return (inc, get)
	}
	// outer scope

	(inc, get) = define_counter(0)

	inc()
	inc()
	usleep(200000)
	int x = get();

The function `define_counter` returns a pair of two molecule names, `inc` and `get`, defined within the local scope. The outer scope can then call inc() to increment the counter asynchronously, and get() to obtain the current value synchronously.

The molecule `counter` is also defined within the local scope but is not returned. So the outer scope cannot make mistakes using the counter's functionality.

The function `define_counter` defines two reactions, which constitute the "join definition" that determines the "chemistry" of the input molecules `inc`, `get`, and `counter`. The "chemistry" is defined statically: After this definition, the reactions cannot be modified, and the user cannot add new reactions that _consume_ `inc`, `get`, or `counter` as input molecules.

The user can certainly add new reactions that consume other molecules and _inject_ `inc` or `get`. However, the user cannot define a new reaction that, say, consumes `inc` or `get`. What happens if the user tries to define a _new_ reactions that consumes `inc`, say

	consume inc() => print "gotcha"

The result will be that a _new_ name `inc` is defined, with this new reaction. This new `inc` belongs to a new join definition and cannot react to the old `counter` molecule. This is so because a join definition always _defines_ the input molecule names as new values in the local scope.

Due to this feature, local reactions are encapsulated and can be safely used from an outer scope.

Example 2: map/reduce
---------------------

"Map": We need to schedule `n` computational tasks `compute_something(x)` concurrently on each element `x` of a collection `C`. "Reduce": as soon as each task is finished, we need to collect the intermediate results and merge them repeatedly together with the function `reduce(a,b)` in order to compute the final value.

We assume that the reducer is associative: 

`reduce(a,reduce(b,c)) = reduce(reduce(a,b),c)`

Thus, we are allowed to reduce the intermediate results in any order and even concurrently, as long as no intermediate values are lost.

We design the "chemistry" as follows:

- each task is initiated by a molecule `begin(x)` by itself
- when the computation is finished, a molecule `done(result)` is injected, carrying the result value of the computation

		consume begin(x) =>  inject done(result), where result = compute_something(x) 

- ideally we would like to define the "reduce" reaction like this:

		consume done(x), done(y) => inject done(z), where z = reduce(x,y)

If this were possible, we would achieve the result that all reducing operations start concurrently. However, we are not allowed to define reactions that consume two copies of the same molecule. We need to use a different molecule instead of `done(y)`, so we change this reaction to

		consume done(x), done'(y) => inject done(z), where z = reduce(x,y)

To convert `done` into `done'`, we use another reaction with a `primer` molecule:

		consume done(x), primer() => inject done'(x)

Now we just need to make sure that there are enough `primer` molecules in the soup, so that all intermediate results get reduced. Here is how we can reason about this situation. If we have `n` tasks, we need to call the reducer `n-1` times in total. The reducer is called once per a "primed" molecule `done'`. Therefore, we need to create `n-1` primed molecules, which is possible only if we have `n-1` copies of `primer()` in the soup. If we inject `n-1` copies of `primer()` into the soup at the beginning, the result at the end will be a single `done(z)` molecule, regardless of the order of intermediate reactions.

- finally, we need to signal that all jobs are finished. A single `done(z)` molecule will carry our result `z`, but it will stay in the soup indefinitely and will not start any reactions by itself. In join calculus, we cannot define a reaction with a "guard condition", such as

		consume done(x) when x > 100 => ... (wrong)

Reactions start when input molecules are present, regardless of the values on the molecules. Guard conditions are not part of the language.

Therefore, we need to be able to detect, _before_ injecting the last `done` molecule, that this molecule is going to be the last one. The only way to know that is if the `done` molecule carries on itself the number of already performed reductions. Thus, we let the `done` molecule carry a pair: `done(x,k)` where `k` shows how many reductions were already performed. When a single task is done, we inject `done(x,1)` into the soup:

		consume begin(x) => inject done (z, 1) where z = compute_something(x)

When we reduce two values to one, we add their `k` values:

		consume done(x,k), done'(y,l) => inject done( reduce(x,y), k+l )

Just one more refinement of this: when `k+l` becomes equal to `n`, we need to stop and signal completion. For instance, like this:

		consume done(x,k), done'(y,l) => 
			if m==n then inject all_done(z) 
			else inject done(z,m) 
			where
				z=reduce(x,y)
				m=k+l

This completes the implementation of map/reduce with fully concurrent computations. The full pseudocode looks like this (assuming integer values):

	function map_reduce(initial_array, compute_something, reduce, all_done) {
		let n = length of initial_array
		
		define molecules begin(integer), done(integer, integer), done'(integer),
			primer(void);
		consume begin(x) => inject done(z, 1) where z = compute_something(x);
		consume done(x,k), primer() => inject done'(x,k);
		consume done(x,k), done'(y,l) => 
			if k+l==n then inject all_done(z) 
			else inject done(z,k+l) 
			where z=reduce(x,y);
		inject begin(x) for x in initial_array;
		inject (n-1) copies of primer();
	}

This function receives a previously defined molecule name, `all_done`, to signal asynchronously that the job is complete and to deliver the final result value. All reactions and newly defined molecules remain hidden in the local scope of the function.

With a slightly different set of "chemical laws", it is possible to signal completion synchronously, or to limit the number of concurrently running tasks, or to provide only a fixed number of concurrent reducers.

In this way, the programmer can organize the concurrent computations in any desired manner.

Summary of features of join calculus
------------------------------------

Join calculus is a purely functional, declarative model of concurrent computation. Join calculus is uses only a small subset of features (pure functions with arguments; locally scoped, typed values; threads and semaphores) that are available in most programming languages and platforms. For this reason, join calculus can be easily embedded as a library in most programming languages.

Join calculus gives the programmer has the following basic functionality:

* define arbitrary names for molecules, with arbitrary types of values
* jointly define several reactions with one or more input molecules
* inject molecules with values into the soup at any time (also within reactions)
* use molecule names as locally defined values, pass them to functions, store them in local data structures

The programmer can use any number of molecules and reactions. By defining the "chemistry" in a suitable way, the programmer can organize concurrent computations in any desired fashion, while remaining within the declarative and purely functional paradigm. For instance, the programmer can:

* use "fast" molecules in order to wait synchronously until certain reaction start or end
* use "slow" molecules to receive response asynchronously from other reactions
* use "fast" molecules to receive values synchronously from other reactions
* use locally defined reactions to encapsulate and reuse concurrent functionality
* create new reactions and molecules inside recursive functions, thus creating a dynamic, recursive graph of reactions at run time
* use "higher-order" chemistry: molecules can carry values that contain _other molecule names_ or _functions of molecule names_, which then become available within a reaction and may be used to inject arbitrary molecules or to perform arbitrary computations 

Join calculus has the following advantages over other models of concurrent computation:

* concurrency is declarative and simple to reason about because the operational semantics is based on just two easily visualized principles:

1. A reaction starts whenever the required input molecules are present in the soup.
2. A reaction consumes input molecules from the soup, then performs a computation, and then injects the output molecules into the soup.

* join definitions are locally scoped and _statically_ defined; reactions are guaranteed to be immutable, the programmer cannot redefine a reaction by mistake or inject molecules that are invisible in the present scope
* each computation is a pure function in a local scope, there is no global "state of the chemistry"
* all concurrent computations are scheduled  _implicitly_: there is no hand-written code for creating or stopping new threads, scheduling new jobs, or waiting for completion
* one core or multicore, one threads or many threads - these low-level details are hidden from the programmer, who merely needs to inject some molecules to initiate concurrent computations
* the use of low-level synchronization primitives, such as locks and semaphores, is implicit in the "laws of chemistry" defined by the programmer
* the programmer does not manipulate shared mutable state; all state is represented by values carried by the molecules, passed automatically and implicitly from one reaction to another

Notes on the Objective-C implementation
---------------------------------------

This implementation of join calculus in Objective-C is called `CocoaJoin` and consists of a small library and a set of CPP convenience macros. The implementation uses Apple's multithreading library GCD ("grand central dispatch") to schedule reactions. Each "join definition" allocates a new asynchronous queue for reactions (however, GCD will make sure not to overload the available CPU cores). A semaphore and shared state is used to implement "fast" molecules. Molecule names are anonymous closures ("Objective-C blocks" as Apple calls them).

To use the library, import `CJoin.h`. Compile the .m files in CocoaJoin/. The implementation uses ARC and should work on iOS 6.0 and up.

For convenience, macros are provided. The example of "asynchronous counter" is implemented in the tests and looks like this:

    cjDef(
       
          cjAsync(inc, empty) // define slow molecule, inc()
          cjAsync(counter, int) // define slow molecule, counter(int x)
          cjSync(int, getValue, empty) // define fast molecule, int getValue()
          
          cjReact2(inc, empty, dummy, counter, int, n, // using the name "dummy" for empty value
           [counter put:n+1]; ); // define reaction: consume inc(), counter(n), inject counter(n+1)
          cjReact2(counter, int, n, getValue, empty_int, dummy,
           [counter put:n], cjReply(getValue, n); ); // define reaction: consume counter(n), getValue(), inject counter(n) and reply n to getValue
    );
    [counter put:0], [inc put], [inc put];
    [self cycleMainLoopForSeconds:0.2];	// allow enough time for reactions to run
    
    int v = [getValue put]; // getValue returns 2

CocoaJoin modifies the model of join calculus in some inessential ways:

* Only a subset of primitive types are supported for molecule values: `empty`, `int`, `float`, `id.` Similarly, the return values of fast molecules can have only these types. Here `empty` is the functionally same as NSNull.
* Molecule names are local values of certain predefined classes such as `CjR_int`, `CjR_empty`, `CjR_id_id`, etc., depending on the types of values. (Fully constructed molecules are not available as objects, as in JoCaml.)

Available classes:

	CjR_A -- abstract parent class of all molecule names (fast or slow)
	CjS_A -- abstract parent class of all fast molecule names
	CjR_empty -- name of a slow molecule with empty value, inc()
	CjR_id -- name of a slow molecule with id value, such as s(@"x")
	CjR_int -- name of a slow molecule with int value
	CjR_float -- name of a slow molecule with float value
	CjR_empty_empty -- name of a fast molecule with empty value, returning empty

Other types of this form: `CjR_`_t_`_`_r_  represents a name of a fast molecule carrying value of type _t_ returning a value of type _r_. In ordinary join calculus, this type would be a function _t_ -> _r_.

* The syntax of molecule injection is not `a(x)` or `b()` but `[a put:x]` and `[b put]`.
* The syntax of `reply` is `[f reply:x]` or `[f reply]`, where `f` must be a fast molecule. (Otherwise, there will be a compile-time error, since the `reply` method is only defined for fast molecules.)
* It is not possible to make two join definitions one after another in the same local scope.
* To make a new join definition, each new molecule name must be defined with its explicit type.

We need to list explicitly all the newly declared input names, because otherwise we cannot generate code for defining them. (The macro processor is unable to process arrays of parameters.)

* Defining a reaction with an input name that has already been defined in the same local scope is impossible (it may result in a compiler error due to name clash).

This is so because the definition of an input name is equivalent in Objective-C to

	CjR_int *counter = ...

If the name `counter` is already locally defined, it is a compile-time error to define the same name again in the same scope. No error will result if the name is redefined within another local scope.

* A join definition is represented by an object of class `CJoin` (the "join object").

The join object is not visible directly. After performing a join definition, the join object initializes its job queue and is ready to accept any injected molecules known to it, i.e. any of its input molecules. When the join object is destroyed, it also destroys the queue it has created.
     
Each molecule name carries a strong reference to the join object to which it belongs, and there are no other references to the join object. Once you destroy the last molecule name that uses the join object, the join is gone.

Together with the join object, the molecule names are created in the local scope, and their reactions have been defined and stored in the join object.

* A reaction may be designated for the "UI thread".

By default, all computations run asynchronously on a background thread, but updating UI on the iOS platform requires to call certain methods on the "UI thread" (or "main thread"). 

For this reason, a special feature is added to join calculus: the user can designate some reactions to run on the "UI thread". In addition, the user can specify that some join definitions to run on the "UI thread". 

* A join definition may be designated for the "UI thread".

Each join definition runs concurrently in order to schedule its reactions independently of other join definitions. The user can specify that the UI thread should be used for the code that decides which reactions can be started, i.e. for the "decision" code of the join definition. By default, this decision code will be executed on a background thread, which may cause additional delay if the molecules are injected from the UI thread and an immediate synchronous reaction is desired (as could be the case for UI-intensive computations). In this case, both the reaction and decision code for the join definition can be designated for the UI thread.

Note that join calculus intentionally restricts the tasks that the decision code for join definitions needs to perform. The decision code only needs to check which molecules are present and which reactions can be scheduled to start. (In join calculus, reactions start whenever the input molecules are present, regardless of the molecule values.) So, the decision code does not check the values of any molecules and does not call any user-defined functions. In the worst case (many molecules are present and all possible reactions can be started), the decision code will run in time linear in the total number of _locally defined_ molecules and reactions. (Each join definition decides only local reactions, not all reactions defined anywhere in the program!) For this reason, it is often acceptable to designate some join definitions for the UI thread, especially if the number of local reactions is small for these join definitions.

* Weak typing

When the user defines a molecule name with some type such as `int`, the compiler will check that the name is used with values of the correct type. So, after defining `cjAsync(counter, int)` it will be an error to inject this molecule as `[counter put:@"x"]`. However, this error becomes merely a warning with the type `id` since this type is compatible with any other object type.

* Thread safety

Each molecule carries a value that may cross thread boundaries. This can happen in several cases:

- the molecule is injected on a background thread but a reaction is designated for the UI thread
- both the injection and the reaction are on background threads, but the GCD system running on a multicore CPU decides to run them on _different_ background threads

Not all Objective-C values are thread-safe in the sense of being able to pass from one thread to another without crashing. In particular, UIKit view objects and Core Data values _cannot_ pass thread boundaries without severe problems (crash, incorrect visual display, or loss of data). Join calculus is designed to operate on immutable values; therefore, Objective-C anonymous closures, immutable objects, and immutable collections should be safe.

If it is required to use a mutable object or collection, join calculus can easily guarantee that only one thread will ever modify the object. To achieve this, define a reaction that consumes a certain input molecule, and then hide this reaction and the molecule in a local scope that injects a single copy of the molecule into the soup. This will make sure that there is ever at most one copy of this molecule in the soup. Thus, there will never be several concurrent reactions of this type. The example of "asynchronous counter" uses this technique.

`CocoaJoin` uses ARC (automatic reference counting), which means that injecting heap-allocated values is mostly unproblematic. An exception is the case of anonymous closures as molecule values. This is still problematic due to the limitations of Objective-C (no garbage collection and no generics). Because of lack of generics, the closure must be represented by the type `id`, and then the memory management rests with the programmer. The problem may be that injecting a molecule carrying a closure requires that the closure should be first manually copied to the heap - otherwise the memory management system will lose the closure, causing a crash later (without a stack trace!). A solution can be to cast a closure manually to some fiducial object type (such as `NSBlock`), so that the memory management system thinks it's an Objective-C object with standard memory management, and then to cast the closure back to its correct type (so that the system allows the programmer to use the closure at all).

In the current implementation, molecule names _are_ anonymous closures, so the users of "higher-order chemistry" must confront this problem!

Finally, Objective-C cannot fully guarantee static typing or fully hide private variables. Nevertheless, Objective-C has local scope and weak typing. It will be certainly possible to break the functionality of CocoaJoin; the compiler cannot prevent using private methods or calling some methods incorrectly. But the library should work correctly as long as the user does not go outside the provided macros.

Dining Philosophers
-------------------

DinPhil5 is a test project that shows a simple solution of the "dining philosophers" problem in a barebones UI. 

The core logic is implemented in "DiningPhilosophicalLogic.m"; consult that file for the actual working code.

There is a single join definition, which is is asynchronous, and all other reactions are also asynchronous, except for a single reaction designated for the UI thread. This reaction updates the visual display of the philosophers.

Available macros
----------------

Make a local join definition:
- a join definition with decision code on a background thread

`cjDef(...)`

- a join definition with decision code on the UI thread
	
`cjDefUI(...)`

What goes inside the `cjDef` macro:
- definitions of names and types for all new input molecules using `cjAsync` or `cjSync`
- definitions of all reactions using `cjReact1`, `cjReact2`, etc.

Define a new input molecule name:

- slow molecule with value of type `t`

`cjAsync(name, t)`

- fast molecule with value of type `tin`, returning value of type `tout`

`cjSync(tout, name, tin)`

Define a new reaction:

- reactions taking a single input molecule:

	cjReact1(name1, type1, var1, code...)
	cjReact1UI(name1, type1, var1, code...)

`name1` must be a newly defined molecule name (value will be created in local scope).
`type1` is the type of the value of that molecule. For fast molecules, separate type with underscore: for example, `empty_int` or `id_id`.
`var1` is the name of the formal parameter bound to the value of that molecule within the reaction body.
`code` is the body of the reaction; this may use the locally defined names `name1` and `var1`.

- reactions taking two input molecules:

	cjReact2(name1, type1, var1, name2, type2, var2, code...)
	cjReact2UI(name1, type1, var1, name2, type2, var2, code...)

Similar macros `cjReact3`, `cjReact3UI`, `cjReact4`, and `cjReact4UI` are available. Further such macros are straightforward to implement. (See `CJoin.h`.)

The "UI" versions of the macros define reactions that are designated for the UI thread.

Here is an example of using the reaction macros.  To convert the pseudocode such as

	consume a(x), b(y), c() => do_computations(x,y); inject a(x+y), c()

into a macro call, we need to specify the names of the input molecules (`a`, `b`, `c`), the types of their arguments (`int`, `int`, `empty`), and the names of the formal parameters (`x`, `y`, `dummy`), and finally we need to write the function code for the reaction. Since there are three input molecules, we use the macro `cjReact3` and write

	cjReact3(a, int, x, b, int, y, c, empty, dummy, { 
		do_computations(x,y); [a put:x+y], [c put];
	})

Here we have put the reaction body into its own block for visual clarity, but this is not necessary. Also, it is optional whether to inject the molecules with the comma operator or through separate statements `[a put:x+y]; [c put];`. The reaction block returns nothing.

Note that we have used the name `dummy` for the argument of the empty type. This is necessary for technical reasons (the CPP macros are insufficiently powerful here). We are required to specify names for all arguments, even if the value is empty. So the reaction body will see a local variable named `dummy` with value equal to `[NSNull null]`.

The `reply` operator:
- reply with value `val` to a fast molecule named `name`

`cjReply(name, val)`

The `reply` operator, as well as injections of known molecules, can be used anywhere in the reaction block.

Current status of CocoaJoin
---------------------------

This is version 0.1. Right now, the operational semantics of join calculus is fully implemented.

The CocoaJoin version 0.1 was tested on two few examples: synchronous and asynchronous counters. In addition, the "dining philosophers" problem is implemented with a barebones GUI.

In the future, I might look into more features such as:

* Define special global methods for controlling the "chemical machine" as a whole, or for controlling specific local join definitions.

Possible functions: stats (get statistics on the number of molecules and reactions), pause (do not schedule any new reactions), resume (start scheduling reactions again), clear (remove all present molecules in all reactions, stop all reactions, reply immediately to all fast molecules, and ignore requests to inject any new molecules).

These global operations, as well as the corresponding local operations, can be implemented most easily via special predefined fast molecules that already have predefined reactions.

* Implement molecule names as locally defined blocks, so that the syntax `counter(3)` or `inc()` can be used instead of the more verbose Objective-C syntax.

The CocoaJoin API is subject to change. I am still investigating ways to simplify the calling conventions. A previous attempt to implement the `counter(3)` syntax was unsuccessful: sufficiently convenient macros could not be defined.

