---
title: "サイトの余白をJavaScriptのジェネラティブアートで彩る"
emoji: "🎨"
type: "tech"
topics: ["javascript", "canvas", "generativeart", "art"]
published: true
---

After a long time, I finally added some JavaScript to this site.

I have a huge mental block when it comes to web technologies. JavaScript, CSS, and HTML itself all feel improvised to me, especially the whole idea of the "single page application."

That's a limitation I need to get over. After all, the web is genuinely the best and most portable interface for most programs these days, even if it goes against a lot of what I believe about minimalism and conserving resources.

For now, the JavaScript I added doesn't interfere much with the page. What it does: when the screen is too wide for the page content, the two side strips that used to sit empty now display randomly generated digital art.

The code is written so that if there are no side margins — that is, no space to draw — the script simply ends and doesn't keep eating resources for nothing. So anyone reading the page on a tablet or phone won't notice any difference at all.

The code itself is quite simple: a few helper functions and a drawing function called recursively via `requestAnimationFrame(update);`. That function tries to run at roughly 60 FPS, but most browsers pause the update when the page isn't visible, so we don't waste resources when the user switches to another tab or minimizes the browser.

The drawing function itself is tiny, and for now I only have one effect: a grid similar to GitHub's contribution heatmap. The plan is to gradually add other functions that generate art across all sorts of themes — fractals, mazes, effects, and so on — and then pick one of them at random when the page loads.

The source code lives at [/digitalart.js](/digitalart.js).

## Walking Through the Code

The `createCanvas` function is a helper I call when I need to create the two side canvases. It returns the context I'll use to draw.

```javascript
function createCanvas(width, height, left) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    canvas.style.position = 'fixed';
    canvas.style.top = '0';
    canvas.style[left ? 'left' : 'right'] = '0';
    canvas.style.zIndex = '-1';
    document.body.appendChild(canvas);
    return canvas.getContext('2d');
}
```

The `adjustCanvas` function checks whether there's any room to create the canvases, and if so it creates both and passes the context to the drawing function. Today there's only one drawing function, but eventually there will be several, and at that point this function will randomly pick which one to use.

```javascript
function adjustCanvas() {
    const screenWidth = window.innerWidth;
    const screenHeight = window.innerHeight;
    const contentWidth = 1024;
    const sideWidth = (screenWidth - contentWidth) / 2;

    if (sideWidth > 0) {
        const leftCtx = createCanvas(sideWidth, screenHeight, true);
        const rightCtx = createCanvas(sideWidth, screenHeight, false);

        githubHeatMap(leftCtx, sideWidth, screenHeight);
        githubHeatMap(rightCtx, sideWidth, screenHeight);
    }
}
```

Then the `githubHeatMap` function draws a green grid like GitHub's contribution heatmap.

```javascript
function githubHeatMap(ctx, width, height) {
    const cellWidth = 20;
    const cellHeight = 20;
    const cols = window.innerWidth / cellWidth;
    const rows = window.innerHeight / cellHeight;
    
    function update() {
        const col = Math.floor(Math.random() * cols);
        const row = Math.floor(Math.random() * rows);
        
        const x = col * cellWidth;
        const y = row * cellHeight;

        ctx.beginPath();
        ctx.roundRect(x, y, cellWidth - 2, cellHeight - 2, 3);
        ctx.fillStyle = `rgb(0, ${Math.random() * 255}, 0)`;
        ctx.fill();
        ctx.closePath();

        requestAnimationFrame(update);
    }
    update();
}
```

Finally, at the end of the JavaScript, we have the lines that load the program and react when the screen size changes.

```javascript
document.addEventListener("DOMContentLoaded", adjustCanvas);
window.addEventListener('resize', function() {
    // Remove old canvases before adding new ones
    document.querySelectorAll('canvas').forEach(canvas => canvas.remove());
    adjustCanvas();
});
```

And that's it — a small piece of code to add some generative art to the site and make the experience a little less dry.

I still have a long way to go before I feel comfortable with web development, and I'm in no hurry to get there. But there's clearly no escaping JavaScript, CSS, and HTML. Building a foundation, knowing the technology's pain points, and learning how to work around them is important for any developer.

---

[Cesar Gimenes](/en/cesar-gimenes/)
