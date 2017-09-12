---
title: Fuckin' monads, how do they work?
description: and I don't wanna talk to a category theorist
draft: true
---

I have recently come into possession of a reasonably sound understanding of
monads. Tradition dictates that I now have an obligation to write a shitty blog
post tutorial about them, wherein I attempt to gracefully share this knowledge
through the judicious use of carefully chosen metaphors and examples.  Legend
has it that [I will inevitably
fail](https://byorgey.wordpress.com/2009/01/12/abstraction-intuition-and-the-monad-tutorial-fallacy/)
in this, and then be raked over the coals for my sins by category theorists and
haskellers alike. This isn't very appealing to me, but who am I to challenge
fate?

<hr>

I wouldn't call this a tutorial, though it feels like it. It kind of is one,
but I prefer the term development log. I assume no real authority, I'm just
trying to clearly explain something I've just learned about. Monads are
particularly prickly, for a variety of reasons, but something that came up over
and over again in my research was the necessity of "developing an intuition" about them.

To that end, I've included a lot of links at the end of this post and I
encourage you to read a lot of them if you are interested. Reading a lot of
different takes on the subject can help to develop that intuition in a way that
no single tutorial or log could ever do. 

<hr>

Monads have a reputation. Why?

1. The term is [imprecise](https://en.wikipedia.org/wiki/Monad) across
   disciplines, and even many professed experts
   [disagree](https://en.wikipedia.org/wiki/Talk:Monad_(functional_programming)/Archive_1)
   on what constitutes a reasonable approach to explaining them in a programming
   context.

2. ...despite this, the term _is_ precise within [category
   theory](https://en.wikipedia.org/wiki/Monad_(category_theory)), which is a
   fascinating but also advanced and abstract branch of mathematics.

3. ...and the term is _also_ precise [within
   Haskell](https://wiki.haskell.org/Monad), which is a fascinating but advanced and
   abstract programming language.

Though I appreciate that a _complete_ comprehension of monads and their
theoretical underpinnings may very well be predicated on becoming intimate with
category theory, I completely reject the assertion that a even a rudimentary and
useful understanding of monads and their applications _must_ be preceded by that
study.

I'm not alone in this. [Philip
Wadler](https://en.wikipedia.org/wiki/Philip_Wadler), in one of the [_very first
papers_](https://page.mi.fu-berlin.de/scravy/realworldhaskell/materialien/the-essence-of-functional-programming.pdf)
ever written describing the practical uses of monads in functional programs,
said as much:

> The concept of a monad comes from category theory, but this paper assumes no
> prior knowledge of such arcana. Rather, it is intended as a gentle introduction,
> with an emphasis on why abstruse theory may be of interest to computing
> scientists.

...pretty salty for academe, tbqh.

[Here's Brian Beckman fullthroatedly making a similar
point.](https://www.youtube.com/watch?v=ZhuHCtR3xq8&feature=youtu.be&t=26m20s)

> ...and that's where we go into category theory... but you _don't need_ to know
> category theory, to be fully conversant, to be _fully fluent_ in this language
> of function composition. All you have to remember is the types need to line up.

Of course, I'm not making an indictment of category theory whatsoever. It looks
absolutely fascinating! I'm just saying it's not a _prerequisite_ to developing
an understanding and intuition of what monads are and do. Beckman goes on...

> If you're going to nest function calls, the types have to line up. There's
> nothing complicated about this you don't need to know category theory to... I mean
> if you _want_ to learn category theory to understand the full, flowering glory
> of the consequences of this astonishing... you can and by all means, it will
> only increase your richness, but you can now speak French in the world of monoidal
> categories because you understand, that as long as the types line up, then
> **compositionality makes sense**.

<hr>

A monad is _three things_ that, working together, satisfy _three
rules_, and that is what makes them, in aggregate, a monad.

The three things are:

a type of thing,
-------------

The structure doesn't matter. What matters it that it's a functor. A functor is
a thing that can be fmapped. fmap means functor map, and it's a function that
_knows how to access values inside the functor_.

Let's see, in Ruby, an `Array` is a functor, and `Array#map` is an fmap.

```ruby
x = [1,2,3]
print x.map {|e| e + 1}
```
```
[2, 3, 4]
```

`map` knows how to get at those values inside the functor and operate on them,
returning a new functor of the same type. This is similar but not exactly like
how a monad works.

Look, here's one:

```ruby
class MyFunctor
    def initialize(val)
        @val = val
    end
    def map
        MyFunctor.new(yield(@val))
    end
end

p MyFunctor.new(1).map {|e| e + 1}
```

```
#<MyFunctor:0x007f8ca31fe0c8 @val=2>
```


and `unit()`
-------------

`unit` takes a value and returns a _new_ something of a type that incorporates
that initial value.  It's _almost_ just a constructor. In the example above
it's just like the `Array` literal `[]`, it could also be `Array.new`.

In javascript, I could use the `new` keyword for this. As evidenced by the
`MyFunctor` class above: _It does not matter what the structure of the returned
object is, only that is is `fmap`-able._

```js
const Thing = function(x) {
    return {
        value: x
    };
}
```

and for now, `unit` is simply a wrapper around this constructor, for
illustration purposes.

```js
const unit = function(x) {
    return new Thing(x);
}
```

I will use only the `unit` function below, and it always means `new Thing()`.

`bind()`
--------

> !IMPORTANT _This is not javascript's bind function!_

Vanilla javascript doesn't have any typing to help here. I'm going to use
a little Typescript instead.


```js
const addOne = function(x: number) {
    return x + 1;
}
```

Now, what if I want to add one to a `Thing`...

```js
let mx = unit(1);
addOne(mx);
```

`mx` is a `Thing`, and `addOne` expects and `number`, so I get this compilation
error:

```
../monad.ts (15,12): Argument of type 'Thing' is not assignable to parameter of type 'number'. (2345)
```

> In vanilla javascript, this _does work_. What it returns is much worse than
> useless, though.
>
```
[object Object]1
```
>
> It casts my `Thing` to a string by calling `Thing.prototype.toString()`,
> which returned `"[object Object]"`, then it "added" "1" to it by concatenating the
> string `"1"` onto the end. Typescript catches this error.

What I really wanted is a function `addOneToThing` that can add one to the
`value` of a `Thing`.

```js
const addOneToThing = function(mx: Thing) : Thing {
    return new Thing(mx.value + 1);
}
```

This function takes a `Thing` and returns a `Thing`. And it does what I would
expect it to.

```js
let mx = unit(1);
addOneToThing(mx);
```

```
{ value: 2 }
```

`addOneToThing` _knows_ about `Thing`s. It knows how to get a value out of a
thing and it knows how to make a new one.

`bind` is a function that knows how to _apply a function to an underlying type
contained inside of another type._ This is the "knowing how to break apart"
part.

For this example, the underlying type is a `number`, and the another type is a
`Thing`.

```js
const bind = function(fn: Function, mx: Thing) {
    return fn(mx.value);
}
```

`bind` knows about `.value`, so `addOne` doesn't have to be `addOneToThing`
anymore. I can just use `bind`!

What do I get, then, if I _bind_ `addOne` to a `Thing`?

```js
bind(addOne, unit(1));
```

I get:

```
2
```

This works, but I am left with a `Number` instead of a `Thing`. Any function
that is bound in this fashion must accept a _bare (underlying) value and
_return a new `Thing`_.

I'll redefine `addOne` then, to do so, and add a `timesTwo` function to help
with the next example. The function signitures below amount to `x -> Mx` where
`M` is a `Thing(Number)` and `x` is a `Number`.


```js
const addOne = (x: number) : Thing => unit(x + 1)
const timesTwo = (x: number) : Thing => unit(x * 2);
```

Now, if I

```typescript
bind(addOne, unit(1))
```
I get...

```
Thing { value: 2 }
```

`bind` knows how to apply these functions... and you may have noticed something
_potentially useful._ Now that I'm returning a `Thing`, I can call `bind`
directly on the return value!

```typescript
bind(timesTwo, bind(addOne, unit(1)))
```

yields:

```
Thing { value: 4 }
```

Interesting...

So, this is all that is needed to satisfy:

the three laws
==============

Described in terms of the preceding functions, `addOne` could be any function at
all with the type signiture `x -> Mx` (where in this example, Mx is a `Thing`).

left identity
--------------

```js
bind(addOne, unit(1)) == addone(1);
```

right identity
--------------

```js
bind(unit, unit(1)) == unit(1);
```

associativity
--------------

```js
const compose = function(g, f) {
    return function(mx) {
        bind(f, bind(g, mx));
    }
}

bind(addOne, compose(timesTwo, addOne)(mx)) == compose(addOne, addOne)(bind(timesTwo, mx))
```

Look carefully at this last one, it is confusing, but ultimately
straightforward. `compose` takes 2 functions and returns a _new function_ that
composes them together. `compose(f,g)` then, returns a function that takes an input
`mx`, `bind`s `g` to it, and then `binds` `f` to _that_. The result is a
function that essentially calls g, then f. In the example above, we're saying
that calling `compose(timesTwo, addOne)` and then `addOne` is equivalent to
calling `timesTwo` and then `compose(addOne, addOne)`.

> [I briefly confused associativity with commutativity.](http://lambda-the-ultimate.org/node/2448)
> Don't be like me, stay in school.

Here's an addendum. All functions that can be bound like this must have the type
signature `x -> Mx`, right? So, that original `addOne` function that had the
type signature `x -> x` where `x` was `Number` doesn't qualify. But, it's
trivial to create a helper that will wrap that original `addOne` in a `unit`
function, thus fulfilling that contract. This is very useful, and it's usually
called `lift()`

```js
const lift = function(fn) {
    return function(x) {
        return unit(fn(x));
    }
}
```

Now,

```js
const addOne = (x: number) => x + 1
bind(lift(addOne), unit(1))
```

will return:

```
Thing { value: 2 }
```


but... _why_
----------

The usefulness of this construct is probably not readily apparent, but in
actual fact this is very powerful and can be used for many things, especially
in a purely functional context!

There aren't that many _truly_ purely functional languages, Haskell is the big
one, of course, and much of _its_ reputation comes from the constraints writing
in a purely functional way impose.

Last year, I wrote a completely pure, 100% pass by value functional lisp called
[Sild](/sild-is-a-lisp-dialect). There is not much to recommend it,
really... it can't really do that much at all. There are no types, not even
_numbers_, just labels and lists. There is no mutable state, there are no
`let`s or `do`s either.

It's only quote, car, cdr, cons, eq, atom, cond, and lambda, really, and it has
define, but only at the top level, and it has display for printing to stdout,
and _that's all_.

Can I use monads in sild for anything useful? It turns out that I can!

I'll start by implementing the same thing from above, the `identity` monad.

```scheme
(define unit
 (lambda (x)
  (cons x '() )))
```

I have no way of creating objects other than lists,, or types of any kind at
all, in Sild, but I can make a "`Thing`" by wrapping it in a list. Remember, it
doesn't really matter what the _structure of the functor_ is, only that these
particular interfaces are satisfied.

`unit` is a function that will take something and wrap it in a list, then!

```scheme
(unit '(a b c))
```
```
((a b c))
```

`bind` needs to know how to "get at" that internal value. In this case, it's as
simple as unwrapping that outer list by using `car` and then applying the given
function to it.

```scheme
(define bind
  (lambda (f mx)
    (f (car mx))))
```

This is already a monad! I've got a _type_ of something, in this case denoted by
a doubly wrapped list. I have `unit` which takes a value and makes it into a
thing of that "type", and I have `bind`, which knows how to "unwrap" the value
and apply a function to it!

Remember that the function it applies must have the type signature `x -> Mx`.
We don't have a type system to help here! But, any function I pass in needs to
take some value and return it as a "`Thing`", in this case by wrapping it in a
list.

Here are three test functions that do that:

```scheme
(define push_a
  (lambda (x) (unit (cons 'a x))))
(define push_c
  (lambda (x) (unit (cons 'c x))))
(define pop
  (lambda (x) (unit (cdr x))))
```

I'll also need `compose`, of course, to test for associativity. That looks just
like the js version:

```scheme
(define compose (lambda (g f)
  (lambda (m) (bind f (bind g m)))))
```

Does this structure pass the tests? I don't have any list equality functions to
check with, but we can just look at the output!

```scheme
; this is a bare value to start with, it's just a list with a few symbols in it.
(define y '(a b c))
; and here's a monadic version of that, created with `unit`!
(define My (unit y ))

; left identity
(display (bind pop My))  ; ((b c))
(display (pop y))        ; ((b c))

; right identity
(display (bind unit My)) ; ((a b c))
(display My)             ; ((a b c))

; ; associativity
(display (bind push_c ((compose push_a pop) My))) ; ((c a b c))
(display ((compose pop push_c) (bind push_a My))) ; ((c a b c))
```

So! This and the javascript examples so far are in fact _identity monads_. They
fulfill all the criteria that a monad needs to fulfill, but don't do anything _else_.


A digression Monads are _"like"_ functions
-------------------------

Monads, like functions, are an _abstraction_. Functions can be thought of in
metaphorical terms... a black box, a machine with inputs and outputs, these are
intuitive but insufficient descriptions of what a function _is_ and does.
Monads can also be thought of in metaphorical terms. A monad is a container, a
monad is a burrito, a bucket, or a package... more abstractly (and accurately,
but not completely) as a sort of composition of functions on types... likewise,
these metaphors can _be_ intuitively correct but insufficient.

Monads are not the structure of type `Thing`, for example, and `Thing` alone,
though acting as a container, is _not_ a monad.  `Thing` _plus_ the `unit` and
`bind` procedures made available to work with and around it _together_ make up
the monad.

But, what does this make _possible_? Well, what do _functions_ make possible,
exactly? Does that question even really make _sense_? Is it specific enough to
have any answer besides "a lot of things"?

It doesn't really matter how you architect these procedures and types, what
matters is the availability of these rudimentary operations and their ability to
pass those three tests: left identity, right identity, and associativity. That is _all_
that matters in terms of defining a monad. To prove this, here's another
Identity monad implemented in a more object oriented way, This time using PHP.

First, I'll define an interface that any monadic class will need to implement.

```php
<?
interface Monad {
    public static function unit($x);
    public function bind(callable $fn);
}
```

Now, I'll make one! The same one, actually, that identity monad.

```php
<?

class IdentityMonad implements Monad {

    private $value;

    private function __construct($n) {
        $this->value = $n;
    }

    public static function unit($x) {
        return new ID($x);
    }

    public function bind(callable $fn) {
        return $fn($this->value);
    }

    public function compose(callable $g, callable $f) {
        return $g($this->value)->bind($f);
    }
}
```

Here are two functions that I can pass to `bind`.

```php
<?

$increment = function($n) { return ID::unit($n + 1); };
$times2    = function($n) { return ID::unit($n * 2); };
```

Does this pass those tests?

```php
<?

# left identity
ID::unit(1)->bind($increment) == $increment(1)

# right identity
ID::unit(1)->bind("ID::unit") == ID::unit(1)

# associativity identity
ID::unit(1)->compose($increment, $times2)->bind($increment) ==
ID::unit(1)->bind($increment)->compose($times2, $increment);

```

All of these are:

```
bool(true)
```

Notice something important, here... those `bind`s are _not returning self_.
There's no mutation happening to the original object, it's a completely new
`ID`, each and every time. I'm not going to say that's the most efficient
pattern in terms of memory use, but languages designed for purely functional
calculations employ techniques to mitigate and [abstract this
away](http://okasaki.blogspot.dk/2008/02/ten-years-of-purely-functional-data.html)


Back to sild, something useful...
-----------

How can I keep track of all the functions I've run on an object? In a stateful
language, this is pretty easy. Here's one way to do so in some Ruby:

```ruby
class Whatever
    attr_reader :history, :value

    def initialize
        @history = []
        @value = 0
    end

    def inc
        @history << 'inc'
        @value += 1
        self
    end

    def dec
        @history << 'dec'
        @value -= 1
        self
    end
end

x = Whatever.new
x.inc.inc.dec.inc.inc.inc.dec.dec.dec

puts x.value # 1
puts x.history.join(", ") # inc, inc, dec, inc, inc, inc, dec, dec, dec
```

...for example. I'm sure that could be metaprogrammed and monkeypatched into
Object if you wanted to debug _everything_ run on _everything_.

But, how could I _possibly_ do this in a pure language, with no mutability, and
no side effects? It can be done!

I'm going to implement a [writer
monad](http://adit.io/posts/2013-06-10-three-useful-monads.html#the-writer-monad)
that will let me keep a log of all the functions I've run, in Sild.

First, I'll define some aliases I like to use:

```scheme
(define def define)
(def λ lambda)
```

Sild is not especially smart, but you _can_ use arbitrary unicode like `λ` and
redefine basic language keywords, which is nice.

I'll also define a few old fashioned lisp functions.

```scheme
(def cadr (λ (l) (car (cdr l))))
(def caadr (λ (l) (car (car (cdr l)))))
```

I'll also need a couple of utility functions...

```scheme
(def revinner
 (λ (l acc)
  (cond l (revinner (cdr l) (cons (car l) acc))
        acc)))
(def reverse (λ (l) (revinner l '())))
```

`reverse` will reverse a list.

```scheme
(def unshift
  (λ (el l)
    (reverse (cons el (reverse l)))))
```

`unshift` will "push" something on to the _end_ of a list. It's the opposite of
`cons`.  [Here read this!](http://www.perlmonks.org/?node_id=613124)

Ok, with these useful extras out of the way, let's get to the meat of things.

Here's the unit function. This monad will have the form:

```
(() ())
```

...that is to say, it must be a list with two lists inside of it.
The first will be the value, the second will be the record (history) of all the
procedures that were bound to the monad. `unit` then will take a value (a
list), and 'wrap' it into a monad with a blank history.

```scheme
(def unit
  (λ (x)
    (cons x '(()))))
```

I'll have a constructor, that simple takes two lists and wraps them up.

```scheme
(def constructor
  (λ (val hist)
    (cons val (cons hist '()))))
```

And I'll define a few aliases to make it clearer what I'm doing to `Thing`s

```scheme
; some aliases to make usage clearer when applied to monads.
(def get-val car)
(def get-hist cadr)
(def get-most-recent-hist caadr)
```

Here's a function that writes a new element to a history and returns a new
Thing with that new history, leaving the value unchanged.

```scheme
; takes a symbol `sym` and a monad `Mx` and writes the symbol onto the end of
; the monad's history
(def write-to-hist
  (λ (sym Mx)
    (constructor (get-val Mx)
            (unshift sym (get-hist Mx)))))
```

Next, I'll need this function that takes two `Thing`s an old one and a new one.
It merges the histories, and returns a new `Thing` with the new value and the
merged histories.

```scheme
; takes two monads, an old one and a new one. Combines the new's value with the
; old's history while appending the new's most recent history entry.
(def combine-hist
  (λ (m-old m-new)
; if both histories are equal, it's empty. We don't need to merge anything,
; just return the new one:
    (cond (eq (get-hist m-old) (get-hist m-new)) m-new ; otherwise, write the
; most recent history entry from the new to the old and return a new monad
; made of the value of the new and the merged histories
              (m-make
                (get-val m-new)
                (get-hist (write-to-hist (get-most-recent-hist m-new)
                                         m-old))))))
```

It's our friend, bind! in this case, we apply the function with signature `a ->
Mb` to the extracted value, and combine histories, and we're done!

```
(def bind
  (λ (f Mx)
    (combine-hist Mx
                  (f (get-val Mx)))))
```
Now, we'll also need some functions of the form `x -> Mx`.

```scheme
; takes a datum to push into something and a name for the function to be
; recorded into history as and returns a function that pushes into a value and
; returns a monad
(def makepusher
  (λ (datum name)
    (λ (l) (write-to-hist name (unit (cons datum l))))))

(def push-a (makepusher 'a 'push-a))
(def push-b (makepusher 'b 'push-b))
(def push-c (makepusher 'c 'push-c))
; this will break if the monad's value list is empty! caveat lisper
(def pop    (λ (l) (write-to-hist 'pop (unit (cdr l)))))
```

And finally, compose, which looks and acts just like the js example.


```scheme
(def compose
  (λ (g f)
    (λ (m) (bind f (bind g m)))))
```

With all of this out of the way, what do we get? Does this pass those three tests?

```scheme
; an initial value state to play with
(def y '(a b c))
; an initial monad with that initial value state to play with
(def My (unit y))

; left identity
(display (bind pop My))  ; ((b c) (pop))
(display (pop y))        ; ((b c) (pop))

; right identity
(display My)             ; ((a b c) ())
(display (bind unit My)) ; ((a b c) ())

; associativity
(display (bind push-c ((compose push-a pop) My))) ; ((c a b c) (push-a pop push-c))
(display ((compose pop push-c) (bind push-a My))) ; ((c a b c) (push-a pop push-c))
```

Indeed it does. This is a monad! And look here,

```scheme
(display (bind push-c
          (bind pop
           (bind pop
            (bind push-a
             (bind push-b
              (bind push-c
               (bind pop
                (bind pop My)))))))))
; ((c c c) (pop pop push-c push-b push-a pop pop push-c))
```

This monad has a memory, a history of everything that's been bound to it!


Appendix
------------

Here are a bunch of things I read to do this. I'm going to pare them down, put
them in some kind of sensible order, and link with descriptions.

- https://wiki.haskell.org/Typeclassopedia
- http://vaibhavsagar.com/blog/2016/10/12/monad-anti-tutorial/
- https://karma-engineering.com/lab/wiki/Monads2
- http://goodmath.scientopia.org/2012/08/19/monads-and-programming/
- https://miklos-martin.github.io/learn/fp/2016/03/10/monad-laws-for-regular-developers.html
- http://lambda-the-ultimate.org/node/2448
- https://web.archive.org/web/20050204001716/http://www.nomaware.com/monads/html/index.html
- http://www.ccs.neu.edu/home/dherman/browse/shared/notes/monads/monads-for-schemers.txt
- http://learnyouahaskell.com/functors-applicative-functors-and-monoids
- http://learnyouahaskell.com/making-our-own-types-and-typeclasses#the-functor-typeclass
- https://wiki.haskell.org/Monad_laws
- http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html
- https://stackoverflow.com/questions/3433608/explanation-of-monad-laws
- https://curiosity-driven.org/monads-in-javascript
- https://medium.com/@dtinth/what-is-a-functor-dcf510b098b6
- http://learnyouahaskell.com/a-fistful-of-monads
- https://medium.com/@tzehsiang/javascript-functor-applicative-monads-in-pictures-b567c6415221
- http://slides.com/julientournay/a-monad-is-just-a-monoid-in-the-category-of-endofunctors-what-s-the-problem/#/
- https://ericlippert.com/2013/02/21/monads-part-one/#more-461
- http://etymon.blogspot.dk/2006/09/monad-laws.html
- http://blog.ssanj.net/posts/2017-06-07-composing-monadic-functions-with-kleisli-arrows.html
- https://jrsinclair.com/articles/2016/marvellously-mysterious-javascript-maybe-monad/
- http://blog.klipse.tech/javascript/2016/08/31/monads-javascript.html
- https://blog.jcoglan.com/2011/03/05/translation-from-haskell-to-javascript-of-selected-portions-of-the-best-introduction-to-monads-ive-ever-read/
- https://byorgey.wordpress.com/2009/01/12/abstraction-intuition-and-the-monad-tutorial-fallacy/
- https://two-wrongs.com/the-what-are-monads-fallacy
- http://www.lispcast.com/monads-and-objects
- http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.79.733&rep=rep1&type=pdf
- https://www.youtube.com/watch?v=ZhuHCtR3xq8&feature=youtu.be&t=26m20s
