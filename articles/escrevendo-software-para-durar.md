---
title: "長く生き残るソフトウェアを書くための指針"
emoji: "🏛️"
type: "idea"
topics: ["go", "architecture", "postgresql", "sqlite"]
published: true
---

What follows is a collection of points I believe matter when you want to build software that stays resilient and keeps running for years. They aren't in any particular order, and they're my own opinions, shaped by my experience as a developer.

Treat this as a set of ideas I've gathered over the years. I tried to keep them as general as possible, but I don't pretend they apply to every scenario. They fit best when your team is small and you need to ship fast.

I tried to keep the text general, but many of the points lean toward Go, my favorite language at the moment.

## Focus on simplicity

Write the software in the simplest way you can, with the fewest layers and abstractions. Nothing comes for free: every new layer, every new abstraction, has a price, usually paid in development time, more maintenance, more complexity, and worse, downtime.

The software should do strictly what's needed to fulfill its purpose, and nothing more.

## Keep the stack small

The fewer tools your software needs to run, the better.

For example, it might look easy to solve potential scalability problems with a queue and workers consuming it. But, beyond often being unnecessary, adding a queue means you've introduced several things you didn't have to worry about before. Now you have to deal with network connections, security keys to read from and write to the queue service, and so on.

This doesn't mean you'll never use queues or similar structures, but you need to think hard about whether they're really necessary, because the load of complexity, code, and administrative problems unrelated to programming grows considerably.

### Reduce the attack surface

Keeping the stack small also has strong security implications. Ask any SRE specialist whether they'd rather handle the security of several interconnected services or take care of a small set of services.

## Forget the ghost of scalability

You know that saying about optimization being the root of all evil? Optimizing for scalability without measuring, just because "I think we'll need it," is far more serious. A REST API written in Go, writing to a database like PostgreSQL, both well built, can handle an incredible number of connections per second even on a modest machine with 1GB of RAM and a single core. If the database lives on a separate machine, or better yet is contracted as a SaaS, the load that small server can take is enormous.

It's common to see a system designed with several microservices, queues, an in-memory key/value store, a vault service to centralize the keys for all those services, and so on.

Then you spend a fortune on infrastructure and an enormous amount of time orchestrating all of it. You'll need a security specialist to make sure everything is configured correctly and nothing leaks.

And in the end you serve only a handful of simultaneous connections.

## Prefer the monolith

Monolith, microservices, FaaS, these are just architectural choices. They all have advantages and disadvantages, but if you can, choose the monolith, because communication between the parts of the system is much simpler in a monolith.

The other options involve communication layers that have to be managed, with an impact on security and performance, and we have a strong tendency to underestimate those costs.

I know how tempting it is to have several microservices, each with a single responsibility. But if it's poorly designed, you end up with a "distributed monolith": you keep all the problems of a monolith, except now everything is distributed, and instead of getting the advantages of microservices you're left only with the disadvantages.

When you design service layers, always ask whether the cost of dealing with security, networking, and so on is worth splitting things into separate services, and always be very critical.

For instance, it makes perfect sense for a large company with several products to have a microservice specialized in authentication, queried by all the others, sitting behind a firewall, with load balancing, several redundant instances, and so on.

But that's usually not what we have here in Brazil. What I see most often are small companies and startups with fairly moderate load.

## Split the system by responsibility

A good way to organize the system, and to create independent libraries that can be reused, is to split it by responsibility, with each piece of software having a single responsibility.

This also applies if you decide to build microservices: each one should have a single responsibility. It may sound obvious put this way, but day to day, with demands piling up and the ever-growing pressure to ship faster, it's important not to give in to the temptation to take shortcuts.

Even within a monolith, libraries that accumulate different responsibilities are bad.

## Avoid splitting the team

Splitting the system by responsibility is good, but that doesn't apply to the team. It may not always be possible depending on the size of the company, but it's better to have a single team where everyone shares information quickly.

### Communication

Communication has a big impact on software quality. A lack of communication easily leads to duplicated effort; that's how Windows ended up with six different audio controls. Good communication makes sure everyone understands the company's priorities and the difficulties other developers are facing.

It's fine to have separate teams if the company is big enough, but remember that communication between teams is more expensive than communication between members of the same team. By the way, the product owner, product manager, scrum master, or whatever the title of the person handing demands to the developers, should stay as close to the devs as possible, ideally alongside them all day.

There are ways to ease the communication problem. One that works very well is keeping everyone in the same chat room. Even with people physically apart, you just open the audio and talk. Beyond strengthening the team's bonds, it avoids the "telephone game," avoids pointless meetings, and so on.

I've tried this dynamic at two different companies with great success. You start your day, join the chat room, mute your microphone, and work. If someone calls you, it's the same as calling someone at the desk next to you.

## Prefer boring, battle-tested technology

We tend to want the newest, shiniest technologies. Programmers love novelty and tech. You watch a talk and get itching to drop the new technology into anything.

That's terrible for the resilience of the software you're building. Ideally, every technology you use should be boring, in the sense that it brings no surprises: the programmers know it almost completely, it has been battle-tested countless times, and there's no risk of it being abandoned or taking an unexpected turn in the coming years.

