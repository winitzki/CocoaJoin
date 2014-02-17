CocoaJoin
=========

An experimental implementation of join calculus in Objective-C.

Join calculus is a formal model for (mostly) purely functional, concurrent computations. Join calculus is somewhat similar to the actor model, but join calculus is, so to speak, "more" purely functional.

There are a few implementations of join calculus in functional programming languages such as OCaml (JoCaml), F# ("joinads"), and Scala.

For a tutorial introduction to join calculus using JoCaml, see https://sites.google.com/site/winitzki/tutorial-on-join-calculus-and-its-implementation-in-ocaml-jocaml

This project contains the join calculus library and an example iOS application, `DinPhil5`, that shows five "dining philosophers" taking turns thinking and eating.

Version history
---------------

* Version 0.2.1

CocoaJoin is now compiled as a static library.

Four tests pass, including a test that does not use macros.

Throwing a fatal exception at runtime if the user injects a molecule that has not been defined as input molecule for a reaction.

Added a test to make sure that background reactions have been scheduled even if the thread is blocked immediately after injecting some slow molecules.

* Version 0.2

The implementation of macros was changed to allow less verbose syntax: molecules are now injected by `a(3)`.

Avoid unnecessary copying of molecule objects on injection.

Produce compile errors if molecules are declared but not used as input in any reactions.

Define more molecule types (`empty`, `id`, `int`, `float`).

More documentation about join calculus and more examples.

* Version 0.1

The operational semantics of join calculus is fully implemented. 

Molecules are injected with Objective-C syntax, `[a put:3]` instead of `a(3)`.

"Dining philosophers" is implemented as an iPhone app.

Overview of join calculus
-------------------------

Join calculus realizes asynchronous computations through an "abstract chemical machine". The chemical machine performs computations by simulating "chemical reactions" between "molecules". Molecules are objects labeled by a name (`a`, `b`, `c`, `incr`, `counter` and so on). Each molecule carries a _value_ on itself (an integer, a string, an object, etc.). In join calculus, this is denoted by `a(123)`, `b("yes")`, etc.

The programmer defines the names of allowed molecules and the type of value carried by each molecule (say, `a` carries integer, `b` carries string, etc.). The programmer also defines reactions that are allowed between the molecules. Each reaction consumes one or more input molecules, then performs some computation using the values carried by the input molecules, and finally can produce some output molecules with some new values. The input molecules disappear from the "chemical soup" while the reaction is running, and at the end the new output molecules are injected into the "soup".

Reactions start asynchronously and concurrently, whenever the input molecules become available. For now, we write reactions using pseudocode with keywords such as `consume`, `inject`, etc. These keywords and the syntax of the pseudocode were chosen only for clarity; they do not exactly correspond to the syntax of any existing implementation of join calculus.

For example, suppose we define a reaction like this,

	consume a(x) & b(y) => print x; print y; inject b(x+y)

and then inject 5 copies of the molecule `a` and 3 copies of the molecule `b`, each with some random values:

	inject a(10), a(2), a(4), a(21), a(156);
	inject b(1), b(1), b(1);

Now the "chemical soup" contains the following molecules,

	a(10), a(2), a(4), a(21), a(156), b(1), b(1), b(1)

Then the chemical machine can start up to three concurrent reactions between some (randomly chosen) copies of `a` and `b`. Reactions will be scheduled to run concurrently, in random order, on some (unspecified number of) background threads. A possible result will be that two reactions are started at once, the machine prints

	21 1
	2 1

and the soup then contains the molecules

	a(10), b(3), a(4), b(22), a(156), b(1)

The chemical machine will not stop here, because some more reactions between `a` and `b` are possible. Reactions will continue to run concurrently in random order, and their input molecules are also chosen randomly. In the present example, three more reactions are possible between some `a` and `b` molecules. A possible result is that the machine prints

	156 3
	10 22
	4 1

and the soup now contains

	b(32), b(5), b(159)

At this point, no more reactions are possible, so the "chemical machine" will wait. If more `a` molecules are injected, further reactions will be scheduled to run.

More details
------------

