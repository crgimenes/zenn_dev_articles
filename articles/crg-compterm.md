---
title: "画面共有に頼らずブラウザでターミナルを配信する Compterm を作った"
emoji: "🖥️"
type: "tech"
topics: ["go", "websocket", "terminal", "lua", "unix"]
published: true
---

I built Compterm to solve a concrete problem from the Go Study Group: showing the terminal live during a class without relying on screen sharing. Screen sharing eats bandwidth, requires specific software on the viewer's side, and almost always feels heavy for people on bad connections.

The fix is simpler than it sounds. Compterm only streams the terminal over the network, and the client is the browser, over WebSocket. Viewers install nothing. The presenter runs a binary.

That ended up covering cases that came later: remote pair programming on poor connections, use on the Atomic Blast BBS, and general demos. BBS support is not decorative nostalgia, it's a design requirement -- working well under limited bandwidth and unpredictable latency forces decisions that most similar projects ignore.

Configuration follows the UNIX pattern: command-line argument, environment variable, and an optional `init.lua` at `~/.config/compterm/`. Precedence is the expected one -- command-line beats env vars, and Lua can override either. I didn't invent a new mechanism.

Build with `make`. In development mode (`make dev`) assets live outside the binary; in production they're embedded.

The repository has the full list of flags, environment variables, and examples.
