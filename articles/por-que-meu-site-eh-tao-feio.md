---
title: "なぜ私のウェブサイトはこんなに「ダサい」のか"
emoji: "🖥️"
type: "idea"
topics: ["retro", "web", "html", "accessibility"]
published: true
---

## Update

I was recently convinced to try a more modern theme, so I'm experimenting with a new one while keeping the same philosophy of accessibility and simplicity. And, for a change, a light theme. On top of that, I added some JavaScript, as incredible as that may sound.

---

There's always someone asking why my site is so ugly. It has sparked plenty of laughs and usually serves as a hook for good conversations. But since I've been asked about it so many times, it's worth leaving a written answer for anyone who isn't close enough (or shameless enough) to ask me directly.

## Beauty Is in the Eye of the Beholder

The first reason is the most obvious of all: people have different tastes, and to me my site is beautiful. It has its own original theme, with a deliberate terminal look. That's no accident; it's part of my history.

For example, the site's default background color is black, and when you move the cursor over a link, the link's background turns white. The idea is to mimic the reverse-video effect of the menus in programs built for the monochrome terminal.

When I got started in microcomputing, my computer used the TV as a monitor and, of course, it had white lines on a black background. Later, when I got my first real monitor, it was a marvel: it could display 256 shades of gray, not green. I was lucky enough to get a white phosphor monitor.

So there's a strong historical component to my site that, for some people, is as barren as a desert, but for me it harks back to a time when computers were mysterious boxes full of surprises.

## Accessibility

I consider accessibility important. I have friends who use screen readers, and some of them don't get along with the way sites are built today.

One of the things I find bad is how menus are packed with visual items and too many options, so I keep just one menu at the top with the bare minimum of options and a few more links at the bottom of the articles. Everything else is content.

This makes people accustomed to more elaborate navigation find the site strange.

That's the reason I abolished pagination, for example. I think it's better to read the site continuously than to paginate, not to mention that with such a small amount of content pagination is irrelevant anyway.

There's still a lot to be done in terms of accessibility. I implement it gradually with the help of friends and as I discover the problems.

Accessibility has another factor that's usually overlooked, which relates to the available connection and the equipment being used. I'll get to that further below.

## Focus on Content

I don't want the reader to be distracted by anything; no element on the screen should stand out more than the content. And even the content should be straight to the point.

The screen elements, navigation, and so on should be predictable. If you've seen one page, you've seen them all in terms of navigation.

## Portability

The pages are made so they can be saved, so resources usually kept in separate files, like images and CSS, are all embedded directly into the HTML.

## No Trackers

This has nothing to do with beauty, but I don't like trackers and I don't want to impose them through the site. I don't sell advertising and I see no reason to make life easier for those who do. There's nothing worse than visiting a site to read something technical and finding it has more ads than a Formula 1 racing suit.

## No JavaScript

There's simply no good reason to include JavaScript on my site, and if JavaScript is needed for some reason, such as loading a WebAssembly module, I prefer it to be specific to the page that needs it.

Besides, there's older equipment that may not get along so well with JavaScript, and I don't want that to be a limiting factor.

## Size and Download Time

I'd rather my site load as fast as possible than be beautiful. The download should be measured in milliseconds and in kilobytes, not megabytes.

It makes no sense. Sites like CNN, for example, where the first page is over 5 MB. Just imagine: it's as if, only to see a single page, I had to download Microsoft Word 6.0 or download DOOM twice!

The site has to be accessible and work well, loading fast even if your equipment is an old phone on a bad connection.

## Conclusion

I hope I've clarified some of the reasons and encouraged my friends to take a more critical view of load time, accessibility, resources used, and so on.

And of course, if you find anything you think should be improved, give me a shout, especially now that you know what I consider beautiful.

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
