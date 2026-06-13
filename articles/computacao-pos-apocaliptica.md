---
title: "ポストアポカリプス時代のコンピューティングを考える"
emoji: "☢️"
type: "idea"
topics: ["computing", "minimalism", "microcontroller", "embedded"]
published: true
---

Post-apocalyptic computing is a game, an interesting exercise for your imagination. The setup goes like this: something terrible has happened and the society you live in no longer exists. As a survivor, it falls to you to help rebuild modern civilization.

The cause of the apocalypse can be whatever you like: nuclear war, a plague, economic collapse, a solar storm, an oppressive government that wants to keep technology for itself, and so on. The only constant is that nothing you take for granted is available anymore. All the infrastructure is gone. No running water, no electricity, none of the comforts of modern life.

It may sound pointless, but trying to solve problems under heavy constraints forces you to come up with creative solutions. And many of those ideas have practical applications in everyday life, like building systems that are more efficient yet resilient, that draw less power, and so on.

## Computing

If you search online you'll find similar ideas, usually under the name "post-apocalyptic programming." I prefer "computing" because it's a broader term than just programming.

## Challenges

The challenges are many and varied. For example: how to build a small computer that uses very little electricity, how to store and retrieve data efficiently, how to communicate and transfer data, how to keep time and maintain a calendar (essential for agriculture). The list is endless.

There's a huge number of considerations to work through and ideas to explore. For instance, you could [download all of Wikipedia](https://en.wikipedia.org/wiki/Wikipedia:Database_download). But now what? How do you store that data safely so it survives the apocalypse? And after that, how do you query it? You can't count on your beefy computer, it simply burns too much energy. So you have to look for more efficient ways to handle the whole process.

## Simplicity and minimalism

One of the more interesting threads here is cutting away everything that isn't needed to meet the goals of the project. Simple and minimal means fewer things to break, fewer things to go wrong, and ideally a system that one person can understand in its entirety.

## The ideal computer

In conversations with friends, we tried to define what the ideal computer for post-apocalyptic computing would be. We essentially landed on this short set of characteristics:

- It should be portable, as light as possible, ideally under 1 kg.
- Compact, ideally under one liter in volume.
- Easily powered from a low-voltage, low-current source, something like 5V and 500 mAh, so that any hand-crank charger made for phones would do.
- A battery good for at least an hour of use.
- Some storage capacity.
- Programmable on the device itself (you have to be able to write code on it without needing any external equipment).
- Some communication capability, like IR or maybe a low-power radio such as Bluetooth or LoRa.

That would be ideal, but it's hard to find a machine with all of those traits. My attempts to reach that ideal keep pushing me toward microcontrollers, which complicates the software side because of the Harvard architecture. But those very difficulties are what make the game interesting.

## Conclusion

Thinking about post-apocalyptic computing teaches us that, when everything else fails, we can still rely on human creativity to find solutions. And that, very often, less is more, and that simplicity and minimalism are virtues worth cultivating.

Good luck rebuilding civilization!
