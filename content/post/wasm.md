---
title: wasm again
draft: true
---

Strap in I guess time for more about WebAssembly.

[Last time]() I started from the binary format and made a couple of really
simple modules that don't do anything, but a WebAssembly module can be made
from a number of very specific sections. There are only 10 of them; in this
post I'll start from nothing and end with a wasm module that has a tiny version
of each type of possible section. All of this is culled from the [normative
docs](https://webassembly.github.io/spec/core/syntax/modules.html#), which are
thorough and complete but is sometimes hard to read without context.

> list types of sections

I'll do all of this in WAT. The `web assembly text` format.

> you'll probably need the toolchain and here's a script to run to compile and
> run it in the browser or whatever.

I ended the last time with this program:

```wat
(module
  (global (;0;) i32 (i32.const 42))
  (export "x" (global 0)))
```

so already covered to first two sections: globals and exports.

Functions
-------

Here is an empty function

```
(module
  (func)
  (global (;0;) i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

You can declare a result type, and return a constant of that type.

```
(module
  (func (result i32)
    i32.const 123)
  (global (;0;) i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

Perhaps instead of a constant value, you can return a global value declared previously.

```
(module
  (func (result i32)
    get_global 0)
  (global (;0;) i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

Now is a good time to mention you can assign an alias to a global value and
refer to it that way.

```
(module
  (func (result i32)
    get_global $theMeaningOfLife)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

Maybe we give it a parameter?

```
(module
  (func (param i32) (result i32)
    get_global $theMeaningOfLife)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

You can also assign a name to parameters instead of referring to them by their index.

```
(module
  (func (param $theNumberTen i32) (result i32)
    get_local $theNumberTen
    get_global $theMeaningOfLife
    i32.add)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

Oh no. I am calling this on the javascript side like `aFunction()`, and it
looks like I am just passing 0. Javascript is leaking; oh well.

It does what you would expect otherwise though. 


Here's a good place to talk about what a stack machine is, but really this is
the business bits of wasm computation. I won't enumerate all the instructions,
but this is where most of them go.

```
(module
  (func (param $theNumberTen i32) (result i32)
    get_local $theNumberTen
    get_global $theMeaningOfLife
    i32.add)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

types
-------

The type section defines function signatures that can be referenced in the
function declarations. Unfortunately it seems like the local variable name
doesn't translate, but the types themselve accept an alias.

```
(module
  (type $ourFriend (func (param i32) (result i32)))
  (func (type $ourFriend)
    get_local 0
    get_global $theMeaningOfLife
    i32.add)
  (global $theMeaningOfLife i32 (i32.const 42))
  (export "aFunction" (func 0)))
```

tables
-------
https://hacks.mozilla.org/2017/07/webassembly-table-imports-what-are-they/

mems
-------
elem
-------
data
-------
imports
-------

start
-------
