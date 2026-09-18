---
title: "画像とCSSをHTMLに埋め込んでサイトを高速化する"
emoji: "⚡"
type: "tech"
topics: ["hugo", "html", "css", "webperformance"]
published: true
---

To share my articles over [IPFS](https://ipfs.io), it made sense to embed the CSS and images directly into the HTML so that there would be a single file to share.

Embedding the CSS was the simplest part: I just placed the CSS directly into the site template using the `<style></style>` *tag*, and embedding the CSS alone already produced a nice speed gain.

I use [HUGO](https://gohugo.io) as the *framework* to generate the site automatically. HUGO works by converting pages written in *Markdown*, but the same idea applies no matter how the site is built, even if it is written by hand, directly in HTML. With HUGO and a bit of programming, though, it was easy to automate my template and have the images converted to *Base64* and inserted into the page automatically.

```go-html-template {linenos=inline,hl_lines=[16]}
{{- if strings.HasPrefix .Destination "http" -}}
    <img
        src="{{ .Destination | safeURL }}"
        alt="{{ .Text }}"
        {{ with .Title }}title="{{ . }}"{{ end }}
    />
{{- else -}}
    {{ $file := index (split .Destination "#") 0 }}
    {{ $class := index (split .Destination "#") 1 }}
    {{ $class = $class | default "floatleft" }}
    {{ $mime := "jpeg" }}
    {{- if eq (path.Ext $file) ".webp" }}{{ $mime = "webp" }}{{ end -}}
    {{- if eq (path.Ext $file) ".png" }}{{ $mime = "png" }}{{ end -}}
    {{- if eq (path.Ext $file) ".gif" }}{{ $mime = "gif" }}{{ end -}}
    {{- if eq (path.Ext $file) ".svg" }}{{ $mime = "svg+xml" }} {{ end -}}
    <img
        src="data:image/{{ $mime }};base64,{{ readFile $file | base64Encode }}"
        alt="{{ .Text }}"
        title="{{ .Title }}"
        {{ with imageConfig ( printf "%s" $file ) }}
            width={{ .Width }}
            height="{{ .Height }}"
        {{ end }}
    />
{{- end -}}
```

With the images in the HTML as well, the site ended up much faster. The reason is that everything happens over a single connection, and the increase in the HTML size does not have much impact since the traffic is compressed.

Since the result was so good, only one file was left to embed into the HTML to make each page require just a single HTTP request: the *favicon*. The good news is that modern browsers allow the favicon to be in [SVG](https://developer.mozilla.org/en-US/docs/Web/SVG) format, which makes it very simple to embed as text in the HTML and removes the need to keep several versions of the image for each size.

```html
<link rel="icon"
    sizes="any"
    type="image/svg+xml"
    href="data:image/svg+xml;utf8,<svg xmlns=...</svg>"
/>
```

The time savings will vary depending on the site's content, the resources it needs to load, external connections, and so on. In my case it is simple, because I rarely use images and never use JavaScript, so the site already loaded fast by nature. The times between the start of the request and the page being fully rendered are running between 300 and 450 milliseconds.

If you try this idea on your own site, remember to collect the timings and compare them to know whether there was an improvement or not. After all, *engineering without numbers is just opinion*.

As a side effect, keeping all the resources of each article self-contained had other interesting benefits. Saving the page for *off-line* reading, archiving it on [archive.org](https://archive.org), and even using the page in integration *scripts* all became simpler, because I do not have to worry about following *links* — everything is in a single file with a predictable format.
