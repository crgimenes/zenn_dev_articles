---
title: "Goのsingleflightで重複呼び出しをまとめる"
emoji: "🛫"
type: "tech"
topics: ["go", "singleflight", "concurrency", "goroutine"]
published: true
---

You have an expensive, heavy function. During a traffic spike, six requests arrive at the same time asking for exactly the same thing. With no precautions, you run that function six times to get six identical results.

**singleflight** is a pattern that collapses those calls. The first call for a key does the real work. Every other call that arrives *while it's in progress* waits and gets the same result. One execution, many consumers.

And here's the part that trips a lot of people up: **singleflight is not a cache**. It doesn't keep anything for later. As soon as the call finishes, the entry is removed. It only merges calls that are *in flight at the same time*. Hence the name, "single flight".

This is a minimal version meant to show the mechanism. The heart of it is a struct that represents a call in progress:

```golang
type call struct {
	done chan struct{}
	val  string
	err  error
}

type Group struct {
	mu    sync.Mutex
	calls map[string]*call
}
```

The `Group` holds a map of the calls happening right now, indexed by key. The `call` has a `done` channel that is the central trick: whoever arrives later blocks reading from that channel until it's closed.

All the logic lives in the `Do` method:

```golang
func (g *Group) Do(key string, fn func() (string, error)) (string, bool, error) {
	g.mu.Lock()

	if g.calls == nil {
		g.calls = make(map[string]*call)
	}

	if c, ok := g.calls[key]; ok {
		g.mu.Unlock()

		<-c.done
		return c.val, true, c.err
	}

	c := &call{
		done: make(chan struct{}),
	}

	g.calls[key] = c
	g.mu.Unlock()

	c.val, c.err = fn()

	close(c.done)

	g.mu.Lock()
	delete(g.calls, key)
	g.mu.Unlock()

	return c.val, false, c.err
}
```

Holding the lock, `Do` checks whether there's already a call in progress for that key. If there is, it releases the lock, waits for the `done` channel to close with `<-c.done`, and returns the result the other goroutine produced.

The second return value is a `bool` that says whether the result was shared, useful for knowing whether you were the "leader" or a "free rider".

If there's no call for that key, this goroutine becomes the leader: it creates the `call`, registers it in the map, **releases the lock**, and only then runs `fn()`. Releasing the lock before running is the key move. That's what lets the free riders come in and queue up to wait while the leader works.

If you held the lock during the expensive call, no free rider could even see that there's already a call in flight, and the whole benefit would go down the drain. When the work finishes, the channel is closed with `close(c.done)` (which releases everyone who was waiting all at once) and the entry is removed from the map.

To test it, a fake expensive function that just sleeps 300ms and counts how many times it actually got called:

```golang
var expensiveCalls atomic.Int64

func expensiveFunc() (string, error) {
	n := expensiveCalls.Add(1)

	time.Sleep(300 * time.Millisecond)

	return fmt.Sprintf("result from expensive call #%d", n), nil
}
```

In `main`, six goroutines fire off asking for the same key at the same time:

```golang
func main() {
	var g Group

	var wg sync.WaitGroup

	// Start 6 goroutines that call the same key at the same time.
	for i := range 6 {
		wg.Add(1)

		go func(id int) {
			defer wg.Done()

			val, shared, err := g.Do("same-key", expensiveFunc)
			if err != nil {
				fmt.Printf("worker=%d error=%v\n", id, err)
				return
			}

			fmt.Printf("worker=%d shared=%v value=%q\n", id, shared, val)
		}(i)
	}

	wg.Wait()

	fmt.Printf("expensive calls: %d\n", expensiveCalls.Load())
```

Running it:

```bash
worker=1 shared=false value="result from expensive call #1"
worker=2 shared=true value="result from expensive call #1"
worker=0 shared=true value="result from expensive call #1"
worker=5 shared=true value="result from expensive call #1"
worker=3 shared=true value="result from expensive call #1"
worker=4 shared=true value="result from expensive call #1"
expensive calls: 1
```

Six workers, but the expensive function ran **only once**. `worker=1` was the leader (`shared=false`) and the other five rode along on the same result (`shared=true`). Notice that the order of the workers in the output changes every run, that's the goroutine scheduler doing whatever it wants. Which one becomes the leader varies too.

Now, to make it clear that this *is not a cache*, at the end of `main` the same key is called again, after the first batch has already finished:

```golang
	val, shared, err := g.Do("same-key", expensiveFunc)
	if err != nil {
		fmt.Printf("worker=%d error=%v\n", 0, err)
		return
	}

	fmt.Printf("worker=%d shared=%v value=%q\n", 0, shared, val)

	fmt.Printf("expensive calls: %d\n", expensiveCalls.Load())
}
```

And the output:

```bash
worker=0 shared=false value="result from expensive call #2"
expensive calls: 2
```

Since there was no one else in flight, this call became the leader again (`shared=false`) and the expensive function ran for the second time. No result was kept.

One detail my minimal version ignores: if the expensive function panics or hangs forever, all the free riders hang with it, stuck on `<-c.done`. A single point of failure that hits everyone who rode along. Go's official implementation handles this.

That official implementation lives in [`golang.org/x/sync/singleflight`](https://pkg.go.dev/golang.org/x/sync/singleflight), with `panic` handling, cancellation propagation, and a `DoChan` method that returns a channel instead of blocking. In production, use theirs. But writing the minimal version is what made me understand why the thing works. In the end, it's a map, a mutex, and a channel.

[Full source code](https://crg.eti.br/post/singleflight/main.go)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
