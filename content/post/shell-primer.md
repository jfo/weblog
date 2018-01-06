---
title: Shell Primer
draft: true
---

<style>
  @keyframes blinker {
    70% { opacity: 0; }
  }
</style>
<code><h1>~$<span style="animation: blinker 1s linear infinite;">▓</span></h1></code>

A filesystem is a tree
----------------------

A computer that has storage stores data in what you can conceive of as one long
continuous block of ones and zeros

https://blog.jfo.click/c-and-simple-types/

For completely obvious reasons, this data needs to be organized _somehow_.
Imagine, if you will, a huge library whose books are in no particular order.
Not very useful, right? Or how about a good chunk of those books' pages are
split up and spread out among all the shelves and crammed in between each
other. Even less useful! They need to be organized according to some sort of
system. A filing system. 

This is what a filesystem does on a computer.

https://arstechnica.com/gadgets/2008/03/past-present-future-file-systems/

The specifics of how this is implemented is interesting! But for now, all you
need to know is that the filesystem is a tree consisting of:

1- files
2- directories that can contain files and other directories


$PATH

Every command is a program
--------------------------

You have an identity
--------------------


how do you move around the file system?

cd for change directory.

cd . and cd .. and cd ~ are special. cd by itself is like cd ~

how about cd - that's a special trick!

ls

touch maybe

what a file _is_

editor - subl nano vim emacs
mac osx 'open' will launch whatever the default handler is

man

running a program.
ruby python node php
