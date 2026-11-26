---
title: "diffとpatchでパッチを作成・適用する"
emoji: "🩹"
type: "tech"
topics: ["git", "unix", "cli", "development"]
published: true
---

These two commands are extremely useful tools for programmers. With them it is easy to send code patches to other programmers without having to send the whole codebase.

## diff

Say you have two text files, an original and a copy of it with some modification.

The diff command looks for differences between two files, or even between two directory trees. The simplest way to use it is like this:

```bash
diff originalFile modifiedFile
```

This command returns the differences between the two files.

To create a patch file, redirect the output of diff as in the example below.

```bash
diff originalFile modifiedFile > file.patch
```

## patch

To apply the patch and change the original file so that it matches the modified one, do as in the example.

```bash
patch originalFile file.patch
```

This command modifies the original file by applying the changes, and the result is identical to the modified file.

These are the most basic ways to use diff and patch. There are many useful parameters to explore in the man page.


## Using git

Git can also generate patch files. Just use the command below.

```bash
git show > file.patch
```

Another option for generating patch files from git is the *diff* command, as in the example below.


```bash
git diff > file.patch
```

It is also possible to patch binary files, which is useful when the repository contains resources such as images.


```bash
git add .
git diff --staged --binary > file.patch
```

As expected, you can apply the patch with git too. Just use the *apply* command, as in the example below.

```bash
git apply file.patch
```

## Conclusion

These days, with everything living in online repositories like GitHub and others, the old diff and patch are less remembered, but they are still useful. Sometimes they are a practical way to move changes around, especially on systems that are kept off the wider network for security reasons.