By default all reactions start _asynchronously_ (in a different thread). For this reason, injecting a molecule `a` does not immediately start a reaction even if some molecules `b` are already present in the soup. Also, reactions start in random order; if there are several reactions involving the same input molecules, a randomly chosen reaction will start. So it is the responsibility of the programmer to design the "chemistry" such that the desired values are computed in the right order, while other values are computed concurrently.

When a reaction is finished, it may or may not inject any output molecules into the soup. If a reaction does not inject any output molecules, the input molecules will be consumed and will disappear from the soup. However, a reaction _must_ consume at least one input molecule.

The reaction's body is written as a pure function that takes each input molecule's value as an argument.

For instance, consider the reaction

	consume a(x) & b(y) => 
		let r = compute_whatever(x,y) in
		inject c(r), a(x), a(y), a(22); // whatever

This reaction consumes two input molecules `a` and `b`. These molecules carry values that are denoted by `x` and `y`. When the reaction starts, its body takes `x` and `y` as arguments and computes something, then injects some new molecules back into the soup. The values carried by the output molecules are functions of the values carried by the input molecules.

The names of the input molecules of a reaction must be all different, and the argument names also must be all different. Thus it is not allowed to define reactions such as

	consume a(x) & a(y) & a(z) => ... (wrong)

or

	consume a(x) & b(x) & c(x) => ... (wrong)

This limitation ("reactions must be _linear_ in the input") is not really restricting the computational power of join calculus.

The definition of a set of reactions that use the same input molecules is called a *join definition*. More precisely, a join definition defines at the same time the names of the input molecules and all the reactions involving these input molecules. The names of the input molecules are treated as _new_ local values, shadowing any previously visible definition of these names.

Reactions involving the same input molecules always have to be defined together in a single join definition. For example, consider the following two reactions,

	consume a(x) & b(y) => ...
	consume b(y) & c(z) => ...

Both reactions have the molecule `b` as an input molecule, so we need to define these reactions together with declaring the new molecule names `a`, `b`, `c`.

	consume a(x) & b(y) => inject b(x+y)
	consume c(x) & d(y) => inject a(x-y)

These two reactions do not have a common input molecule. For this reason, we do not necessarily have to define them together in a single join definition. However, note that the first reaction defines the name `a` for the molecule that is used in the second reaction. For this reason, the second reaction needs to be defined _after_ the first one, and the definition of the second reaction must be made within a scope where the name `a` is still visible.

Once a join definition is made that involves some new molecules as inputs, the "chemistry" of the new molecules is set in stone - no further reactions can be added to the same input molecules. In other words, reactions and molecule names are defined _statically_.

In join calculus, the molecule names (`a`, `b`, etc.) are syntactically function names and play the role of "injectors" for molecules. By writing `a(2)`, the programmer performs an injection of the molecule `a` with value `2` into the soup. The operator `inject a(2)` does not return any value (or, formally, you can say it returns an _empty_ value). So, by itself, the construction `a(2)` is _not_ a value accessible in the program, but rather it represents the "fully constructed molecule" that exists only within the "chemical soup". On the other hand, the molecule name `a` is a local (and immutable) value in the program, it can be given as an argument to a function, stored in an array, and so on.

It is important to realize that molecule names are _local_ values in join calculus. These values are created whenever a new reaction is defined that uses these names as input molecules. For this reason, it is possible to encapsulate reactions safely within a local scope (say, within the scope of a function). The new molecule names and the reactions defined for these molecules are all encapsulated within the local scope and are not visible outside that scope. The outside scope cannot modify these reactions or directly access all the molecules defined inside. If some of these new molecules are needed outside the local scope, their names must be returned to the outer scope, say as return values of the function. The outer scope will then be able only to _inject_ these new molecules into the soup, but not define any new reactions for them. There is an example of this functionality below.

Synchronous molecules
---------------------

In addition to the molecules that start reactions asynchronously, there is a second type of molecules that are "synchronous" or "fast". A fast molecule, when injected into the soup, behaves like an ordinary function: it blocks the execution thread and returns a value to the caller.

Injecting a "slow" molecule returns right away (whether reactions can start or not) and does not block the execution thread. In contrast, injecting a "fast" molecule will try starting a reaction with this molecule right away (or as soon as possible). In other words, injecting a "fast" molecule will _block_ the execution thread until the machine can run some reaction involving this fast molecule. In the course of the reaction, a special operator "reply" can be used on the "fast" molecule. The operator "reply" looks like this, 

	reply x to m

