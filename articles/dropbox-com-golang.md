---
title: "GoでDropboxのファイルを操作する"
emoji: "☁️"
type: "tech"
topics: ["go", "dropbox", "api", "development"]
published: true
---

I needed a Golang package to talk to Dropbox and perform a few basic operations — listing files, uploading, and downloading. For that I used [dropbox-sdk-go-unofficial](https://github.com/dropbox/dropbox-sdk-go-unofficial).

## Connecting to Dropbox

To connect to Dropbox you need access credentials. The easiest way is to create a token: go to [Dropbox developers apps](https://www.dropbox.com/developers/apps), create an application, and then generate the token from the application's panel.

## Configuring the system

Every function needs the configuration with the access credentials and other useful parameters, such as the log level. So we create a function that returns an instance of the config struct.

```golang
func NewConfig(token string) (config dropbox.Config) {
    config = dropbox.Config{
        Token:    token,
        LogLevel: dropbox.LogOff, // logging level. Default is off
    }
    return
}
```

### Example

```golang
config := NewConfig("token here")
```

## Listing files

To make things easier we create a struct called Node. A node can be a file or a directory — a more common way to look at file systems than the one originally used by the package.

```golang
// Node contains metadata to files and folders
type Node struct {
    IsFolder       bool
    Name           string
    Size           uint64
    Rev            string
    ServerModified time.Time
}
```

To list the root directory, don't send a "/" as you might expect; send an empty string instead.

```golang
func List(config dropbox.Config, path string) (nodes []Node, err error) {
    f := files.New(config)
    lfa := files.NewListFolderArg(path)
    lfr, err := f.ListFolder(lfa)
    if err != nil {
        return
    }
    for _, v := range lfr.Entries {
        var n Node
        switch fm := v.(type) {
        case *files.FileMetadata:
            n = parseFileMetadata(fm)
        case *files.FolderMetadata:
            n = parseFolderMetadata(fm)
        }
        nodes = append(nodes, n)
    }
    return
}
```

### Example

Listing files and directories

```golang
nodes, err := dropbox.List(config, "")
if err != nil {
    log.Fatal(err)
}
for k, v := range nodes {
    fmt.Printf("%v %v\n", k, v.Name)
}
```

## Uploading files

To upload a file you have to give the full destination path, including the root and the file name.

Our function already manages the upload session in order to handle the size limits of a single Dropbox API session, and it also tries to keep memory usage low. In my tests the best result came from sending files in 1 MB chunks, but that may vary depending on network conditions. The maximum chunk size the API allows in a single request is 150 MB.

### Example

```golang
err := dropbox.Upload(config, "source", "/destination")
if err != nil {
    log.Fatal(err)
}
```

## Downloading files

Just like the Upload function, we also have to watch RAM usage during the download, but there's no need to manage sessions — we don't have the same limitations here, so we can use the copy function to copy the data stream coming from the API into the destination file.

```golang
err := dropbox.Download(config, "/source", "destination")
if err != nil {
    log.Fatal(err)
}
```
