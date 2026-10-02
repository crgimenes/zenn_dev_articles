---
title: "GoでChrome DevTools Protocolを使ったWebスクレイピング"
emoji: "🕷️"
type: "tech"
topics: ["go", "webscraping", "chromedp", "web"]
published: true
---

I recently needed to extract some information from a website. My plan was simple: find the URL the search form pointed to, make the request directly from my program, then use the [goquery](https://github.com/PuerkitoBio/goquery) package to parse the results and pull out the data I wanted.

Of course it wasn't that easy. The site I wanted to crawl was full of JavaScript that interfered with the form, with the cookies, and with basically everything.

There was no password and no [captcha](https://en.wikipedia.org/wiki/CAPTCHA) — all I had to do was fill in the search form and grab the data. But doing that directly, the way I had planned, was impossible.

So I started looking for ways to do it by simulating a browser. My first idea was to use something like [Selenium](https://www.seleniumhq.org), but I wasn't happy about it at all: that would be one more piece of software to deal with and learn.

While searching, though, I ran into [chromedp](https://github.com/chromedp/chromedp), a [Golang](https://golang.org) package that uses the [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/) with no dependencies other than Chrome itself.

Best of all, it has an API that's easy to use and easy to understand.

Basically, you drive the browser by telling it where to click, which fields to fill in, and when to wait for something to happen — another page loading, for example.

It wouldn't be polite to show the original site that gave me so much trouble here, so I put together an example that goes to the `time` package documentation, runs the `Date` example, waits for the result, and captures only the script's output.

## Chrome DevTools Protocol

The first thing to do is create a context along with a `cancel` function. This matters for shutting Chrome down when the program ends. If you simply abort execution or panic without running the cancel function, you'll end up with several headless Chrome instances hanging around.

At the same time, we can set up a logging function with `chromedp.WithLogf` — any function with the same interface as `Printf` will do.

```golang
ctx, cancel := chromedp.NewContext(
  context.Background(),
  chromedp.WithLogf(log.Printf),
)
defer cancel()
```

Next we pass the context and the actions we want to run in the browser to the `chromedp.Run` function, as in the example below.

```golang
var result string
err := chromedp.Run(ctx,
  chromedp.Navigate(`https://golang.org/pkg/time/#example_Date`),
  chromedp.WaitVisible(`body > footer`),
  chromedp.Click(`
    #example_Date >
      div.expanded >
        div >
          div.buttons >
            button.Button.Button--primary.run`,
    chromedp.NodeVisible),
  chromedp.WaitVisible(`
    #example_Date >
      div.expanded >
        div >
          div.output >
            pre >
              span.system`),
  chromedp.Text(`
    #example_Date >
      div.expanded >
        div >
          div.output >
            pre >
              span.stdout`,
    &result),
  chromedp.Stop(),
)
if err != nil {
  log.Println(err)
  return
}
```

As the last action I told the browser to stop loading any resources with `chromedp.Stop()`. I don't think that's strictly necessary, since the program was about to end anyway, but it seemed like good practice.

After that it was just a matter of handling errors as usual, and reading the output from the `result` variable.

```golang
log.Printf("result %q", result)
```

I put the [source code on gist](https://gist.github.com/crgimenes/b825cec4fb73fb556380564a440f5dce) so you can try it out.

Being able to use bots to browse the internet and automate tasks is pretty interesting. Another neat use is automating web application tests by simulating user behavior. chromedp can even take screenshots, which helps a lot when debugging.

A very useful book for anyone interested in web scraping is [Web Scraping with Python](https://novatec.com.br/livros/web-scraping-com-python/).