This assigns the return value `x` to the "fast" molecule `m`. The `reply` operator cannot be used on a "slow" molecule. (So, if we see a `reply` operator, we know that it is applied to a fast molecule.)

Once the `reply` operator is called, the injecting thread unblocks and the value is returned from the injection call. Thus, the call `m()` will return the value `x`, like an ordinary, blocking function call. The reaction, meanwhile, continues (perhaps asynchronously on a different thread) and may inject other molecules into the soup or "reply" to other fast molecules.

Referential transparency
------------------------

It is important to keep in mind that join calculus is _not_ fully referentially transparent because the operators we denoted by `inject` and by `reply`, as well as "fast" molecule invocations, have side effects (change the state of the chemical soup).

The operators `inject` and `reply` are, technically speaking, functions that return an empty value. These operators cannot be replaced by their return values, which is a violation of referential transparency. Nevertheless, the _order_ of these operations is not significant because the operational semantics of join calculus says that molecule injections and reactions may happen in random order. Thus, if we need to perform several `inject` and `reply` operation, together with other calculations, we may put these operations in any order, e.g.

`inject a(), inject b(), let x=y+z, reply x to c(), inject d()`

and so on. 

The order of `inject` operations _is_ significant when using fast molecules. For example, consider the following reaction, where `f()` is a fast molecule and `a()` is a slow molecule:

	consume a() & f() => reply 123 to f()

In this case, the expression `inject a(); f()` will return 123. However, the expression `f(); inject a();` may block forever if no `a()` molecules are present in the beginning. This is so because `f()` blocks until some reaction involving `f()` can start. However, there is only one such reaction, and it can start only when `a()` is present.

Example 1: asynchronous counter
-------------------------------

Here is how one can implement an "asynchronous counter".

Define molecule `inc` with empty value and `counter` with integer value. Define a fast molecule `get` with empty value, returning int. Define two reactions:

 	consume inc() & counter(n) => inject counter(n+1)
    consume get() & counter(n) => inject counter(n), reply n to get

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
		// define reactions
			consume inc() & counter(n) => inject counter(n+1)
			consume get() & counter(n) => inject counter(n), reply n to get
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

Example 2: run many jobs
------------------------

Suppose we need to run, say, 100 concurrent computations and wait until they are all done, then call a certain function, `all_done()`.

For each of the computations, we define a reaction with input molecule `begin(f)` where `f` is a closure that needs to be evaluated. The reaction will compute `f()` and produce a molecule `done()`. In order to initiate the computation, we will just have to inject 100 `begin` molecules, specifying the required computations as values carried by these molecules.

To simplify our example, we assume that `f` does not take an argument and that it is not necessary to collect any results of the computations. (If this is not the case, the results will have to be put onto the `done` molecule; this modification is straightforward.) The reaction for `begin` looks like this:

		consume begin(f) => f(); inject done();

Now, it remains to wait until all reactions are finished. How can we do this? We know how many `begin` molecules we injected, and we need to make sure that exactly as many `done()` molecules have been produced.

Join calculus does not allow us to query the global state of the chemical soup, to ask how many molecules of type `done` are available, or to start a reaction when exactly 100 are available. There is always only one way to do any such bookkeeping: through new reactions.

So we need to introduce a new molecule, say `remain(x)`, that counts how many computations remain. Here is a simple way of doing this:

		consume remain(x) & done() => inject remain(x-1)

Now, if we inject a _single_ instance of `remain(100)` at the beginning, we can be sure that at most one copy of `remain` is available in the soup at any time. The reaction will consume the `done()` molecules one by one, i.e. sequentially, without any possibility for a race condition or deadlock. (We get this functionality from join calculus "for free".)

The entire code now becomes two coupled reactions:

		consume begin(f) => f(); inject done()
		consume remain(x) & done() => if x==1 then all_done() else inject remain(x-1)
		inject remain(100)
		inject begin(...), begin(...), ...

This code will work, but there are some minor problems with it:

- we would like to avoid injecting the `begin` molecules by hand
- the code is "brittle": if the programmer mistakenly forgets to inject `remain(100)`, or injects `remain(x)` with another value of `x`, or later injects several more copies of `remain` or `done()`, the reactions will not work as desired! The closure `all_done` could be called too early, or called several times, or not called at all.

