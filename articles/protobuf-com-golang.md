---
title: "GoではじめるProtocol Buffers入門"
emoji: "📦"
type: "tech"
topics: ["go", "protocolbuffers", "grpc", "rpc"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=XzSgREcg_sU).

This is the first in a series of quick tutorials where I plan to cover [gRPC](https://grpc.io) and various aspects of it, such as testing, TLS, best practices, and much more.

To get started with gRPC we need to go all the way down to the foundation, so let's talk about [Protocol Buffers](https://developers.google.com/protocol-buffers) first.

Protocol Buffers is a simple, language-agnostic way to define a data structure. Think XML, but better, simpler, and faster — much faster.

You can also think of Protocol Buffers as a way to describe how your data is organized so you can use that description to automatically generate code for several languages. The currently supported languages are C++, Go, Java, Python, Ruby, C#, Objective-C, JavaScript, and PHP. Odds are the language of your heart is on that list — mine happen to be the first two :D — but if you look around you will find implementations for languages that are not officially supported, such as Lua. Supporting so many programming languages is possible because the compiler that reads your protocol definition uses a plugin system to decide what code to emit. [Here is a list of third-party plugins](https://github.com/protocolbuffers/protobuf/blob/master/docs/third_party.md)

Besides our own material, there is a lot of good content on the internet explaining how Protocol Buffers works. Be sure to watch, for example, [Francesc Campoy's videos on JustForFunc](https://www.youtube.com/watch?v=_jQ3i_fyqGA)

Now let's look at a simple example of how to save and retrieve structs in a file. This example derives from Francesc's, and the main difference is in how the data is loaded from the file: I prefer to avoid loading everything into RAM and only then parsing the data. Instead, it is better to read the file and parse the data as you go.

To use the protoc compiler with Go, be sure to install the plugin as shown below.

```bash
go get -u github.com/golang/protobuf/protoc-gen-go
```

Not having the plugin for the language you intend to generate code for is the most common failure when working with Protocol Buffers.

Now let's create a very simple .proto file, user.proto

```proto
syntax = "proto3";

package user;

message User {
    int64 ID = 1;
    string email = 2;
    string name = 3;
}
```

The .proto files define the structures/messages serialized by Protocol Buffers. With this file, the protoc compiler can generate code for several languages, and that is the big trick: it is fast because the generated code handles binary data for one specific structure, which makes the parser's job much easier. Other formats such as JSON carry far more processing overhead.

One important detail in the example file is the ID that comes after the equals sign. Since the serialized data is binary, this ID is used to tell the fields apart. You can add new fields in whatever order you want, as long as each one has a different ID.

## Generating code

Now that we have the file defining the format the data will be serialized in, we can use protoc to generate a package containing our struct as Go code.

```bash
protoc --go_out=. user.proto
```

That is the command to generate the code manually, but I prefer to call protoc through go generate. To do that I added the following line.

```golang
//go:generate protoc --go_out=. ./user/user.proto
```

That way we can generate this dependency and any other one by calling `go generate`

```bash
go generate
```

The `user.pb.go` file will be generated containing the `user` package and everything we need to serialize and deserialize it.

## Writing serialized data

With the package generated, let's finally get to our example code.

We have two functions, one to add users and another to list them.

The `add` function first creates an instance of the user struct and fills in the fields.

```golang 
u := &user.User{
    ID:    id,
    Name:  name,
    Email: email,
}
```

Then we serialize this struct to binary

```golang
b, err := proto.Marshal(u)
if err != nil {
    return fmt.Errorf("could not encode task: %v", err)
}
```

At this point the struct is already serialized, which means it can be stored or transmitted, and any language that uses the same .proto file to generate its code would be able to deserialize the data.

In our case we will write it to a file, so let's open a file in append mode, or create an empty file if it does not exist.

```golang
f, err := os.OpenFile(dbPath, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0600)
if err != nil {
    return fmt.Errorf("could not open %s: %v", dbPath, err)
}
```

Now, before writing the struct to the file, we write an integer holding the size of the struct. This is necessary because Protocol Buffers does not include any metadata about the size of the struct, or any information beyond the essentials — that is part of why it is so fast.

So the next part has nothing to do with Protocol Buffers, but it is interesting in its own right. We are going to write the size to the file using `binary.Write`, and that depends on how the integer is laid out in memory, which means dealing with `endianness`. This is the trade-off we make when we want speed: we have to go down to the structure of the platform.

```golang
// add record length to file
if err = binary.Write(f, endianness, length(len(b))); err != nil {
    return fmt.Errorf("could not encode length of message: %v", err)
}
```

Finally, we write the structure itself.

```golang
// add rocord to file
_, err = f.Write(b)
if err != nil {
    return fmt.Errorf("could not write task to file: %v", err)
}
```

And we finish by closing the file.

```golang
err = f.Close()
if err != nil {
    return fmt.Errorf("could not close file %s: %v", dbPath, err)
}
```

## Reading serialized data

The data is now saved on disk in a very simple format: the size of the data followed by the structure's payload, followed by the size of the next record and then its data, and so on until the end of the file.

The first thing we do is open the file for reading.

```golang
f, err := os.Open(dbPath)
if err != nil {
    return fmt.Errorf("could not open file %s: %v", dbPath, err)
}
defer func() {
    e := f.Close()
    if e != nil {
        fmt.Println(e)
    }
}()
```

Then we enter a loop where we read the file, and we only leave it once we have finished reading the file `EOF`

First we read the integer holding the size of the next record. If `binary.Read` returns an error or EOF, we leave the loop.

```golang
// load record file
var l length
err = binary.Read(f, endianness, &l)
if err != nil {
    if err == io.EOF {
        err = nil
        return
    }
    return fmt.Errorf("could not read file %s: %v", dbPath, err)
}
```

Now that we know the size of the struct serialized in the file, we can use `io.ReadFull` to read exactly that many bytes, and for that we create a buffer.

```golang
// load record
bs := make([]byte, l)
_, err = io.ReadFull(f, bs)
if err != nil {
    return fmt.Errorf("could not read file %s: %v", dbPath, err)
}
```

Our buffer now holds the serialized data, and we use that data with `proto.Unmarshal` to fill a new user instance.

```golang
// Unmarshal
var u user.User
err = proto.Unmarshal(bs, &u)
if err != nil {
    return fmt.Errorf("could not read user: %v", err)
}
```

And finally we print the data on screen. We use the getters that protoc generated for us, but they are not required here since Go does not allow NULL strings. If this were a pointer to the user instance, though, those getters would prevent errors by returning empty strings.

```golang
// Print
fmt.Println("id:", u.GetID())
fmt.Println("name:", u.GetName())
fmt.Println("e-mail:", u.GetEmail())
fmt.Println("------------------")
```

Gradually we will alternate between more advanced topics like this one and simpler, more practical ones.

## Useful links

- [Protocol Buffers](https://developers.google.com/protocol-buffers)
- [Our study group repository](https://github.com/crgimenes/grupo-estudos-golang)
