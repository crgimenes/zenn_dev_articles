---
title: "Goのスライスと配列の違いを理解する"
emoji: "🔪"
type: "tech"
topics: ["go", "slice", "array", "development"]
published: true
---

## Array

Arrays in Go always have a fixed size.

When you add a new element to an array, what happens internally is that a new array is created and the old and new items are copied into it. Eventually the space occupied by the old array gets freed by the garbage collector. So it's important, whenever possible, to declare the array with the maximum size it will need and avoid appending items, especially inside a loop.

## Slice

A slice, on the other hand, is an abstraction for accessing the contents of an array. You can think of a slice as a structure of pointers that points to the items of an array and knows where to start, the slice's length, and the array's capacity. This makes slice operations very fast.

This can cause some confusion because if you have an array that holds, say, four elements, and you append one more to it through a slice, you end up with a new array referenced by the slice, but the old reference to the array still works.

```golang
package main

import (
    "fmt"
)

func main() {
    // this is an array
    a := [6]string{"this", "is", "a", "collection", "of", "words"}

    // here we create a slice pointing to array a
    s := a[:]

    fmt.Printf("value of a[3]: %q\n", a[3])
    fmt.Printf("value of s[3]: %q\n", s[3])

    // since s points to a, changing
    // s also changes a
    fmt.Println(`— Since "s" points to "a", changing "s" also changes "a"`)
    s[3] = "array"
    fmt.Printf("value of a[3]: %q\n", a[3])
    fmt.Printf("value of s[3]: %q\n", s[3])

    // now let's append to slice s
    fmt.Println(`— Appending to "s" creates a new array`)
    s = append(s, "!")

    // this created a new array and copied the old data
    // now let's change the value of s[3] to demonstrate this
    s[3] = "slice"
    fmt.Printf("value of a[3]: %q\n", a[3])
    fmt.Printf("value of s[3]: %q\n", s[3])
}
```

The example above produces the following output:

```bash
value of a[3]: "collection"
value of s[3]: "collection"
— Since "s" points to "a", changing "s" also changes "a"
value of a[3]: "array"
value of s[3]: "array"
— Appending to "s" creates a new array
value of a[3]: "array"
value of s[3]: "slice"
```

Notice that the first time s[3] is changed, a[3] changes too, because s points to a. After we append a new item to s, a new array is created, and s stops pointing to a and starts pointing to this new array instead. And since there's still a reference to a, the garbage collector won't touch it yet.

Using slices and pre-allocating the array gives you great speed, but you need to be careful not to get confused. Not understanding how slices and arrays work is a great source of bugs.

Take the following example:

```golang
package main

import "fmt"

func main() {
    a := [3]int{0, 0, 0}
    v := a[:]
    for i := 0; i <= 5; i++ {
        v = append(v, i)
    }
    fmt.Println(v)
}
```

Once again we're using a slice to access a pre-allocated array. Since we're appending without paying attention to the size already allocated, we end up with an array of eight items instead of four.

Here's the result:

```bash
[0 0 0 0 1 2 3 4]
```

The correct approach here would be to check the array's capacity before adding a new item, so you can decide whether to do a plain assignment or an append.

## len() and cap()

Go has two built-in functions you can use to inspect a slice: *len()*, which returns the size currently used by the slice, and *cap()*, which returns the current capacity of the array the slice points to.

Let's modify the previous example to use these functions and investigate Go's behavior and the space allocated for the array.

```golang
package main

import "fmt"

func main() {
    a := [3]int{0, 0, 0}
    v := a[:]
    fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    for i := 0; i <= 4; i++ {
        v = append(v, i)
        fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    }
    fmt.Println(v)
}
```

This example produces the following result:

```bash
len: 3 cap: 3
len: 4 cap: 8
len: 5 cap: 8
len: 6 cap: 8
len: 7 cap: 8
len: 8 cap: 8
[0 0 0 0 1 2 3 4]
```

Notice that since Go could predict the number of iterations of the *for* loop, it was smart enough to pre-allocate the array with the items it would need. This optimization helps a lot, but in a situation where the compiler can't predict the number of iterations, Go will reallocate the whole array on every iteration. And of course, we're still making the mistake of not using the first items of our array, since we're always appending.

Let's look at a way to improve this:

```golang
package main

import "fmt"

func main() {
    a := [3]int{0, 0, 0}
    v := a[:]
    fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    for i := 0; i <= 4; i++ {
        if i < len(v) {
            v[i] = i
            fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
            continue
        }
        v = append(v, i)
        fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    }
    fmt.Println(v)
}
```

In this example we check the slice's length beforehand and decide whether to append or not. But in this case Go tries to pre-allocate extra space for possible future appends and ends up wasting memory.

Here's the result:

```bash
len: 3 cap: 3
len: 3 cap: 3
len: 3 cap: 3
len: 3 cap: 3
len: 4 cap: 8
len: 5 cap: 8
[0 1 2 3 4]
```

We're no longer just appending, but the array's capacity is still larger than necessary.

The best way to solve this problem is to pre-allocate the array with the exact size we know we'll need.

```golang
package main

import "fmt"

func main() {
    a := [5]int{}
    v := a[:]
    fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    for i := 0; i <= 4; i++ {
        if i < len(v) {
            v[i] = i
            fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
            continue
        }
        v = append(v, i)
        fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    }
    fmt.Println(v)
}
```

And here's the result of the code above:

```bash
len: 5 cap: 5
len: 5 cap: 5
len: 5 cap: 5
len: 5 cap: 5
len: 5 cap: 5
len: 5 cap: 5
[0 1 2 3 4]
```

Now the result and the capacity are finally correct, and since we're no longer appending, we can drop that code entirely.

```golang
package main

import "fmt"

func main() {
    a := [5]int{}
    v := a[:]
    fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    for i := 0; i <= 4; i++ {
        v[i] = i
        fmt.Printf("len: %v cap: %v\n", len(v), cap(v))
    }
    fmt.Println(v)
}
```

Now that our code no longer appends, it's much faster and *garbage collector friendly*.