This useful functionality can be protected from change and at the same time encapsulated by a function that receives as arguments, say, a collection of closures to be evaluated and an `all_done` closure. The function will hide the molecule and reaction definitions within its scope.

	run_all_and_report(array, all_done) =
		{
			consume begin(f) => f(); inject done()
			consume remain(x) & done() => if x==1 then all_done() else inject remain(x-1)
			inject remain(array.length)
			inject begin(f) for each f in array
		}

It is important to note that the molecule `remain` is invisible outside this function. So the user will not be able to inject `remain` with an incorrect value or too many times.

In fact, the user of this function will not be able to inject `remain`, or `begin`, or `done` at all. The only scope where these molecule names are visible is the local scope of the function `run_all_and_report`.

Example 3: map/reduce
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

		consume done(x) & done(y) =>  (wrong!)
			inject done(z) where z = reduce(x,y)

If this were possible, we would achieve the result that all reducing operations start concurrently. However, we are not allowed to define reactions that consume two copies of the same molecule. We need to use a different molecule instead of `done(y)`, so we change this reaction to

		consume done(x) & done'(y) => inject done(z) where z = reduce(x,y)

To convert `done` into `done'`, we use another reaction with a `primer` molecule:

		consume done(x) & primer() => inject done'(x)

Now we just need to make sure that there are enough `primer` molecules in the soup, so that all intermediate results get reduced. Here is how we can reason about this situation. If we have `n` tasks, we need to call the reducer `n-1` times in total. The reducer is called once per a "primed" molecule `done'`. Therefore, we need to create `n-1` primed molecules, which is possible only if we have `n-1` copies of `primer()` in the soup. If we inject `n-1` copies of `primer()` into the soup at the beginning, the result at the end will be a single `done(z)` molecule, regardless of the order of intermediate reactions.

- finally, we need to signal that all jobs are finished. A single `done(z)` molecule will carry our result `z`, but it will stay in the soup indefinitely and will not start any reactions by itself. In join calculus, we cannot define a reaction with a "guard condition", such as

		consume done(x) if (x > 100) => ... (wrong)

Reactions start whenever input molecules are present, regardless of the values on the molecules. Guard conditions are not part of the join calculus.

Therefore, we need to be able to detect, _before_ injecting the last `done` molecule, that this molecule is going to be the last one. The only way to know that is if the `done` molecule carries on itself the number of already performed reductions. Thus, we let the `done` molecule carry a pair: `done(x,k)` where `k` shows how many reductions were already performed. When a single task is done, we inject `done(x,1)` into the soup:

		consume begin(x) => inject done (z, 1) where z = compute_something(x)

When we reduce two values to one, we add their `k` values:

		consume done(x,k) & done'(y,l) => inject done( reduce(x,y), k+l )

Just one more refinement of this: when `k+l` becomes equal to `n`, we need to stop and signal completion. For instance, like this:

		consume done(x,k) & done'(y,l) => 
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
		consume done(x,k) & primer() => inject done'(x,k);
		consume done(x,k) & done'(y,l) => 
			if k+l==n then inject all_done(z) 
			else inject done(z,k+l) 
			where z=reduce(x,y);
		inject begin(x) for x in initial_array;
		inject (n-1) copies of primer();
	}

This function receives a previously defined molecule name, `all_done`, to signal asynchronously that the job is complete and to deliver the final result value. All reactions and newly defined molecules remain hidden in the local scope of the function.

The function `map_reduce` can be seen as part of a "standard chemical library" of predefined molecules and reactions that can be reused by programmers.

With a slightly different set of "chemical laws", it is possible to signal completion synchronously, or to limit the number of concurrently running tasks, or to provide only a fixed number of concurrent reducers.

In this way, the programmer can organize the concurrent computations in any desired manner.

Example 4: enable/disable
-------------------------

In an interactive application, we might have a button that starts an asynchronous computation. This can be implemented in join calculus by making the button inject a slow molecule that starts an asynchronous reaction. Now, suppose we would like to "enable" or "disable" this response: when "disabled", the molecule should not start the computation.

Here is how this functionality can be implemented in a "chemical library".

