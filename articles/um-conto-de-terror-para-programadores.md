---
title: "プログラマーのための怖い話"
emoji: "👻"
type: "idea"
topics: ["retro", "microservices", "development"]
published: true
---

Many years ago there was a very famous Linux [mailing list](https://en.wikipedia.org/wiki/Electronic_mailing_list) where everybody hung out. But those were the early days and things were nowhere near as robust as they are today. Mailing lists were still the main way to exchange information because nobody had a 24/7 connection like we do now: you dialed in, downloaded your email, read everything offline, wrote your replies, dialed in again and sent them. Very rough around the edges, but it worked.

One day a user of that famous list went on vacation and set up his mail server to reply to every message he received with that quaint little note saying he was away and would be back on such and such date, etc.

At this point the old guard already knows what happened…

As the list received messages that day, it forwarded them to everyone, including our guy. His server generated a reply for every message coming from the list, which in turn sent that reply back out to every subscriber, including him. The pile of email grew exponentially until the list server hit its limit — but by then everyone subscribed to the list already had a few thousand messages in their inbox, and back then getting two or three emails a day was a lot. Plenty of people simply couldn't download everything from their account and had to call their [ISP](https://en.wikipedia.org/wiki/Internet_service_provider) to wipe the inbox, deleting important email in the process, sometimes having to do it more than once because it took a while for the flood to stop.

At some point the list started forwarding to everyone the bounce messages coming from accounts with full inboxes, which meant people who were entirely blameless had to be removed from the list just to stop the deluge…

I keep wondering how many people run into the same thing today with one microservice talking to another until the whole thing blows up… or until they rack up a huge bill on some [IaaS](https://en.wikipedia.org/wiki/Cloud_computing#Infrastructure_as_a_service_.28IaaS.29)… scared yet? I am!
