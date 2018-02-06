---
title: How Zig do?
draft: true
scripts: ["zighl.js"]
---

Hello, good morning or whatever! Let's write a brainfuck interpreter. "Why
would one do such a thing?" I hear you asking. You won't find that answer here.

> Actually, I was reading some of my old blog posts and I came across
> [this](/fizzbuzz-in-brainfuck-part-3/#never-going-to-happen).

The time is now! Let's do it in [Zig](http://ziglang.org/).

Zig is....
--------

new, still very much in beta, and moving quickly. `master` has already
changed a lot since the [`0.1.1`](http://ziglang.org/download/) release a few
months ago, so if you notice discrepencies from zig code you might have seen
somewhere else, this is why.

This code was all tested and compiled with Zig
[`0.1.1.4d8d654`](https://github.com/zig-lang/zig/tree/44d8d654a0ba463a1d4cf34d435c8422bfcd1c81)

For more on how brainfuck works, [look
here](https://blog.jfo.click/how-brainfuck-works/).

say a thing about wrapping around the memory etc.

This is as much a small zig tutorial as anything. Zig is designed to be
readable (link), and as such it's fairly intuitive if you are familiar with
similarly compiled, (~)typed languages like C, C++, and even in some cases,
Rust.

Getting Zig
------------

Homebrew, compile from source.


Ok, here we go.
--------

Zig is a compiled language. When you compile a program, the resulting binary
(if you are building an executable binary, as opposed to a library) needs a
`main` function that denotes the entry point.

So...

```zig
// main.zig
fn main() void { }
```

...and running...

```shell
$ zig build-exe main.zig
```

...gives me...

```shell
/zig/std/special/bootstrap.zig:70:33: error: 'main' is private
/zigfuck/main.zig:2:1: note: declared here
```

`main` must be declared public in order to be visible outside of its
compilation unit...

```zig
// main.zig
pub fn main() void { }
```

A brainfuck program is supposed to use a 30,000 byte array of memory, so I'll
make one.

```zig
// main.zig
pub fn main() void {
  const mem: [30000]u8;
}
```

I can make a variable `const` or `var`. Here, I'm declaring `mem` as an array
of `30000` unsigned (`u`) bytes (`8` bits).

This does not compile.

```shell
/main.zig:3:5: error: variables must be initialized
```

Zig forces me to make this decision at the declaration site. Often, I don't
care what the memory is. I can state this intent clearly by initializing to
`undefined`.

```zig
// main.zig
pub fn main() void {
  const mem: [30000]u8 = undefined;
}
```

Initializing a variable to `undefined` offers no guarantees about the values
that may or may not be in the memory. This is just like an uninitialized
declaration in C, except it _forces me_ to explicitly state that it is
undefined.

But maybe I _do_ care what this memory is initialized to. Maybe I want to
guarantee that it is zeroed out, or start it all off at some arbitrary value or
something? In that case I must be explicit about that:

```zig
// main.zig
pub fn main() void {
  const mem = []u8{0} ** 30000;
}
```

This might look a little funny, but `**` is an operator used for array
multiplication. I'm defining an array of a single `0` byte and then multiplying
it by `30000` to get my final initialization value of an array of 30000 zeroes.
This operation happens once, at _compile time_. `comptime` is one of Zig's main
Big Ideas, and I'll come back to it later.

Now, let's write a brainfuck program that doesn't do anything!


```zig
pub fn main() void {
  const mem = []u8{0} ** 30000;
  const src = "+++++";
}
```

In Zig, strings are just byte arrays. I don't have to declare `src` as a byte
array because the compiler infers it. It is unneccesary to do so, but I am free
to be explicit about that, too:

```zig
const src: [5]u8= "+++++";
```

This will compile just fine. This, however...

```zig
const src: [6]u8= "+++++";
```

will not.

```shell
main.zig:5:22: error: expected type '[6]u8', found '[5]u8'
```

`for (the_love_of) |pete| { }`
--------------------------------

I want to do _something_ for each character in the source. I can do that!

```zig
const warn = @import("std").debug.warn;
// main.zig
pub fn main() void {
  const mem = []u8{0} ** 30000;
  const src = "+++++";

  for (src) |c| {
      warn("{}", c);
  }
}
```

During debugging and initial development and testing, I just want to print
something to the screen. Zig is [fastidious about error
handline](http://ziglang.org/documentation/master/#Hello-World) and stdout is
error prone. I don't want to mess around with that right now, so I can print
straight to stderr with `warn`, here imported from the standard library.

`warn` takes a format string, just like `printf` does! The above prints:

```
4343434343
```

43 being the ascii code for the `+` char. I can also go:

```zig
warn("{c}", c);
```

and wouldn't you know it:

```
+++++
```

So, I've initialized the memory space, and written a program. Next, I must
implement the language. Let's start with `+`! I'll replace the body of the
`for` to `switch` on the character.

```zig
for (src) |c| {
    switch(c) {
        '+' => mem[0] += 1
    }
}
```

I get two errors from this program!

```shell
/main.zig:10:7: error: switch must handle all possibilities
      switch(c) {
      ^
/main.zig:11:25: error: cannot assign to constant
          '+' => mem[0] += 1
                        ^
```

Of course, I can't assign a new value to a variable that's been declared
`const`ant! `mem` needs to be `var`...

```
var mem = []u8{0} ** 30000;
```

as for the other error, my [`switch`
statement](http://ziglang.org/documentation/master/#switch) needs to know what
to do for everything that's not a `+`, even if it's nothing. In my case, that's
exactly what I want.

```
for (src) |c| {
    switch(c) {
        '+' => mem[0] += 1,
        else => undefined
    }
}
```

Now, I can compile the program. If I run it with a warn on the end of it,

```zig
const warn = @import("std").debug.warn;

pub fn main() void {
  var mem = []u8{0} ** 30000;
  const src = "+++++";

  for (src) |c| {
      switch(c) {
          '+' => mem[0] += 1,
          else => undefined
      }
  }

  warn("{}", mem[0]);
}
```

I get `5` printed to
[stderr](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_(stderr)),
like I would expect.

From here
-------

It becomes straightforward to support `-`.

```zig
switch(c) {
    '+' => mem[0] += 1,
    '-' => mem[0] -= 1,
    else => undefined
}
```

To use `>` and `<`, I'll need a helper variable that represents a "pointer"
into the memory I've allocated for brainfuck's "user space".

```zig
var memptr: u16 = 0;
```

an unsigned 16 bit number can be a maximum of 65,535, much more than enough to
index the entire 30,000 byte address space.

> Actually, all I _really_ need is an unsigned _15 bit_ number, which would be
> enough for 32,767. Zig allows for fairly [arbitrarily wide types](http://ziglang.org/documentation/master/#Primitive-Types), but not a u15 just yet.

Now, instead of indexing `mem[0]` for everything, I can use this variable.

```zig
'+' => mem[memptr] += 1,
'-' => mem[memptr] -= 1,
```

`<` and `>`, then, are simply incrementing and decrementing that pointer.

```zig
'>' => memptr += 1,
'<' => memptr -= 1,
```

Great. We can write "real" programs with this sort of!

Zig has a simple built in testing apparatus. Anywhere in any file I can write a
test block:

```zig
test "Name of Test" {
  // test code
}
```

And then run the tests from the command line with `zig test $FILENAME`. There
is nothing special about test blocks except that they are executed only under
these circumstances.

Look at this:

```zig
// test.zig
test "testing tests" {}
```

```
zig test test.zig
```

```
Test 1/1 testing tests...OK
```

Of course, an empty test is not useful. I can use `assert` to actually assert
test cases.

```zig
const assert = @import("std").debug.assert;

test "test true" {
    assert(true);
}

test "test false" {
    assert(false);
}
```

```
Test 1/2 test true...OK
Test 2/2 test false...assertion failure
Unable to open debug info: TodoSupportMachoDebugInfo

Tests failed. Use the following command to reproduce the failure:
./zig-cache/test
```

[We don't have traces on Mac yet, unfortunately.](https://github.com/zig-lang/zig/blob/44d8d654a0ba463a1d4cf34d435c8422bfcd1c81/std/debug/index.zig#L268)

In order to test this effectively, I need to break it up. Let's start with this;

```
fn bf(src: []const u8, mem: [30000]u8) void {
    var memptr: u16 = 0;
    for (src) |c| {
        switch(c) {
            '+' => mem[memptr] += 1,
            '-' => mem[memptr] -= 1,
            '>' => memptr += 1,
            '<' => memptr -= 1,
            else => undefined
        }
    }
}

pub fn main() void {
    var mem = []u8{0} ** 30000;
    const src = "+++++";
    bf(src, mem);
}
```

This looks like it will work! All the types line up and everything, right?

and yet...

```zig
/main.zig:1:29: error: type '[30000]u8' is not copyable; cannot pass by value
```

Zig is very strict about this. Complex types, basically anything that can
possibly be variable in size, can't be passed by value. This makes stack
allocations incredibly predictible and consistent, and can avoid unneccessary
copying. If you want the semantics of pass by value in your program, you are
free to implement them in user space using a custom allocation strategy, but
the language itself is designed to discourage this under normal circumstances.

The natural way to get around this would be to pass a pointer instead (passing
by reference). Zig prefers a different strategy, though,
[slices](http://ziglang.org/documentation/master/#Slices). A slice is sort of
just a souped up pointer with bounds checking and a `len` property attached to
it. The syntax looks like this in the function signiture:

```zig
fn bf(src: []const u8, mem: []u8) void { ... }
```

and this at the call site:

```
bf(src, mem[0..mem.len]);
```

It resembles taking a sliced index! Notice that I'm defining the upper bound by
simply referencing the length of the array. There is a shorthand for this:

```
bf(src, mem[0..]);
```

> maybe something about []const u8 and how that works for src but not mem and why.

Now I can start writing tests.