For example, if you grab a good PostgreSQL book from five years ago, it's probably still fully relevant today; a good Bash book easily survives a decade, and a good C book is eternal. And I really hope Go follows the same path.

### Operating system commands

Speaking of Bash, learn to use the operating system's commands well. Often it's better to write a small script and use what already exists than to build it yourself.

### Queues and workers

Better than the whole weight of adding a queue service to your infrastructure is to use the database you're probably already using anyway.

In my case, where the chosen database is PostgreSQL, mainly for historical reasons, I use a combination of `select... for update` and `select... skip locked` to process records safely without record-level lock contention. I also add a simple field to record the current status of the record that needs processing, and that's it.

Another interesting mechanism, especially when you need to consume third-party services to process the record, is to create a field holding the processing history.

A text field where you concatenate things like the result of an API call, errors, and so on. It's quite pleasant to have the error in the same record that caused it.

If processing doesn't need to be fast, it's better to call the worker via `crontab` than to keep it looping, waiting for some record to need processing. The big advantage of using crontab is that your program isn't held in memory all the time; it always starts from a clean state, and you don't run the slightest risk of a memory leak growing to the point of becoming a problem.

### FTS

Instead of using Elasticsearch, both PostgreSQL and SQLite are great for full text search. I recently needed to build a small log server to collect logs from several systems and, most importantly, to retrieve that information easily.

I used SQLite and a small Go server, and the result was very good. A single FTS table receives the records, with one field for the log itself, another to store the date, and another for the name of the system that produced the log.

With this small system it became very simple to search for occurrences and errors and to get a view of the overall state of the system.

## Don't use panic

When programming in Go, handle every error. I know how repetitive it is; sometimes we handle errors that, if they ever happen, mean the operating system itself is in trouble. But I can't count how many times I skipped handling an error that seemed impossible, and of course it happened.

## Don't recover from a panic

Sometimes we write systems that can't go down, and that's the justification for the system recovering from a panic.

But a panic is there to tell you that something went very wrong and needs your attention. Ideally, when a program panics, the right move is to write a test that reproduces the problem and then handle the error.

To keep the system up, use a service manager like [supervisor](https://supervisord.org), for example.

That way, over time, your system becomes more and more resilient.

## Handle the error where it occurs

When I programmed in C++, I disabled try/catch directly in gcc with the `-fno-exceptions` flag. It's always preferable to handle errors where they occur. In Go, for example, never use a function to hide the `if err != nil`. That creates an indirection that makes the code less explicit.

## Never trust the data you receive

It doesn't matter whether it's a REST API or your program's internal functions: never trust the user, even if that user is you in the future. All data must be validated.

### Always validate interface types

When a Go function receives a parameter that is an interface, the compiler itself ensures it's of the correct type. The real problem is when we use an empty interface and then cast to a specific type. If you don't check the type and it isn't what you expect, or it's `nil`, the program will panic.

Besides, internally interfaces are pointers, so they can be `nil`.

### Always check for nil

Whenever you receive a pointer or an interface, check whether it's `nil` before using it or trying to convert it.

A good practice for catching these problems is running linters over the code. [golangci-lint](https://github.com/golangci/golangci-lint) applies several linters that detect these and many other issues.

### Always check the length of arrays

Programmers are usually used to checking the length of arrays in a for loop, but they forget to check the array they receive when they're only interested in the first item.

## Don't break your API

When you build an API, be minimalist. Avoid adding extra features that might seem interesting during implementation, and keep the specification lean. If you overload your API with features, it becomes more costly to make changes and updates to your code in the future.

### Don't keep versions of the same API

Few things are as much work as maintaining two different versions of the same API. But things change, and it's often unavoidable that you'll need to change something that could potentially break the API, forcing you to maintain two (or more) versions. Instead, try to design the API so it can take additions. There's usually no problem adding an extra field to a response, or even adding a new feature, as long as the existing ones keep working and stay tested. The devs (internal and on the client side) will thank you.

## Tests are fundamental

Tests are fundamental, but focus first on testing features, not code.

In compiled languages, test coverage doesn't need to be very high, because the compiler already caught all the syntax errors, oversights, and so on.

In a scripting language, you need to be more rigorous.

Any function with SQL inside it needs to be fully tested. The reason is that even if you're using a compiled language, the SQL code is a little piece of interpreted code inside your compiled program; the compiler has no way of knowing whether that snippet is valid.

## Keep the corporate card topped up

This has nothing to do with programming, but I put it here because I'm sure several senior programmers will laugh when they read it and remember the times they spent hunting for the reason a system went down, only to find out it was because whoever was in charge of the corporate card let it run out of funds.

## References

- [Hidden files in UNIX](https://crg.eti.br/post/arquivos-ocultos-no-unix/)
- [Program design in the UNIX environment](https://crg.eti.br/post/escrevendo-software-para-durar/unix_prog_design.pdf)
- [How Go Programs Keep Working](https://www.youtube.com/watch?v=v24wrd3RwGo)
- [The Only Unbreakable Law](https://www.youtube.com/watch?v=5IUj1EZwpJY)
- [Radical Simplicity in Technology](https://www.radicalsimpli.city)
- [suckless.org](https://suckless.org/philosophy/)