Reactions are defined statically, so there is no way to modify a reaction so that, say, a new input molecule is required. All input molecules for the reaction have been already defined; now we would like to control whether this reaction starts. The only way of doing this is to control whether the required input molecule has been injected. Instead of enabling/disabling a reaction, we will enable/disable the injection of a molecule.

Given a molecule name `m`, we define new molecule names `m_on`, `m_off`, `m_state`, `request_m` and the reactions,

		consume m_on() & m_state(_) => inject m_state(true)
		consume m_off() & m_state(_) => inject m_state(false)
		consume request_m(x) & m_state(is_on) =>
			inject ( if is_on then m(x) else () );
			inject m_state(is_on)

Injecting `m_on` or `m_off` switches the molecule state. Te user is supposed to inject `request_m(x)` instead of directly injecting `m(x)`. This will result in injecting `m(x)` only if the molecule `m` is in the state "on". Otherwise the request to inject `m` is ignored.

Other variations of this technique could put more values on the molecule `request_m`. For example, this molecule could carry not just the value `x` for the molecule `m`, but also some closures to be evaluated when the request was granted or refused. The molecule `request_m` could even carry the molecule name `m` as value and inject that molecule:

		consume request(m,x) & m_state(is_on) =>
			inject ( if is_on then m(x) else () );
			inject m_state(is_on)

Now, we can create these reactions in a local scope and return just the molecule names `m_on`, `m_off`, and `request`.

	make_switch(initial) = 
		consume m_on() & m_state(_) => inject m_state(true); reply () to m_on
		consume m_off() & m_state(_) => inject m_state(false); reply () to m_on
		consume request(m,x) & m_state(is_on) =>
			inject ( if is_on then m(x) else () );
			inject m_state(is_on)
		inject m_state(initial) // initial value of the switch
		(m_on, m_off, request) // return these names, but do not return m_state

The user of this function is then free to pass any molecule name as the value on `request`. This molecule will be either injected or not, according to the current state of the switch.

To prevent undetermined behavior in case several `m_on` and `m_off` molecules are injected at once, e.g.

	m_on(); m_off(); request(...)

we have designated `m_on` and `m_off` as fast molecules.

Note that the current implementation allows us to use several instances of `request` at the same time. The checking of the switch state is automatically non-concurrent because there is only one copy of `m_state`, so only one reaction `request & m_state => ...` can run at any one time.

Example 5: cancelable computation
---------------------------------

When a computation takes a long time, we may need to cancel it in the middle. Since it is impossible to stop a running thread from outside, what we need to do is to split the computation into several steps and check, after every step, whether we need to proceed to the next step or the computation has been cancelled. We may also need to notify an outside scope that the computation has been aborted after a certain step, and send the partial results to the outside scope.

Here is how we can implement this functionality in a "chemical library".

Splitting a long computation into steps needs to be performed by the programmer. Once this is done, we can imagine having the pseudocode

	y = step_1(x)
	z = step_2(y)
	t = step_3(z)
	...

The desired functionality should now allow programmer to rewrite this into

	y = step_1(x);
	continue_next( () => 
		z = step_2(y);
		continue_next( () =>
			t = step_3(z);
			...
		)		
	)

and achieve a computation that will not proceed to the next step once a cancellation molecule has been injected.

It seems that `continue_next` should not be a _slow_ molecule; otherwise we will be inserting unnecessary thread switching into a computation. Let us guard the call to `continue_next` by using the `make_switch` function defined in the previous example:

	(m_on, m_off, request) = make_switch(true);
	continue_next f = inject request(f, ())

Any calls to `continue_next` will result in first injecting `request(f, ())`. This molecule will do nothing if the state of the switch is "off". Otherwise the closure `f` will be evaluated on its argument `()`. To cancel the computation at any time, it is sufficient to inject the (fast) molecule `m_off`.

Summary of features of join calculus
------------------------------------

Join calculus is a (mostly) purely functional, declarative model of concurrent computation. This model does not depend on any particular programming language and can be embedded as a library in almost any host language.

Join calculus only needs a few features of the host language: 

* functions returning locally defined functions as values (molecule names are syntactically functions)
* locally scoped values (no access to values defined in another scope)
* concurrent threads (for scheduling reactions)
* sending values synchronously to a blocking call in another thread (for implementing fast molecules)
* functions with side effects (for implementing `inject`, `reply`, and fast molecules)

