---
title: "GoでJSONを扱うテクニックまとめ"
emoji: "🧰"
type: "tech"
topics: ["go", "development"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=0PJ1YqO3wjI).

## Converting and validating JSON

It's always good to check whether the JSON is valid first. That saves you debugging time chasing a problem that isn't in your code. A good online tool for this is [JSONLint](https://jsonlint.com).

Another great online tool is [JSON-to-Go](https://mholt.github.io/json-to-go), which converts JSON files into Go structs. It won't factor repeated parts into sub-structs, but it helps a lot, especially when the structure is large and complex.

## Walking Through JSON with Recursion

Recursive functions are delightful. They're extremely important to computing, and how they work may not be intuitive, so it's worth spending some time studying recursion. A good starting point is the excellent video [Programming Loops vs Recursion from the Computerphile channel](https://www.youtube.com/watch?v=HXNhEYqFo0o).

Let's see how to load a JSON file into a map and then walk through each element of that map, which is very useful when you want to process the field values.

### Reading a file into a variable

We use the ReadFile function from the ioutil package to read the file. The advantage of this function is that it's very convenient, but be careful: depending on the file size, loading everything into RAM at once may not be a good idea.

```golang
data, err := ioutil.ReadFile("../payload.json")
if err != nil {
    fmt.Println(err)
    return
}
```

Now we have the file contents in a byte array in RAM, the `data` variable.

### Converting to a map

To convert the byte array into a map we'll use the `Unmarshal` function from the `json` package.

```golang
payload := make(map[string]interface{})
err = json.Unmarshal(data, &payload)
if err != nil {
    fmt.Println(err)
    return
}
```

At this point the payload variable holds all the data in a fairly convenient format: every JSON field name is now a key in the map, and every object is in the interface. Remember that it's always wise to be careful with empty interfaces `interface{}`.

### Checking the map

Finally we call the `chkMap` function, which we'll see below, to check whether any value is under the limit.

```golang
if chkMap(payload) {
    fmt.Println("Um ou mais itens abaixo do limite")
}
fmt.Println("fim")
```

### The recursive functions

The `chkMap` function walks through each field of the map. If any of the objects contains the fields `Limit` and `Value`, we compare the values and return right away depending on the result. Otherwise we go into the loop that walks every field at that level looking for fields of type `map` or type `slice`, and calls the appropriate function when it finds one. One note about this code: we created a helper function to make it more readable. Besides `chkMap`, which walks maps, we also created `chkSlice` to walk `slices`, separating these two memory structures into specialized functions. It would be perfectly possible to write this code in a single function, but we'd lose the chance to demonstrate recursion across more than one function.

```golang
func chkMap(payload map[string]interface{}) (ret bool) {
    limit, lmtOk := payload["Limit"]
    value, valOk := payload["Value"]
    if lmtOk && valOk {
        if value.(float64) < limit.(float64) {
            ret = true
            return
        }
    }

    for _, v := range payload {
        switch v.(type) {
        case []interface{}:
            ret = chkSlice(v.([]interface{}))
        case map[string]interface{}:
            ret = chkMap(v.(map[string]interface{}))
        }
        if ret {
            return
        }
    }
    return
}

func chkSlice(pauload []interface{}) (ret bool) {
    for _, v := range pauload {
        switch v.(type) {
        case []interface{}:
            ret = chkSlice(v.([]interface{}))
        case map[string]interface{}:
            ret = chkMap(v.(map[string]interface{}))
        }
        if ret {
            return
        }
    }
    return
}
```

## Handling JSON with structs

Another way we often handle JSON is converting it into a struct, manipulating the data as we want, and then converting it back to JSON.

### omitempty

Go provides some useful tools, such as the `omitempty` tag, which we can use to tell the JSON parser that if a given field is empty it should be omitted when generating the JSON.

```golang
type metadata struct {
    SystemID  int    `json:"SystemID,omitempty"`
    FileID    string `json:"FileID,omitempty"`
    SubModule string `json:"SubModule,omitempty"`
}
```

In this example, whenever the `SystemID` field is zero, or `FileID` is an empty string `""`, or `SubModule` is an empty string, the field will be omitted when generating the JSON.

### Fields as pointers

Another way to handle data with structs is turning the field into a pointer: just put an asterisk `*` in front of the field type. Don't worry, if `C` traumatized you with pointers, Go is much gentler about it.

If a field in our struct is a pointer and its value is `nil`, when the `Marshal` function converts the struct to JSON that field will show up as a `Null` field. That's rarely what we want, but if we add the `omitempty` tag we saw earlier, the field disappears entirely.

And of course, if you want to return an empty object, instead of using a pointer just set the field to an empty instance — in the case of `metadata` that would be `metadata{}` — and each field inside the struct will follow its own tags, as we've already seen.

### Partial structs

Often we don't want all the data from the JSON. A few fields from one part may be enough, and there's no reason to build [a huge struct like the one in the example](https://github.com/crgimenes/grupo-estudos-golang) if we only want some of the data.

Let's suppose, for example, that we only want the `metadata` field from our example.

You don't need to declare the whole struct. To grab just that field we can declare the following struct.

```golang
type apenasMetadata struct {
    Payload []struct {
        Result struct {
            Metadata metadata
        }
    }
}
```

In this example we declare only the part of the struct we want. It has to follow the same path through the parent fields, but it made the struct much smaller, and when the JSON parser runs `Unmarshal` on the data it will happily ignore everything else and return only what's represented in the struct.

## Structs inside functions

And here's a tip for using small, specialized structs: you don't even need to declare them outside the function that will use them. Very handy for avoiding structures scattered around your code.

In the example below the `produtos` struct only exists inside the `structInetna` function.

```golang
func structInetna() {
    type produtos struct {
        Nome  string
        Valor float64
    }
    ...
}
```

And if you're only going to use it once, you don't even need to declare a new type — you can declare and instantiate it at the same time, as in the next example.

```golang
func structInetna() {
    produtos := struct {
        Nome  string
        Valor float64
    }{}
    ...
}
```

## A common mistake with structs and JSON

A very common mistake when using structs with the JSON parser is forgetting that lowercase fields are `private` in Go. Only uppercase fields are visible, and that applies to the JSON parser too, so if the struct field names start with a lowercase letter they'll be summarily ignored by the parser, both for `Unmarshal` and for `Marshal`.

If you want the field to be lowercase in the generated JSON, change the name in the tag, as in the example.

```golang
type device struct {
    Limit int `json:"limit"`
    Value int `json:"value"`
```

Note that the struct field is uppercase, which makes it visible to the parser, but the json tag is lowercase, meaning that when it's converted to and from a byte array it will use lowercase letters.

## More JSON tips

We also covered some of today's tips in this [short video from our study group](https://www.youtube.com/watch?v=FoHEIqTkksw).
