---
title: "Goのテストカバレッジをシェルから手軽に可視化する"
emoji: "🧪"
type: "tech"
topics: ["go", "terminal"]
published: true
---

Unit tests are incredibly important, even for a compiled language like Golang.

Fortunately, most programming languages today have a good variety of unit testing tools. Go ships with some surprising ones, not just for running tests but also for analyzing code to find coverage gaps.

A quick, visual way to analyze test coverage is to write a script around `go tool cover` and load it in `zsh` or `bash`, which makes inspecting the code very simple.

Below is an example of a *gocover* function you can add to your favorite shell.

```sh
gocover () {
    t="/tmp/go-cover.$$.tmp"
    go test -coverprofile=$t $@ && \
    go tool cover -html=$t && \
    rm $t
}
```

When you run it, this function generates a test coverage report in HTML and automatically opens it in your machine's default browser. Anything in red is not covered, and anything in green is. It makes coverage gaps very easy to spot.

I use *gocover* as the name for this script, but ideally it should be a command with two letters at most — fast to type so you use it all the time.

Beyond analyzing my own code, this little script helps a lot during *code review*, letting me glance over what is and isn't covered.

Of course, in a language like Golang you don't need 100% test coverage; the compiler already guarantees that your code at least compiles.

What really matters isn't **making sure every feature is covered**. There's plenty of dishonest code sitting at 100% coverage that doesn't test the functionality or the error cases. Coverage only shows that the system passed through that line while the tests were running, which is exactly why the percentage isn't a good indicator of code quality — it works only as a guide, a hint about what's going on.

It's also worth remembering that unit tests are the cheapest way to validate your code. It pays to overdo it a little and write every test you can imagine, even the ones that seem redundant or unlikely.

## Working entirely in the terminal

After I moved my development environment to the cloud, *gocover* could no longer open the browser on my local machine because everything runs on the server. To solve that, I wrote a new version of the function that saves the HTML coverage report to a directory on my web server, so I only have to visit the URL to see what's going on. To remove the report, just press *enter*.

```sh
function gocover() {
    echo "Testing..."
    w="cloud.crg.eti.br"       # web server domain
    f="cover-$$.html"          # cover html file
    t="/tmp/go-cover.$$.tmp"
    root=~/web/root            # web server root
    go test ./... -coverprofile=$t && \
        go tool cover -html=$t -o $root/$f && \
        rm -f $t || \
        return 1
    echo "Open https://$w/$f"
    echo "Press enter to stop"
    read
    rm -f $root/$f
}
```

## Automating even further with *zsh*

If you use *zsh* as your shell, there's a very good way to automate this and many other commands: use the *bindkey* command to create a keyboard shortcut.

```bash
bindkey -s '^X^G' 'gocover\n'
```

That way you just press *^x^g* (*control x followed by control g*) and *gocover* runs for you.
