---
title: "Goのfilepath.Walkでディレクトリツリーをたどる"
emoji: "📂"
type: "tech"
topics: ["go"]
published: true
---

I used to run into the problem of having to type the full path to reach the project directory I wanted to work on. Everything lives under GOPATH and the paths are usually long. Typing the full path once in a while is fine, but I work with [golang](https://golang.org) daily across several projects. Having to type the full path over and over gets tedious. Sometimes I don't even know exactly where the project is, or I forget parts of the path, like the author's name or whether it's on [GitHub](https://github.com/crgimenes) or in some other repository.

You can watch the video for this file [here](https://www.youtube.com/watch?v=NngM6PrKC34).

I used the [Walk](https://golang.org/pkg/path/filepath/#Walk) function from the [path/filepath](https://golang.org/pkg/path/filepath) package. The function is simple and takes two parameters: a string with the root directory to start the search from, and a function that gets called for each file or directory found.

The call to Walk looks like this:

```golang
err = filepath.Walk(root, visit)
```

In this example, `visit` is the function that receives the data for the current item, which can be either a directory or a file.

The function must have the following signature:

```golang
func visit(path string, f os.FileInfo, err error) error {
    ...
    return nil
}
```

The return value varies depending on the behavior you want. Returning *nil*, for instance, makes Walk move on to the next file or directory. Returning *filepath.SkipDir* makes it skip the current directory, meaning Walk won't descend into it. Returning *io.EOF* makes Walk stop and return to the function that called it. You can also return any other value that implements the error interface.
