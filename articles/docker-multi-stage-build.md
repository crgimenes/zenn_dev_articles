---
title: "マルチステージビルドでコンテナイメージを小さくする"
emoji: "🐳"
type: "tech"
topics: ["docker", "golang", "container", "go"]
published: true
---

Every now and then I run into some huge Docker image where 99% of the size is junk left behind while the image was being built. This is especially bad when we're dealing with Go executables, which are self-contained and usually don't need any external resources, not even libc.

## multi-stage builds

The solution is to use *multi-stage builds*. This way you can have two stages in your Dockerfile: a build stage that downloads whatever is needed, compiles the code, and so on, and another that just copies the executables and resources to their expected locations. This second stage doesn't even need to be based on a distribution; it can be a *scratch* image, which shrinks the final size even further.


### Dockerfile example

This is a small example of a Dockerfile that uses *multi-stage builds* to first create an executable and then build an image that contains only the executable itself and nothing else.

```Dockerfile
FROM golang:latest as build
WORKDIR /build
ADD . .
RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags '-extldflags "-static"' -o app

FROM scratch
COPY --from=build /build/app /app
ENTRYPOINT ["/app"]
```

### Upsides

- Smaller attack surface: there's no extra software sitting around waiting to be exploited, just your executable and nothing else.
- Easier to scale, simply because of how fast a cluster can pull and spin up new instances.

### Downsides

- If you're used to accessing your containers by opening a shell, you won't be able to do that with scratch images. For that you'd need to bring up a distribution, even a lightweight one.
- Debugging can be a bit trickier depending on how your system is designed. If you make a mistake and your executable returns a panic, you need to make sure you're watching the error output.

## Good practice

Using a *multi-stage build* is without a doubt a good practice regardless of the language. It's simple to implement, and the downsides are easily worked around.
