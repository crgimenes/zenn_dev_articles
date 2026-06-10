---
title: "アートとしてのプログラミング"
emoji: "🎨"
type: "tech"
topics: ["javascript", "canvas", "generativeart", "art"]
published: true
---

I think of programming computers as a form of artistic expression. There are many ways to solve the everyday problems of programming, which leaves plenty of room for creativity.

## Classic Examples of Generative Art

There are also many fascinating examples of computer-generated art. My favorites are the "one-liners" — programs just a single line long that do something interesting. A famous one is `10 PRINT CHR$ (205.5 + RND (1)); : GOTO 10`, which draws a maze in *BASIC*, and its more modern equivalent `yes 'c=(╱ ╲);printf ${c[RANDOM%2]}'|bash`, written in *Bash*. A quick search online will turn up plenty of implementations in different languages.

## Rediscovering Generative Art

Even though I like the concept, I set generative art aside for a long time, focusing more on the utilitarian side of my code. But recently I decided to give the HTML, CSS, and JavaScript trio another shot, and started writing some code to make my site a little less barren.

### JavaScript and the Evolution of Browsers

The result is that, in a short time, I built several *toy programs* that generate interesting visual effects. I'm using most of them to put something along the sides of the site when the screen is too wide. What I find interesting is how much JavaScript and browsers have evolved. Don't get me wrong — JavaScript is still a terrible language, but it's present on virtually every modern computer and, with a bit of care, you can write reasonably decent code with it.

- *JavaScript is the new BASIC: it's on every computer, it's very easy to start programming in, and nobody likes it (except people who only know JavaScript).*

### Simplicity and Self-Contained Code

I've always tried to limit my code to avoid external dependencies such as third-party libraries or overly complex environments I don't control. Of course, that's often not possible, but it's worth keeping in mind while developing. Keeping things simple makes your life easier down the road.

When it comes to generative art, though, I'm even more radical: the code has to be small, self-contained, and free of any external resources. These constraints serve several purposes, from making the code more challenging to write, to making the piece easy to reproduce and reuse.

### Performance Considerations

You also need to be careful with resource usage. In my early experiments, code that ran perfectly on my machine struggled on more modest ones.

For continuous drawing, I rely heavily on *requestAnimationFrame*, which aims for 60 FPS but stops drawing when the user switches to another tab, for example, saving a lot of resources. It's also important to keep the function called by *requestAnimationFrame* light and fast. Finally, if you're going to replace the drawing function, it's essential to cancel the previous instance with *cancelAnimationFrame* — otherwise your code's performance will quickly degrade.

Trying to keep the code efficient and simple has been an interesting experience. Avoiding extra processing and reallocation has consistently pushed me to pick up new techniques. For instance, in the Matrix-style falling letters effect, to erase the previous letters as new ones appear, it's far more efficient to cover everything with a semi-transparent image in the background color. That way the alpha accumulates and the letters slowly fade until they vanish. This is much more efficient than trying to track the state of every letter and reprocess each one over and over.

## Conclusion

Exploring generative art has been a rewarding journey, letting me combine programming and creativity. Despite the challenges, it's exciting to see what you can achieve with simple, efficient code.
