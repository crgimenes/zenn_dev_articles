---
title: "GoでJSONのMarshal/Unmarshalを自作する"
emoji: "🔄"
type: "tech"
topics: ["go", "json"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=ALlzgQfXVFo).

Postgres's default date format is incompatible with Go's default format, and our system uses JSON heavily to both send and receive information from the database.

Having to remember to parse the date into the correct format every single time simply isn't practical. It's much better to teach Go how to handle dates and times in good old ISO 8601.

By the way, I highly recommend always using ISO 8601 UTC for everything in the backend, and only switching to the local format and timezone when displaying it to the user. But that's a story for another day.

The source code for the Go package is [available on GitHub](https://github.com/nuveo/dbtime).

### MarshalJSON

Now let's see how the code works. In the example below we create a `Time` struct and implement a MarshalJSON function for it. In `main` we instantiate a struct with some data, then use `json.MarshalIndent`, which walks the struct and, when it reaches the Time field, uses the function we defined instead of the system default.

```golang
package main

import (
    "encoding/json"
    "fmt"
    "time"
)

type Time struct {
    time.Time
}

const layout = "2006-01-02T15:04:05.999999"

func (t Time) MarshalJSON() ([]byte, error) {
    return []byte(fmt.Sprintf(`"%s"`, t.Time.Format(layout))), nil
}

func main() {
    data := struct {
        Name string
        Time Time
    }{
        Name: "teste",
        Time: Time{time.Now().Add(time.Millisecond * time.Duration(54321))},
    }

    json, err := json.MarshalIndent(data, "", "\t")
    if err != nil {
        fmt.Println(err)
    }

    fmt.Println(string(json))
}
```

Here's the output from `The Golang Playground`. Notice that the date format follows our function.

```json
{
    "Name": "teste",
    "Time": "2009-11-10T23:00:54.321"
}
```

### UnmarshalJSON

In the next example we do the opposite: we define an UnmarshalJSON function for our struct. Take a look.


```golang
package main

import (
    "encoding/json"
    "fmt"
    "time"
)

type Time struct {
    time.Time
}

const layout = "2006-01-02T15:04:05.999999"

func (t *Time) UnmarshalJSON(b []byte) (err error) {
    if b[0] == '"' && b[len(b)-1] == '"' {
        b = b[1 : len(b)-1]
    }
    if string(b) == `null` {
        *t = Time{}
        return
    }
    t.Time, err = time.Parse(layout, string(b))
    return
}

func main() {
    data := struct {
        Name string
        Time Time
    }{}

    b := []byte(`{"Name": "teste", "Time": "2009-11-10T23:00:54.321"}`)

    err := json.Unmarshal(b, &data)
    if err != nil {
        fmt.Println(err)
    }

    fmt.Println(data.Time.String())
}
```

When the system receives the byte array to parse and populate the struct, it walks through the data, and upon reaching the Time field the package uses our `UnmarshalJSON` function instead of the system default. That's how we can correctly read data that isn't in the system's standard format.

Besides formatting data correctly, we can also use this feature for other tasks. For example, you can walk through the fields checking the information of a given type and return an error if you find invalid data. It's a form of data validation that works inside the type's parser and can be very useful. Just be careful, because it can end up hiding where the error is coming from, so write good error messages. In the json package's own documentation, the example is a counter that counts animals in a zoo.

## Useful links

- [Our study group's repository](https://github.com/crgimenes/grupo-estudos-golang)