For this reason, join calculus can be implemented as a library in most programming languages. Any special features of the programming language (algebraic types, polymorphism, OOP, etc.) can be immediately used by the embedded join calculus library.

Join calculus gives the programmer the following basic functionality:

* define arbitrary names for molecules, with arbitrary types of values
* jointly define several reactions with one or more input molecules
* inject molecules with values into the soup at any time (also within reactions)
* use molecule names as locally defined values, pass them to functions, store them in local data structures

The programmer can use any number of molecules and reactions. By defining the "chemistry" in a suitable way, the programmer can organize concurrent computations in any desired fashion while remaining within the declarative and purely functional paradigm. For instance, the programmer can:

* use "fast" molecules in order to wait synchronously until certain reaction start or end
* use "slow" molecules to receive response asynchronously from other reactions
* use "fast" molecules to receive values synchronously from other reactions
* use locally defined reactions to encapsulate and reuse concurrent functionality
* create new reactions and molecules inside recursive functions, thus creating a dynamic, recursive graph of reactions at run time
* use "higher-order" chemistry: molecules can carry values that contain _other molecule names_ or _functions of molecule names_, which then become available within a reaction and may be used to inject arbitrary molecules or to perform arbitrary computations with molecule names obtained at run time
* create an abstract library of useful "chemical reactions" with a purely functional API

Join calculus has the following advantages over other models of concurrent computation:

* concurrency is simple to reason about because the operational semantics is based on easily visualized principles:

1. A reaction can start only if all of its input molecules are present in the soup.
2. A reaction _first_ consumes the input molecules from the soup, _then_ performs some computation and injects the output molecules into the soup.
3. All reactions can start concurrently and in random order.

* reaction and molecule name definitions are locally scoped, immutable, type-checked, and _static_ (fixed at compile time)
* the local scoping enables the _safe_ reuse of reactions: the programmer cannot, by mistake, destroy the functionality of any previously defined reactions (either by modifying the reactions or by injecting molecules at wrong times or in wrong numbers)
* each computation is a pure function in its local scope; the programmer does not manipulate shared mutable state
* state is represented by values carried by the molecules, passed automatically and implicitly from one reaction to another
* all concurrent computations are scheduled  _implicitly_: there is no hand-written code for creating or stopping new threads, scheduling new jobs, or waiting for completion; in other words, all concurrency is _declarative_
* one core or multicore, one threads or many threads - these low-level details are hidden from the programmer, who merely needs to inject some molecules to initiate concurrent computations
* the programmer does not use error-prone low-level synchronization primitives, such as locks and semaphores; instead the programmer operates with the visually clear "laws of chemistry"

Notes on the Objective-C implementation
---------------------------------------

This implementation of join calculus in Objective-C is called `CocoaJoin` and consists of a small library and a set of CPP convenience macros. The implementation uses Apple's multithreading library GCD ("grand central dispatch") to schedule reactions. Each "join definition" allocates a new asynchronous queue for reactions (however, GCD will make sure not to overload the available CPU cores). A semaphore and shared state is used to implement "fast" molecules. Molecule names are anonymous closures ("Objective-C blocks" as Apple calls them).

To use the library, import `CJoin.h`. Compile the .m files in CocoaJoin/. The implementation uses ARC and should work on iOS 6.0 and up.

For convenience, macros are provided. The example of "asynchronous counter" is implemented in the tests and looks like this:

    cjDef(
       
          cjAsync(inc, empty) // define slow molecule, inc()
          cjAsync(counter, int) // define slow molecule, counter(int x)
          cjSyncEmpty(int, getValue) // define fast molecule, int getValue()
          
          cjReact2(inc, empty, dummy, counter, int, n, // using the name "dummy" for empty value
           counter(n+1); ); // define reaction: consume inc(), counter(n), inject counter(n+1)
           // define reaction: consume counter(n), getValue(), inject counter(n) and reply n to getValue()
          cjReact2(counter, int, n, getValue, empty_int, dummy,
          { counter(n), cjReply(getValue, n); } );
    );
    counter(0), inc(), inc();
    [CJoin cycleMainLoopForSeconds:0.2];	// allow enough time for reactions to run
    
    int v = getValue(); // getValue returns 2

