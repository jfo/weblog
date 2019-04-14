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
docs](https://webassembly.github.io/spec/core/syntax/modules.html#), which is
thorough and complete but is sometimes hard to read without context.

types
-------
funcs
-------
tables
-------
mems
-------
globals
-------
elem
-------
data
-------
start
-------
imports
-------
exports
-------
