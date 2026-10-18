---
title: "GoでシンプルなJSON Lintツールを作る"
emoji: "🔍"
type: "tech"
topics: ["go", "json", "cli"]
published: true
---

Watch the video about this file [here](https://www.youtube.com/watch?v=VXVZE5SYMiM).

## A JSON Lint in Golang

This is a small command line utility to validate and format JSON that can also be used as a package. The original idea was to write a parser to validate the JSON, but that turned out to be unnecessary: Golang itself gives us everything we need in the error, including the offset where it happened. From there it was simple to display errors in a more complete way, with an arrow pointing at exactly where the problem is.

```golang
package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "os"

    "github.com/crgimenes/goconfig"
    "github.com/gosidekick/jsonlint"
)

func printError(a ...interface{}) {
    _, err := fmt.Fprintf(os.Stderr, "\x1b[91m%v\033[0;00m\n", a...)
    if err != nil {
        fmt.Println(err)
    }
}

func printIndicator(a ...interface{}) {
    _, err := fmt.Fprintf(os.Stderr, "\x1b[96m%v\033[0;00m\n", a...)
    if err != nil {
        fmt.Println(err)
    }
}

func main() {
    type configFlags struct {
        Input  string `json:"i" cfg:"i" cfgDefault:"stdin" cfgHelper:"input from"`
        Output string `json:"o" cfg:"o" cfgDefault:"stdout" cfgHelper:"output to"`
    }

    cfg := configFlags{}
    goconfig.PrefixEnv = "JSON_LINT"
    err := goconfig.Parse(&cfg)
    if err != nil {
        printError(err)
        os.Exit(-1)
    }
    var j []byte

    if cfg.Input == "stdin" {
        j, err = ioutil.ReadAll(os.Stdin)
        if err != nil {
            printError(err)
            os.Exit(-1)
        }
    } else {
        j, err = ioutil.ReadFile(cfg.Input)
        if err != nil {
            printError(err)
            os.Exit(-1)
        }
    }
    var m interface{}
    err = json.Unmarshal(j, &m)
    if err != nil {
        out, offset := jsonlint.ParseJSONError(j, err)
        printError(out)
        if offset > 0 {
            out = jsonlint.GetErrorJSONSource(j, offset)
            printIndicator(out)
        }
        os.Exit(-1)
    }
    j, err = json.MarshalIndent(m, "", "\t")
    if err != nil {
        printError(err)
        os.Exit(-1)
    }
    if cfg.Output == "stdout" {
        fmt.Println(string(j))
        return
    }
    err = ioutil.WriteFile(cfg.Output, j, 0644)
    if err != nil {
        printError(err)
    }
}
```

Here is the code for our utility, which doubles as an example of how to use our error handling package. Basically, you just pass the error from `json.Unmarshal` to `jsonlint.ParseJSONError` and you get back a string with a more detailed description of the error along with the offset where it occurred. You can then pass the JSON that caused the error and that offset to `jsonlint.GetErrorJSONSource`, and it will produce a string containing the problematic part of the code along with an arrow pointing to the first character the parser could not process.

This utility, like many others, is being built in our [Go study group](https://github.com/crgimenes/grupo-estudos-golang) repository.

- [Our group's repository](https://github.com/crgimenes/grupo-estudos-golang)

We meet every Thursday at 10:00 PM. To join, [enter the Golang channel on Slack](https://invite.slack.golangbridge.org) and look for #brazil
