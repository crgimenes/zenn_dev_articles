---
title: "setuid と setgid：特殊なパーミッションビットを扱う"
emoji: "🔐"
type: "tech"
topics: ["go", "security", "linux", "unix"]
published: true
---

In the article on [Privilege Reduction in Programs](https://crg.eti.br/en/post/reducao-de-privilegios-com-golang/), we used the `sudo` command to run a program with superuser privileges. However, it's possible to do this without an external command.

For that, we use special file permissions known as the *setuid bit* and the *setgid bit*. These attributes allow files to be executed with the **privileges of the owning user or group**.

To set the `setuid` and `setgid` bits, we use the `chmod` command with the `u+s` and `g+s` options, respectively.

```bash
# Change the file owner to root and the group to wheel
sudo chown root:wheel main # On Linux, the group is root

# Set the setuid bit
sudo chmod u+s main

# Set the setgid bit
sudo chmod g+s main
```

When listing the file with `ls -l`, an `s` in place of the `x` indicates that the setuid or setgid bit is enabled. On modern systems, the file name may be highlighted to indicate the bit is active, due to the security implications.

With superuser permissions configured, the program can use the `Setuid` and `Setgid` syscalls to set the user and group IDs without needing the `sudo` command.

```go
// Set the group ID
err = syscall.Setgid(gid)
if err != nil {
    fmt.Println(err)
    return
}

// Set the user ID
err = syscall.Setuid(uid)
if err != nil {
    fmt.Println(err)
    return
}
```

Setting file permissions is more convenient than using the `sudo` command, but it requires care. The setuid and setgid bits are dangerous and can be exploited to gain unauthorized access. An attacker could run commands through your program to obtain privileged access.

A list of dangerous programs that can be exploited with setuid bits is available at [GTFOBins](https://gtfobins.github.io/). The site shows how to exploit a large and surprising collection of common programs.

Video with a detailed explanation:

https://www.youtube.com/watch?v=in5OxDxkWC8