CocoaJoin modifies the model of join calculus in some inessential ways:

* Only a subset of primitive types are supported for molecule values: `empty`, `int`, `float`, `id.` Similarly, the return values of fast molecules can have only these types. Here `empty` is the functionally same as NSNull.
* Molecule names are local values of certain predefined types such as `CjM_int`, `CjM_empty`, `CjM_id_id`, etc., depending on the types of values. (Fully constructed molecules are not directly available as objects, as in JoCaml.)

Available types:

	CjM_empty -- name of a slow molecule with empty value, such as inc()
	CjM_id -- name of a slow molecule with id value, such as s(@"a")
	CjM_int -- name of a slow molecule with int value
	CjM_float -- name of a slow molecule with float value
	CjM_empty_int -- name of a fast molecule with empty value, returning int

Other types of this form: `CjM_`_t_`_`_r_  represents a name of a fast molecule carrying value of type _t_ returning a value of type _r_. In ordinary join calculus, this type would be a function _t_ -> _r_.

* The syntax of molecule injection is simply `a(x)` or `b()`. (These function calls return `void` and inject the molecule. A fully constructed molecule is not available as a separate object.)
* The syntax of `reply` is `cjReply(name, value)`, where `name` must be the name of a fast molecule. (Otherwise there will be a compile-time error, since the `reply` method is only defined for fast molecules.)
* It is not possible (due to limitations of the CPP macro processor) to make two join definitions one after another in the same local scope. Separate them with `{ ... }` or define them within different function/method scopes.
* To make a new join definition, each new molecule name must be defined with its explicit type. If you do not define some of the new input molecules, or if you define a new input molecule but do not use it in the input, there will be a compiler error (undefined variable, or unused variable).

We need to list explicitly all the newly declared input molecule names, because otherwise we cannot generate code for defining them. (The macro processor is unable to process arrays of parameters or keep track of which names were used in a list of parameters.)

* Defining a reaction with an input name that has already been defined in the same local scope is impossible (it may result in a compiler error due to name clash).

This is so because the definition of an input molecule name, e.g. `counter` with integer value, is equivalent in Objective-C to the declaration of a new local variable,

	  CjM_int counter = ...

If the name `counter` is already locally defined, it is a compile-time error to define the same name again in the same scope. No error will result if the name is redefined within another local scope.

* A join definition is represented by an object of class `CJoin` (the "join object").

The join object is not visible directly, and should not be manipulated by the programmer. (It is not possible to hide it entirely, without making the Objective-C syntax of join calculus extremely verbose.) After performing a join definition, the join object initializes its job queue and is ready to accept any injected molecules known to it, i.e. any of its input molecules. When the join object is destroyed, it also destroys the queue it has created.

Each molecule name carries a strong reference to the join object to which it belongs, and there are no other references to the join object. Once you destroy the last molecule name that uses the join object, the join is gone.

Together with the join object, the molecule names are created in the local scope, and their reactions have been defined and stored in the join object.

* A reaction may be designated for the "UI thread".

By default, all computations run asynchronously on a background thread, but updating UI on the iOS platform requires to call certain methods on the "UI thread" (or "main thread"). 

For this reason, a special feature is added to join calculus: the user can designate some reactions to run on the "UI thread". In addition, the user can specify that some join definitions to run on the "UI thread". 

* A join definition may be designated for the "UI thread".

Each join definition runs concurrently in order to schedule its reactions independently of other join definitions. The user can specify that the UI thread should be used for the code that decides which reactions can be started, i.e. for the "decision" code of the join definition. By default, this decision code will be executed on a background thread, which may cause additional delay if the molecules are injected from the UI thread and an immediate synchronous reaction is desired (as could be the case for UI-intensive computations). In this case, both the reaction and decision code for the join definition can be designated for the UI thread.

Note that join calculus intentionally restricts the tasks that the decision code for join definitions needs to perform. The decision code only needs to check which molecules are present and which reactions can be scheduled to start. (In join calculus, reactions start whenever the input molecules are present, regardless of the molecule values.) So, the decision code does not check the values of any molecules and does not call any user-defined functions. In the worst case (many molecules are present and all possible reactions can be started), the decision code will run in time linear in the total number of _locally defined_ molecules and reactions. (Each join definition decides only local reactions, not all reactions defined anywhere in the program!) For this reason, it is often acceptable to designate some join definitions for the UI thread, especially if the number of local reactions is small for these join definitions.

