---
title: "GoでSped Fiscalファイルの読み込みを95%高速化した話"
emoji: "🚀"
type: "tech"
topics: ["go", "performance", "goroutine", "development"]
published: true
---

Last Sunday, Ricardo Gomes from Fix Auditoria and I did some pair programming with one mission: improve the [EFD Fiscal parser](https://github.com/chapzin/parse-efd-fiscal) he's building in Golang.

You can watch the video of this file [here](https://www.youtube.com/watch?v=gnTsHQEVoZE).

Our goal was to squeeze some performance out of the parser and also fix a few small problems in how the files were loaded.

Here's what the system does so far: it reads several text files containing hundreds of thousands of records, parses that content line by line, and finally writes everything to the database.

This task used to take 37 minutes for 36 files with over 50,000 lines each, and now it takes roughly 2 minutes. A 95% performance gain, not bad for a Sunday morning spent talking nonsense and nerding out.

## Here are the changes we made:


The first thing was improving how files were loaded. Initially everything was read into RAM and then processed, which meant a lot of memory was used just to keep a huge pile of data sitting there waiting its turn through the parser. Instead, we made the files be read as they were parsed. We used a reader from Golang's standard [bufio](https://golang.org/pkg/bufio) package with a routine very similar to the example below.

```golang
scanner := bufio.NewScanner(file)
for scanner.Scan() {
    ProcessRows(scanner.Text())
}
```

This way, each file's lines are processed as they're loaded and discarded right after, which helps keep RAM usage under control. Something to always keep in mind: memory and CPU are not infinite, and we have to be careful about how much data we push into RAM at once.

Next, we made the files be processed through goroutines instead of sequentially. That got us some performance, but we had to make a few adjustments so that variables that used to be global would no longer cause conflicts. The solution was to move those variables into structs and create one instance per parser process.

That earned us a bit more performance, but the database wasn't happy about it, because we had a single database connection and every goroutine was trying to insert at the same time, creating a huge bottleneck. The fix was simple: we created one database connection per parser instance. That brought a big performance improvement.

But we were worried about overloading the system, since the project requires reading several hundred files and we didn't want the number of goroutines to grow out of control. So we came up with a simple and fairly primitive way to limit how many parser instances run at the same time. Basically, we used a variable to count the routines: every time a new parser is instantiated the control variable is incremented, and every time a parser finishes its work it decrements the control variable. When that variable hits a maximum limit, we simply let the system wait until the value drops again. We essentially built the simplest possible thread pool, and it's working surprisingly well.

If you're curious, the main changes were made in the [SpedRead.go](https://github.com/chapzin/parse-efd-fiscal/blob/master/SpedRead/SpedRead.go) file.

Sunday's final test ran with 96 files, generating 776,000 MySQL records, and the load time was around 3 minutes.

The system still has a lot of room to grow. Ricardo is now working on the XML parser, which also matters for the audit he wants to run, and that means several hundred more files to parse and load. One of the things we want to do is get the system working with [gofn](https://github.com/nuveo/gofn) so we can process files on demand, without keeping a service running all the time waiting to be used.

There's also still plenty of room for improvements and optimizations. If you're looking for an open source project that handles a large volume of data processing, it might be a good idea to keep an eye on this repository.
