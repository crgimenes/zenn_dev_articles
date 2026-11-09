---
title: "Goでビット演算を楽しむ"
emoji: "🔢"
type: "tech"
topics: ["go", "development"]
published: true
---

## Playing with bits

The idea is to manipulate the CGA color palette, which stores colors in a single byte. This may look complicated, but it is actually very simple: we only need to learn a handful of operations to manipulate bits.

Before we start, let's agree on the following: when I talk about the upper or high part of a set of bits, I mean the leftmost bits, and when I talk about the lower or low part, I mean the rightmost bits. It is not always like this, but for the purposes of this text that is how it works — this is what we call [lite-endian](https://en.wikipedia.org/wiki/Endianness)

## Shift (<< and >>, shifts bits)

Shift is the operator used to move bits to the right << or to the left >>

## Example

```
00000001 << 1 results in: 00000010
00000001 << 2 results in: 00000100
00000001 << 3 results in: 00001000

10000000 << 1 results in: 01000000
10000000 << 2 results in: 00100000
10000000 << 3 results in: 00010000
```

## AND (&)

We use AND to define a mask, and we use that mask to extract the part we want from a set of bits.

## Example

Let's say we want to extract only the four center bits of a byte. To do that we define the following mask: 00111100 — note that the bits we want to extract are set to 1 and the ones we don't want are set to 0. Then we just compare the byte holding the value to be extracted against the mask using AND (&)

```bash
 value     & mask
10101010 & 00111100 results in: 00101000
```

What AND does is compare each bit with its counterpart in the mask, and only where both bits are 1 will the result be 1. This zeroes out the bits outside the mask.

And now we can shift right two positions to get the value we want extracted into a byte.

```bash
00101000 >> 2 results in: 00001010
```


In other words, we use AND together with a bit mask to isolate the parts we want from a set of bits.

## OR (|)


OR, in this case, is the opposite: we use it to combine two sets of bits into a single one.

## Example

Let's say we want to put these four bits 1010 in the upper part of a byte, followed by these 4 bits 0101 in the lower part.

First we move the 4 bits to the upper part of the byte:

```bash
00001010 << 4 results in: 10100000
```

Then we use OR to join the upper and lower parts:

```bash
10100000 | 00000101 results in: 10100101
```

Let's look at an example in Go:

```golang
package main

import "fmt"

func main() {

    /*
        Takes the foreground and background color codes
        and combines both into a single byte
    */

    var b, f byte

    b = 0x9 // background color (light blue)
    f = 0x4 // font color (red)

    // combines both codes to compose the color code
    c := (f & 0x0f) | (b << 4)

    /*
        Takes the color code and splits the font
        and background colors so they can be used separately
    */

    h := (c & 0xf0) >> 4 // High Nibble
    l := c & 0x0f        // Low Nibble
    blink := (c & 0x80) >> 7

    /*
        Show the results
    */

    fmt.Printf("cor do fundo.: %04b\n", h)
    fmt.Printf("cor da letra.:     %04b\n", l)
    fmt.Printf("codigo da cor: %08b\n", c)
    fmt.Printf("blink........: %b", blink)
}
```

[Try it on The Golang Playground](https://play.golang.org/p/FSOUAd5Kes)

