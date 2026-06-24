---
title: "AI支援プログラミングの実践と注意点"
emoji: "🤖"
type: "idea"
topics: ["ai", "go", "copilot", "chatgpt"]
published: true
---

Lately we've seen an explosion in the use of artificial intelligence, with products like ChatGPT, GitHub Copilot, Tabnine, and many others. They're useful and interesting tools, but not nearly as magical as the press makes them out to be.

Think of these tools as a machine that predicts the most likely next word, drops it into the suggestion, and repeats that in a loop until it hits a word count or until the probability of a good guess falls below some acceptable threshold, whichever comes first.

That design causes a few problems. For one, these tools don't handle formal logic well. Ask for something like *build an HTTP mux without using gorilla mux* and it's almost guaranteed to reach for *gorilla mux* anyway. They're also bad at math: the algorithm is built for conversation, not arithmetic.

Even so, I've been using some of these tools since launch, both directly and through their APIs, wiring them into my own projects. Despite the limitations, the results have been pretty good, especially for repetitive work.

## Security

We're still discovering the security problems this kind of tool can introduce. At a minimum, it's about as bad as the telemetry that already ships with various editors.

Basically everything you type is sent off to the service, and they use your code to improve the product and feed the model: what you accepted or rejected, your edits, and all of your code.

So a few old rules apply nicely here:

- Never put real keys in your code, don't commit them, and so on. For work projects it's better not to have access to them at all; leave the access keys with the security team.
- The same care goes for customer data. Always use a mock, never real data.
- Be careful with code that's genuinely confidential. This isn't a concern for me today, since my work is mostly interacting with APIs and there's nothing truly secret in it. The APIs are documented on the internet and anyone can hit them. But earlier in my career I worked on products where the equations were the heart of the business and kept under lock and key.
    - In that case I wouldn't use any AI product. It would be better to write a small library or API without any of these tools, and have the rest of your system simply consume that library.

There's also an effort underway to build security filters that keep sensitive information from leaking.

For now, as long as you take the proper precautions, my view is that the security level is acceptable. Many of my colleagues disagree. It's up to you to decide whether the risk is worth it.

## Reliability of the results

For short snippets and the more predictable parts, the reliability of the suggestions is excellent, though far from perfect. You need to watch closely what's being suggested. The inside joke we came up with is that it's like having a very inexperienced intern who happens to be very enthusiastic.

## The licensing problem

The available AI products were trained on everything developers could get their hands on, including GitHub, Stack Overflow, and so on.

The problem is that no attention was paid to software licenses, so you can accidentally end up with GPL code in your program because the tool suggested the snippet and you have no idea where it came from.

I don't see copying small snippets as a problem, partly because I believe code should never have a license or a patent in the first place. Day to day, nobody worries about copying a snippet from Stack Overflow and using it in their project.

As with the security question, this one is open. It depends on what you believe and what risks you're willing to take.

## Costs

As I write this, GitHub Copilot costs $100 USD/year. In my opinion it paid for itself in the first month; it saved me a lot of time.

The ChatGPT API has a variable cost depending on prompt size and the model you choose. Since the amount can swing quite a bit depending on what you want to build, there's no real way for me to list prices here. That said, in my tests the cost was quite affordable, as long as you don't run a huge volume of tokens.

## Writing good prompts

Writing a good prompt has a big impact on the quality of the AI's response. Here are a few tips.

- The less ambiguity, the better. It sounds obvious, but in conversation we accidentally introduce ambiguities we don't even notice.
- Writing correctly helps. In my tests, taking a little care with grammar and spelling produced slightly better results.
- Try to phrase things positively. "Do this" works better than "don't do that," because the AI doesn't understand formal logic. You may need a few attempts before you get the result you want.
- You can specify what you want back. For example, you can ask for "all code snippets formatted with the markdown Telegram uses," or ask that if the question isn't related to Go it return only the string `---1234---`. Then you can intercept that result and take the right action.
- Keep the prompt size under control. Measuring a prompt is tricky; the number of tokens is roughly 3.5 per English word, and you have a fairly limited token budget. Pass too large a prompt to the OpenAI API and it will simply return an error.

## Disabling GitHub Copilot

It can be useful to disable GitHub Copilot now and then. Sometimes you know exactly what you want to write and don't need help, and the AI suggestions are just a distraction. When that happens it's nice to be able to switch the AI off for a moment. In vim/nvim you can do it with `:Copilot disable` and `:Copilot enable`, or in VS Code you can click the Copilot icon in the bottom-right corner of the screen.

To make this easier and type a little less, I created these two commands that I use in nvim.

```vim
cnoreabbrev dcp Copilot disable
cnoreabbrev ecp Copilot enable
```

## Beyond the editor

Other tools are emerging to help with the rest of a developer's day-to-day work, beyond writing code itself. Some are more interesting than others.

### On the command line

As I write this, GitHub Copilot for the command line is in an experimental phase. I personally didn't like the interface, and the results were below expectations.

### Filling in the commit

It's easy and fun to extend git, so it's no surprise we have several tools to help fill in commit messages.

### Community chat

One of the most fun experiments with the OpenAI API was building a bot for the Telegram channel of the Go study group.

I wanted the bot not to respond to a specific command. Instead, it would read every message, and when it detected that a message was a question, it would answer.

The result was great, but I ran into trouble with prompt size, and as the message volume grew the cost climbed beyond what I was willing to spend on experimentation. I plan to revisit this experiment.

## Do it yourself

People have used AI for a long time, but they forget it as the technology becomes common and expected in everyday life. A spam filter, for instance, is nothing more than a classifier (a Bayes algorithm) trained to tell good emails from bad ones, and you can use the same algorithm to classify anything at all. And that's only the beginning; there's a huge field out there to have fun with.

[Cesar Gimenes](/en/cesar-gimenes/)
