---
title: "psで親プロセスをたどってシェルの起動元を判定する"
emoji: "🐚"
type: "tech"
topics: ["zsh", "bash", "shell", "unix"]
published: true
---

When I started using [compterm](https://github.com/crgimenes/compterm), a problem showed up quickly: sometimes I forgot that compterm was already running. So I wrote a small function to detect whether I was inside a session launched by compterm or just a regular zsh session.

```bash
function is_parent_compterm {
    local pid=$$
    local parent_pid

    while [ "$pid" -ne 1 ]; do
        parent_pid=$(ps -p $pid -o ppid=)
        parent_pid=${parent_pid//[[:blank:]]/}  # Remove espaços

        # Verifica se o nome do comando do processo pai é 'compterm'
        if ps -p $parent_pid -o comm= | grep -q "^compterm$"; then
            return 0  # Retorna true se encontrar 'compterm'
        fi

        pid=$parent_pid
    done

    return 1  # Retorna false se 'compterm' não for encontrado
}
```

The function walks up through all of the current process's parents, and if any of them is named `compterm` it returns true. That lets me customize the prompt and know at a glance whether compterm is running.

```bash
if is_parent_compterm; then
    PS1="%F{yellow}compterm%f%F{green}>%f "
fi
```

The newer version of compterm doesn't need anything this elaborate. When it starts, it sets an environment variable holding the process PID, so checking whether the shell session was launched by compterm becomes trivial.

```bash
if [[ -v COMPTERM ]]; then
    PS1="%F{yellow}compterm%f%F{green}>%f "
fi
```

The same idea works in other scripts to find out, for example, whether you're running under [tmux](https://github.com/tmux/tmux) or not.

---

[Cesar Gimenes](/pt-br/cesar-gimenes/)
