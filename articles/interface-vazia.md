---
title: "Goの空インターフェース（interface{}）の使いどころと落とし穴"
emoji: "📦"
type: "tech"
topics: ["go", "interface", "development"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=yBTzaVwqvng).

The empty interface is a type that accepts anything. You can pass whatever you want as a function parameter or store it in a variable of type `interface{}`.

At first glance this looks convenient, but when we use `interface{}` we throw away the type validation done at compile time and lose one of the great advantages of a compiled language with strong, static typing.

And since the type check will not happen at compile time, it becomes your responsibility to check that you are receiving the right type at run time.

## Identifying the type

When we want to know the type of a value, especially while debugging and trying to confirm that what arrived is what we expected, we can use `fmt.Printf` with the `%T` verb, as in the example below.

```golang
var value interface{}
value = 1
fmt.Printf("tipo de value: %T\n", value)
```

In this example we declare the variable `value` as `interface{}`, so now we can assign any value to it. Since we assigned an integer, `Printf` with the `%T` verb will report that the variable is of type `int`.

Let's look at a complete example.

```golang
package main

import (
    "fmt"
)

func main() {
    var value interface{}
    value = 1
    fmt.Printf("tipo de value: %T\n", value)
    value = 3.14
    fmt.Printf("tipo de value: %T\n", value)
    value = "isso é uma string"
    fmt.Printf("tipo de value: %T\n", value)
}
```

This small program should print the following.

```bash
tipo de value: int
tipo de value: float64
tipo de value: string
```

## Switch

Inspecting the type of a variable is simple, as we saw, and it helps a lot when debugging and checking whether we are getting what we expect. Now let's make the code do that work on its own.

We will combine a switch with the `(type)` assertion, which returns the type of the variable. See the example.

```golang
package main

import (
    "fmt"
)

func main() {
    var value interface{}
    value = 1
    switch value.(type) {
    case int:
        fmt.Println("Value é do tipo int")
    case string:
        fmt.Println("Value é do tipo string")
    default:
        fmt.Printf("Tipo %T não implementado\n", value)

    }
}
```

If `value` holds an `int`, our program prints `Value é do tipo int`. If we assign a string to `value`, the output is `Value é do tipo string`, and for any other value the program warns that support for that type is not implemented yet.

Once we know the type of the variable, we can assert it to the correct type and use it without trouble.

```golang
switch value.(type) {
case int:
    fmt.Println(value.(int))
case string:
    fmt.Println(value.(string))
```

If we skip this validation and simply assert the variable to the type we want, we risk the program blowing up with a `panic` when the type that came in is not the one we expected.

## map[string]interface{}

A very common use is combining empty interfaces with maps to convert JSON strings into structures whose format we do not know for sure. Since we know neither the fields nor their types, we can use a `map[string]interface{}`, which basically matches any structure.

```golang
package main

import (
    "fmt"
    "encoding/json"
)

func main() {
    b := []byte(`{"Name":"Cesar","Value":10}`)
    
    var m map[string]interface{}
    m = make(map[string]interface{})
    
    err := json.Unmarshal(b, &m)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Printf("%#v\n", m)
}
```

In this example we first declare a byte array holding a JSON structure, then declare a map of strings to empty interfaces and allocate it in memory. Next we use `json.Unmarshal` to read the byte array and populate the map with the fields and values it finds. We check for errors, because there is always the chance the JSON is invalid, and then we use one more small trick to display the structure: the `%#v` verb in `fmt.Printf` shows more detail instead of only the value, as `%v` alone would.

Let's look at a more complete example using `range` to walk through the JSON fields and `switch` to branch to the correct type.

```golang
package main

import (
    "encoding/json"
    "fmt"
)

func main() {
    b := []byte(`{"Name":"Banana","Value":2.10}`)

    var m map[string]interface{}
    m = make(map[string]interface{})

    err := json.Unmarshal(b, &m)
    if err != nil {
        fmt.Println(err)
        return
    }
    for k, v := range m {
        switch v.(type) {
        case float64:
            fmt.Printf("%v %v\n", k, v.(float64))
        case string:
            fmt.Printf("%v %v\n", k, v.(string))
        default:
            fmt.Printf("Tipo %T não implementado\n", v)

        }
    }
}
```

There is one more way to check whether an empty interface holds the type you want, shown below.

```golang
package main

import "fmt"

func main() {
    var value interface{}
    value = 1

    str, ok := value.(string)
    if !ok {
        fmt.Println("Value não é string")
    }
    fmt.Println(str)
}
```

Here we use `str, ok := value.(string)`, so that if `value` is a `string`, ok will be true and str will hold the value itself, already as a string. It is a simple way to test the type without writing a `switch case`.

I hope this cleared up a bit more about the empty interface, its uses, and why it can be risky.

## Useful links

- Source code for today's examples
    1. https://play.golang.org/p/mf317GEVSo3
    2. https://play.golang.org/p/yAVCQjdk56Q
    3. https://play.golang.org/p/ucMSAgbGIEO
    4. https://play.golang.org/p/-eLaKhS-ojh
    5. https://play.golang.org/p/vrelMrzXnN-
    6. https://play.golang.org/p/cA-JutjQWWf
- [Our study group repository](https://github.com/crgimenes/grupo-estudos-golang)
