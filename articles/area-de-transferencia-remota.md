---
title: "リモートサーバーからローカルのクリップボードへコピーする"
emoji: "📋"
type: "tech"
topics: ["ssh", "neovim", "terminal", "osc52"]
published: true
---

*Tip:* The `pbcopy` command on the Mac is equivalent to `xclip -selection clipboard` on Linux. The `pbpaste` command on the Mac matches `xclip -selection clipboard -o` on Linux. The `xclip` command doesn't work because it requires [X Window](https://en.wikipedia.org/wiki/X_Window_System) installed.

## Copy and Paste

I edit a lot of code on remote servers over SSH, with no graphical interface, usually with [Neovim](https://neovim.io). It would be great to copy and paste between the remote machine and the local one. Pasting from the local machine to the remote one is simple, since the terminal already handles it. Copying from the remote machine to the local one, however, takes a bit of code.

### Using netcat

At first, I thought about using netcat to create a small server that pipes its output to `pbcopy`. That way, I would only need to send data to the server.

To start the "copy service":

```bash
nc -l 9090 | pbcopy
```

To send the text to the server:

```bash
echo "text to be sent" | nc local-machine 9090
```

The problem with this approach is that it isn't very practical and the text is sent over the network unencrypted. A better alternative would be to use SSH directly. However, that requires the local machine to run an SSH server. You can also create an SSH tunnel, but that solution still isn't ideal.

### Using SSH

```bash
echo "text to be sent" | ssh local-machine 'pbcopy'
```

With SSH, you can also grab the text from the local machine's clipboard using the following command:

```bash
ssh local-machine 'pbpaste'
```

Although SSH isn't the best solution, it removes the need to start a service listening on a port. We can wire the command into Neovim's `TextYankPost` event. That way, whenever text is copied, Neovim sends it over SSH.

```vim
augroup remote_clipboard
  au!
  au TextYankPost * call system("ssh local-machine 'pbcopy'", @")
augroup END
```

### Using OSC52

There's a more efficient way to get the same functionality without starting a local SSH server or sending the text over the network unencrypted. For that, we use OSC (Operating System Command), a subset of the ANSI standard escape codes. Modern terminal emulators like iTerm2 can run several OSC sequences, such as displaying links, changing the window title, and, in our case, copying text to the clipboard using code 52. Here's an example:

```bash
echo -ne "]52;c;$(echo -n "text to be sent" | base64)\a"
```

You need to convert the text to base64 before sending it. This can cause a problem: the `base64` utilities on Linux and Mac, by default, wrap the line if the text is too long, which breaks decoding. As a result, the text may be truncated if it's too large.

To solve this, there's a parameter to prevent line wrapping in the `base64` output, but that parameter differs between Linux and Mac. So we need to adjust our script to accommodate the difference.

Here's a version of the script that runs on both Mac (Darwin) and Linux.

```vim
augroup remote_clipboard
    au!
    function Copy()
        if system('uname -s') == "Darwin\n"
            let l:c64 = system("base64 --break=0", @")
        else
            let l:c64 = system("base64 -w0", @")
        endif
        let l:s = "\e]52;c;" . l:c64 . "\x07"
        call chansend(v:stderr, l:s)
    endfunction
    autocmd TextYankPost * call Copy()
augroup END
```

This last version works well, but it makes two calls to the operating system: one to identify the system in use and another to convert to base64. To improve it, I moved the platform detection and the conversion into a separate script and called that script from the `Copy` function in the previous code.

Here's an example of the script that uses the right parameter depending on the operating system.

```bash
#!/bin/zsh

if [[ "${OSTYPE}" == "darwin"* ]]; then
    base64 --break=0 "$@"
elif [[ "${OSTYPE}" == "linux"* ]]; then
    base64 -w0 "$@"
fi
```

I named the script `b64`. It comes in handy in other situations where I need to convert to base64 without wrapping the line.

Here's the final version of the script that lets me, whenever I copy text in Neovim, also have that text available in the local machine's clipboard.

```vim
" Send the copied text to the client's clipboard
" Requires a terminal emulator with OSC52 support
augroup remote_clipboard
    au!
    function Copy()
        let l:c64 = system("b64", @")
        let l:s = "\e]52;c;" . l:c64 . "\x07"
        call chansend(v:stderr, l:s)
    endfunction
    autocmd TextYankPost * call Copy()
augroup END
```

This final solution works really well because I don't have to remember anything: no new keybinding, no new service. It just works. Of course, there are important points to consider, such as needing a terminal emulator compatible with OSC52. In my case, the one I use already supports it, so nothing changes for me.

Also, this solution uses the same SSH connection as the terminal, ensuring the text is sent encrypted.
