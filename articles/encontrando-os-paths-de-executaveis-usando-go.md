---
title: "Goのexec.LookPathでプログラムのパスを見つける"
emoji: "🔍"
type: "tech"
topics: ["go", "cli", "exec"]
published: true
---

I started a new project that needs to check whether certain programs are installed on the system and get their full paths. For that, I used the `exec.LookPath` function from the `os/exec` package.

The `exec.LookPath` function searches for an executable in the directories listed in the `PATH` environment variable. If it doesn't find one, it returns an error. So I created the `programPath` function, which takes the program name and returns the executable's path and a boolean indicating whether the program was found.

```golang
func programPath(name string) (string, bool) {
    s, err := exec.LookPath(name)
    if err != nil {
        return "", false
    }

    return s, true
}
```

Now I can use the `programPath` function to check whether the required programs are installed on the system and get their full paths. The following program shows how this works.

```golang
func main() {
    prgs := []string{
        "lua",
        "rsync",
        "ssh",
    }

    for _, p := range prgs {
        s, ok := programPath(p)
        if ok {
            fmt.Printf("%s: %s\n", p, s)
        }
    }
}
```
[Complete source code](https://crg.eti.br/en/post/encontrando-os-paths-de-executaveis-usando-go/main.go)

This way, I can verify that the programs and dependencies are installed on the system and use the path to call the executables directly. Besides that, using the executable's full path is a good practice to prevent the program from being replaced by another one with the same name in a directory that appears earlier in `PATH`.

Video with the explanation and code execution:

@[youtube](2iLRTIfc1vo)
