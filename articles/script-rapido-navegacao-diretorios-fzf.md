---
title: "fzf で最近使ったディレクトリへ素早く移動するスクリプト"
emoji: "📂"
type: "tech"
topics: ["fzf", "bash", "terminal", "shellscript", "cli"]
published: true
---

This article presents a script to make directory navigation faster, continuing the series on reducing cognitive complexity.

You often need to move between several directories in one or many projects. Remembering paths and locating files becomes an unnecessary effort.

One solution is to keep a list of the most recently visited directories so you can switch between them quickly. Dave Eddy implemented this idea in his [cdstack](https://github.com/bahamas10/bash-cdstack).

Inspired by that approach, I built my own version, better suited to the way I work.

```bash
#!/usr/bin/env bash

CD_STACK_MAX="${CD_STACK_MAX:-15}"
CD_STACK_LAST=""

declare -a _CD_STACK=("$PWD")

_cd_save_env() {
    {
        declare -p _CD_STACK
        declare -p CD_STACK_LAST
    } > ~/.cd_stack_fzf.tmp && \
        mv ~/.cd_stack_fzf.tmp ~/.cd_stack_fzf
}

_cd_load_env() {
    [[ -f ~/.cd_stack_fzf ]] && \
        source ~/.cd_stack_fzf
}

cd() {
    CD_STACK_LAST=${PWD}
    builtin cd "$@" || return "$?"

    _CD_STACK=("$CD_STACK_LAST" "${_CD_STACK[@]}")

    [ "${#_CD_STACK[@]}" -gt "$CD_STACK_MAX" ] && \
        unset '_CD_STACK[-1]'

    _CD_STACK=($(printf "%s\n" "${_CD_STACK[@]}" | \
        awk '!x[$0]++'))

    _cd_save_env
    return 0
}

b() {
    _cd_load_env
    cd "${CD_STACK_LAST}" || return "$?"
    _cd_save_env
}

s() {
    _cd_load_env
    local selected
    local formatted_dirs=()

    for dir in "${_CD_STACK[@]}"; do
        formatted_dirs+=("${dir/#"$HOME"/~}")
    done

    selected=$(printf '%s\n' "${formatted_dirs[@]}" | \
        fzf --prompt=": " \
            --height 40% \
            --layout=reverse)

    [[ -z "$selected" ]] && return 0

    local dir="${selected/#\~/$HOME}"
    cd "$dir" || return "$?"
    return 0
}

_initialize_cd_stack_fzf() {
    _CD_STACK=(
        "/Users/crg"
        "/Users/crg/Projects"
    )
    _cd_load_env
}

_initialize_cd_stack_fzf
```
[Source code](https://crg.eti.br/en/post/script-rapido-navegacao-diretorios-fzf/cd_stack_fzf.sh)

My version uses *fzf* to build a menu, letting you type a few characters to pick the directory you want. By the way, *fzf* is a great tool for creating quick menus in shell scripts.

![A script for fast directory navigation using fzf](https://crg.eti.br/en/post/script-rapido-navegacao-diretorios-fzf/script-rapido-navegacao-diretorios-fzf.webp)

To use the script, save it to a file named *cd_stack_fzf.sh* and load it with the *source* command when your terminal starts.

Once the script is loaded, two new commands become available:

- *s*: opens the menu with the most recently visited directories.
- *b*: returns to the previously visited directory.

You can change the *_CD_STACK* variable to define a preloaded list of directories.

There are many ways to speed up directory navigation, but this script offers an efficient and pleasant solution compared to the other options.

A video demonstrating the script in action:

@[youtube](SjpE7sVgpvI)
