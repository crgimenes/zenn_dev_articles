---
title: "UNIXの隠しファイル — バグが仕様になった話"
emoji: "👻"
type: "tech"
topics: ["unix", "retro", "linux", "history"]
published: true
---

Everyone knows how to create a hidden file on UNIX/Linux: just start the filename with a dot (`.`). But this feature wasn't there from the beginning.

According to Rob Pike, in a Google+ post that now survives only on archive.org, the `.` and `..` entries showed up around version 2 of UNIX, while the file system design was still being worked out, as a way to make directory navigation easier. This probably happened in version 2, when the file system became hierarchical.

The problem was that when you listed files with `ls`, those two entries showed up too. So Ken Thompson or Dennis Ritchie added a simple check: if the first byte of the filename was a dot, the program would skip the entry.

That solved the problem of hiding both `.` and `..`, but it also accidentally made *any* file whose name started with a dot disappear from the listing.

It's a classic case of a *bug* that's now a *feature*, and it has caused plenty of trouble over the years, including the pile of hidden files sitting in your home directory, most of which you probably have no idea what they're for.

When you design your own programs, use the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

As far as I could dig up, the very concept of hidden files didn't exist before this point, and it seems its appearance was entirely accidental.

Other operating systems have similar quirks. MS-DOS had an attribute system that let you mark a file as hidden, but it would still show up in tools like File Explorer. If you named the file using ASCII character 255, though, it wouldn't be displayed at all.

## References

[A lesson in shortcuts - Rob Pike - 2012-08-02](https://web.archive.org/web/20180827160401/https://plus.google.com/+RobPikeTheHuman/posts/R58WgWwN9jp)

---

[Cesar Gimenes](/pt-br/cesar-gimenes/)
