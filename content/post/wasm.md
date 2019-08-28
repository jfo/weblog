---
title: wasm again
draft: true
---

Strap in I guess time for more about WebAssembly.

[Last time](#waht) I started from the binary format and made a couple of really
simple modules that don't do anything, but a WebAssembly module can be made
from a number of very specific sections. There are only 10 of them; in this
post I'll start from nothing and end with a wasm module that has a tiny version
of each type of possible section. All of this is culled from the [normative
docs](https://webassembly.github.io/spec/core/syntax/modules.html#), which are
thorough and complete but is sometimes hard to read without context.

This is how the rest of this series of posts is going to go... a bunch of
iterative examples building up to a small wat program that does some useless
stuff but uses all of the possible sections that can appear in a webassembly
program. I won't be exhaustively listing all the instructions or every single
thing that can go in any place in the file, as you are free to pore over the
[ur-spec]() for that, as I have attempted to do. Hopefully by the end, we'll
both have a better idea of how a wasm module is or can be structured, and why.
Doing useful things with that comes later, but stick with me, and maybe we'll
get there.

> list types of sections

I'll do all of this in WAT. The `web assembly text` format.

> you'll probably need the toolchain and here's a script to run to compile and
> run it in the browser or whatever.

I ended the last time with this program:

```
(module
  (global (;0;) i32 (i32.const 42))
  (export "x" (global 0)))
```

so the first two sections, globals and exports, have already been covered. Let's move on!


Functions
-------

Here is an empty function.

```
(module
  (func)
  (global (;0;) i32 (i32.const 42))
  (export "x" (global 0)))
```

You can declare a function signature type, and return a constant of that type.
With no return type specified, the return type is default "`null`", or
"`undefined`", or something falsy, right? notice the air quotes... wasm doesn't
really have those types, what it _has_ got is an "empty stack".

Let's say I try to assemble this:

```
(module
  (func i32.const 123))
```

I'll get this error:

```
test.wat:2:9: error: type mismatch in function, expected [] but got [i32]
  (func i32.const 123))
        ^^^^^^^^^
```

This tracks, the function doesn't so much "return" as it does "leave its stack
in a state compatible with the stated expected result". This may seem hair splitting,
and it is of course, but I think it's valuable to draw subtle distinctions
between the way we usually think about functions in a higher level language and
how we think about them in a stack machine environment. More on that later.

Moving on, I can return a constant value:

```
(module
  (func (result i32)
    i32.const 123)
  (global (;0;) i32 (i32.const 42))
  (export "x" (global 0)))
```

Perhaps instead of a constant value, you can return the global value declared
previously. It's available to you here:

```
(module
  (func (result i32)
    global.get 0)
  (global (;0;) i32 (i32.const 42))
  (export "x" (global 0)))
```

Now is a good time to mention you can assign an alias to a global value and
refer to it that way.

```
(module
  (func (result i32)
    global.get $theMeaningOfLife)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "x" (global $theMeaningOfLife)))
```
Also it doesn't matter what order these modules are declared in:

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func (result i32)
    global.get $theMeaningOfLife)
  (export "x" (global $theMeaningOfLife)))
```

> You may also see `get_global`, I think that's an old way to do that. TODO: find why

Maybe we give it a parameter?

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func (param i32) (result i32)
    global.get $theMeaningOfLife)
  (export "x" (global $theMeaningOfLife)))
```

You can also assign a name to parameters instead of referring to them by their index.

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func (param $n i32) (result i32)
    global.get $theMeaningOfLife)
  (export "x" (global $theMeaningOfLife)))
```

Here's a good place to talk about what a stack machine is; really this is
the business end of wasm computation. I won't enumerate all the instructions,
of course, but this is where most of them go. A stack machine is a pretty
simple model of computation, things get loaded into a FILO stack (first in,
last out), and when instructions are applied to them, they pull out the number
of arguments they need.

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func (param $n i32) (result i32)
    get_local $n
    get_global $theMeaningOfLife
    i32.add)
  (export "x" (global $theMeaningOfLife)))
```

The body of this function has three lines, after this line:

```
get_local $n
```

the stack looks like this (let's pretend we called this function in javascript with `10`):

```
[10]
```

Then after this line:

```
get_global $theMeaningOfLife
```

```
[42, 10]
```

Now,

```
i32.add
```

pops two values off the stack and pushes the result of the operation onto the
stack, so in the end, it looks like this

```
[52]
```

The function then "returns" this value by leaving it in the stack. If the stack
doesn't match the result type, you'll get an error.

Of course, we may like to export the function the same way we exported the global:

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func (param $n i32) (result i32)
    get_local $n
    get_global $theMeaningOfLife
    i32.add)
  (export "x" (global $theMeaningOfLife))
  (export "aFunction" (func 0)))
```

And we can name it as well.

```
(module
  (global $theMeaningOfLife i32 (i32.const 42))
  (func $aFunction (param $n i32) (result i32)
    get_local $n
    get_global $theMeaningOfLife
    i32.add)
  (export "x" (global $theMeaningOfLife))
  (export "aFunction" (func $aFunction)))
```

> maybe a useful note: these alias names are thrown away on assembly, if we run
> `wasm2wat` on the output of `wat2wasm`, we get
```
(module
  (global (;0;) i32 (i32.const 42))
  (type (;0;) (func (param i32) (result i32)))
  (func (;0;) (type 0) (param i32) (result i32)
    local.get 0
    global.get 0
    i32.add)
  (export "x" (global 0))
  (export "aFunction" (func 0)))
```
>


types
-------

The type section defines function signatures that can be referenced in the
function declarations. Unfortunately it seems like the local variable name
doesn't propogate to the function scope, but the types themselves accept an
alias.

```
(module
  (type $ourFriend (func (param i32) (result i32)))
  (func $aFunction (type $ourFriend)
    get_local 0
    get_global $theMeaningOfLife
    i32.add)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "x" (global $theMeaningOfLife))
  (export "aFunction" (func 0)))
```

It should be noted that the current spec only allows results of a single value,
meaning you can't return a vector of more than one value. So this, which looks
like it could or should be valid and would leave the stack in the state `[2, 1]`,

```
(module
  (func (result i32 i32)
        i32.const 1
        i32.const 2))
```

Will error on assembly:

```
test.wat:2:4: error: multiple result values not currently supported.
  (func (result i32 i32)
   ^^^^
```

I take this to mean that it is likely to be supported in the future, if I had
to bet.


