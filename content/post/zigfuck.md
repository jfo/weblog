---
title: Zigfuck
draft: true
scripts: ["zighl.js"]
---

```zig
fn bfseek(src: []const u8, si: u32) u32 {
  var depth:u16 = 1;
  var sii:u32 = si + 1;
  while (depth > 0) {
    switch(src[sii]) {
      '[' => depth += 1,
        ']' => depth -= 1,
        else => undefined
    }
    sii += 1;
  }
  return sii;
}

```
