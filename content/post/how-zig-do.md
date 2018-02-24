---
title: How Zig do?
draft: true
scripts: ["zighl.js"]
---

Hello, good morning or whatever! Let's write a brainfuck interpreter. "Why
are you doing this?" you might say. You won't find that answer here.

Carpe something! The time is now! Let's make it in [Zig](http://ziglang.org/).

Zig is....
--------

...new, still very much in beta, and moving quickly. If you've seen any Zig
previously, the code in this post might look different. It is different! Zig
0.2.0 has just been released, coinciding with LLVM 6, and includes a lot of
changes to the syntax. Most notably, many of the sigils have been replaced by
keywords. See [here]() for a more in depth explanation.

For more on how brainfuck works, [look
here](https://blog.jfo.click/how-brainfuck-works/).

say a thing about wrapping around the memory etc.

Zig is designed to be readable (link), and as such it's fairly intuitive if you
are familiar with similarly compiled, (~)typed languages like C, C++, and even
in some cases, Rust.

Getting Zig
------------

This code was all compiled and tested with [Zig 0.2.0](), which is available
right now, via different channels, including [homebrew]() if you're on a mac.


Ok, here we go.
--------------

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

`main` must be declared public in order to be visible outside of its module...

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
handling](http://ziglang.org/documentation/master/#Hello-World) and stdout is
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
        else => {}
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
          else => {}
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
    else => {}
}
```

To use `>` and `<`, I'll need a helper variable that represents a "pointer"
into the memory I've allocated for brainfuck's "user space".

```zig
var memptr: u16 = 0;
```

an unsigned 16 bit number can be a maximum of 65,535, much more than enough to
index the entire 30,000 byte address space.

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
            else => {}
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

Now I can start writing tests in earnest, unit testing the `bf()` function
directly. I can just put test blocks at the bottom of this file, for now...

```zig
test "+" {
    var mem = []u8{0};
    const src = "+++";
    bf(src, mem[0..]);
    assert(mem[0] == 3);
}
```

I'm operating on the mem byte array (of a single byte) and then asserting that
what I thought was going to happen (the byte is incremented three times)
happened. It did!

```shell
Test 1/1 +...OK
```

The `-` case is similar:

```zig
test "-" {
    var mem = []u8{0};
    const src = "---";
    bf(src, mem[0..]);
    assert(mem[0] == 253);
}
```

But this fails! When I try to subtract `1` from `0` I get...

```shell
Test 2/2 -...integer overflow
```

Once again, Zig is forcing me to consider this possibility explicitly. In this
case, it so happens that I don't care about this overflow- in fact I want it to
default to overflow as per the [brainfuck spec](dfji), such as it is. Zig has a set
of auxiliary arithmetic operators that offer ["guaranteed wrap around
semantics"](http://ziglang.org/documentation/master/#Wrapping-Operations)

```zig
'+' => mem[memptr] +%= 1,
'-' => mem[memptr] -%= 1,
```

For `<` and `>`, I'll navigate a small array and then check the value of an
incremented cell:

```zig
test ">" {
    var mem = []u8{0} ** 5;
    const src = ">>>+++";
    bf(src, mem[0..]);
    assert(mem[3] == 3);
}
```

and...

```zig
test "<" {
    var mem = []u8{0} ** 5;
    const src = ">>>+++<++<+";
    bf(src, mem[0..]);
    assert(mem[3] == 3);
    assert(mem[2] == 2);
    assert(mem[1] == 1);
}
```

For this last one, I can directly compare the result to a static array using...

```
const mem = std.mem;
```

```zig
test "<" {
    var storage = []u8{0} ** 5;
    const src = ">>>+++<++<+";
    bf(src, storage[0..]);
    assert(mem.eql(u8, storage, []u8{ 0, 1, 2, 3, 0 }));
}
```


...and remember, string literals are just `u8` arrays in zig, and I can put in
hexadecimal literals inside them ,so the following will work in the exact same
way!

```zig
assert(mem.eql(u8, storage, "\x00\x01\x02\x03\x00"));
```

Let's add `.`! This simply prints the byte value as a character in the cell
that is currently being pointed to. For now, I'll abuse `warn`, and revisit
this later to properly handle `stdout` here.

```zig
'.' => warn("{c}", storage[memptr]),
```

> how do I test this?

For now, I'll ignore `,`. // come back to that.

Loops
-----

`[` and `]` are where the magic happens....

```brainfuck
[   if the value of current cell is zero skip to the matching bracket without executing the code
]   if the value of the current cell is NOT zero go back to the opening bracket and execute the code again
```

I'll _start_ with the test case this time, testing them together (as it doesn't
make sense to test them in isolation).

```zig
test "[] skips execution and exits" {
    var storage = []u8{0} ** 2;
    const src = "+++++>[>+++++<-]";
    bf(src, storage[0..]);
    assert(storage[0] == 5);
    assert(storage[1] == 0);
}
```

and I'll stub out the switch case:

```zig
'[' => if (storage[memptr] == 0) {
},
']' => if (storage[memptr] == 0) {
},
```

Now, _what goes here_? A naive approach presents itself. I will simply advance
the src index forward until I find a `]`! But I cannot do this in a zig `for`,
which is designed simply to iterate over elements of a collection, never to
skip around them. The appropriate construct here is `while`

from:

```
var memptr: u16 = 0;
for (src) |c| {
    switch(c) {
      ...
    }
}
```

```
var memptr: u16 = 0;
var srcptr: u16 = 0;
while (srcptr < src.len) {
    switch(src[srcptr]) {
      ...
    }
    srcptr += 1;
}
```

Now, I am free to reassign the `srcptr` index mid block, and I will do so.

```zig
'[' => if (storage[memptr] == 0) {
    while (src[srcptr] != ']')
        srcptr += 1;
},
```

This satisfies the test "[] skips execution and exits", albeit flimsily, as
we'll see.

What about the closing brace? I suppose the analog will be simple enough:

```zig
test "[] executes and exits" {
    var storage = []u8{0} ** 2;
    const src = "+++++[>+++++<-]";
    bf(src, storage[0..]);
    assert(storage[0] == 0);
    assert(storage[1] == 25);
}
```

```zig
']' => if (storage[memptr] != 0) {
    while (src[srcptr] != '[')
        srcptr -= 1;
},
```

You might see where this is going... the naive solution to both brackets has a
fatal flaw in it completely breaks when there are nested loops of any kind. Consider:

```brainfuck
++>[>++[-]++<-]
```

This should result in `{ 2, 0 }`, but the first opening bracket will dumbly
jump to the first available closing bracket, and then get all confused. I need
it to be able to jump to the _next closing bracket at the same nesting depth_.
This is a fiddly operation but it's easy to add a depth count and keep track of
it while going through the src string.

```zig
'[' => if (storage[memptr] == 0) {
    var depth:u16 = 1;
    srcptr += 1;
    while (depth > 0) {
        switch(src[srcptr]) {
            '[' => depth += 1,
            ']' => depth -= 1,
            else => {}
        }
        srcptr += 1;
    }
},
```

> something about how long everything is.

TODO:

now refactoring.

now make a literal stack, then a generic stack.

swap warns for stdout

see about explaining @cimport for `getc` and supporting `,`

make main take a filepath and build in some examples: serpinsky, echo, and fizzbuzz.

> Actually, I was reading some of my old blog posts and I came across
> [this](/fizzbuzz-in-brainfuck-part-3/#never-going-to-happen).


You actually can make a u15 like this:
`const u15 = @IntType(false, 15);`
> Actually, all I _really_ need is an unsigned _15 bit_ number, which would be
> enough for 32,767. Zig allows for fairly [arbitrarily wide types](http://ziglang.org/documentation/master/#Primitive-Types), but not a u15 just yet.