* Weak typing

When the user defines a molecule name with some type such as `int`, the compiler will check that the name is used with values of the correct type. So, after defining `cjAsync(counter, int)` it will be an error to inject this molecule as `counter(@"x")`. However, this error becomes merely a warning with the type `id` since that type is compatible with any other object type.

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

- fast molecule with value of type `t_in`, returning value of type `t_out`

`cjSync(t_out, name, t_in)`

- for molecules that carry no value, special macros are used:

`cjAsyncEmpty(name)`

`cjSyncEmpty(t_out, name)`

For "fast" molecules that return no value, use the `empty` type, e.g. `cjSync(empty, f, int)`. These molecules will be declared as blocks returning an `empty` value (in Objective-C, this is `NSNull *null`).

Define a new reaction:

- reactions taking a single input molecule:

		cjReact1(name1, type1, var1, code...)
		cjReact1UI(name1, type1, var1, code...)

`name1` must be a newly defined molecule name (value will be created in local scope).
`type1` is the type of the value of that molecule. For fast molecules, separate type with underscore: for example, `empty_int` or `id_id`.
`var1` is the name of the formal parameter bound to the value of that molecule within the reaction body.
`code` is the body of the reaction; this may use the locally defined names `name1` and `var1`.

Note: for molecules that carry no values, the type `empty` is used here.

- reactions taking two input molecules:

		cjReact2(name1, type1, var1, name2, type2, var2, code...)
		cjReact2UI(name1, type1, var1, name2, type2, var2, code...)

Similar macros `cjReact3`, `cjReact3UI`, `cjReact4`, and `cjReact4UI` are available. Further such macros are straightforward to implement. (See `CJoin.h`.)

The "UI" versions of the macros define reactions that are designated for the UI thread.

Here is an example of using the reaction macros.  To convert the pseudocode such as

	consume a(x) & b(y) & c() => do_computations(x,y); inject a(x+y), c()

into a macro call, we need to specify the names of the input molecules (`a`, `b`, `c`), the types of their arguments (`int`, `int`, `empty`), and the names of the formal parameters (`x`, `y`, `dummy`), and finally we need to write the function code for the reaction. Since there are three input molecules, we use the macro `cjReact3`:

	cjReact3(a, int, x, b, int, y, c, empty, dummy,
	{   do_computations(x,y); a(x+y), c();  }
	)

Here we have put the reaction body into its own block for visual clarity, but this is not necessary. Also, it is optional whether to inject the molecules with the comma operator or through separate statements `a(x+y); c();`. The reaction block always returns nothing.

Note also that we have used the name `dummy` for the argument of the empty type. This is necessary for technical reasons (the CPP macros are insufficiently powerful here). We are required to specify names for all arguments, even if the value is empty. So the reaction body will see a local variable named `dummy` with value equal to `[NSNull null]`.

The `reply` operator:
- reply with value `val` to a fast molecule named `name`

`cjReply(name, val)`

The `reply` operator, as well as injections of known molecules, can be used anywhere in the reaction block.

Current status of CocoaJoin
---------------------------

The CocoaJoin library was tested on a few examples shown above. In addition, the "dining philosophers" problem is implemented with a spartan GUI for 5 philosophers.

Roadmap for the future:

* Define special global methods for controlling the "chemical machine" as a whole, or for controlling specific local join definitions.

Possible functions: stats (get statistics on the number of molecules and reactions), pause (do not schedule any new reactions), resume (start scheduling reactions again), clear (remove all present molecules in all reactions, stop all reactions, reply immediately to all fast molecules, and ignore requests to inject any new molecules).

These global operations, as well as the corresponding local operations, can be implemented most easily via special predefined fast molecules that already have predefined reactions.

* Start a "chemical library" encapsulating useful reactions and functions.

* Document the internals of CocoaJoin, trying to be language-agnostic, since this kind of "dynamic" implementation might be quite useful and simple to do in other languages.

* Refactor the API so that the types for molecules are introspected, and the reaction block receives correct arguments via currying and helper blocks. (Not sure if this will even work in Objective-C but worth investigating.)
