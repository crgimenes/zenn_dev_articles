---
title: "糸電話で音を使ったデータ通信を試してみた"
emoji: "📞"
type: "tech"
topics: ["go", "security", "audio", "minimodem"]
published: true
---

When I started playing with computers, the only way to load a program into the machine was to type it from scratch. My old computer had no storage; there was no hard drive, floppy disk, or any other way to store data. At startup, the machine loaded *BASIC* straight from ROM and that was it. Eventually I got a tape recorder, but it was terrible. With no money for a recorder made for computers, I used a household one. It took a long time adjusting the volume and other settings before I could load anything. The equipment was so finicky that I taped the controls down to keep them from moving, because the slightest change would prevent loading.

Despite the difficulties, it was interesting to hear the data being transferred to the tape and back. My recorder didn't mute the speaker, so I always had to listen to the shrill sound of the data being transmitted. And I was too young to take the recorder apart and add a switch to cut off the speaker.

With modern computers, that reality is far behind us. Computers are much smarter, but we can still use sound to store and transmit data. That led me to an experiment I had wanted to do for a while: using two plastic cups connected by a string to transmit data between computers, instead of just talking through a *cup telephone*.

Today, Vitória and I spent our Saturday morning putting the experiment into practice. We built the *telephone* with two cups and 13 meters of string, since that's the longest straight-line distance we have at home.

In the first tests, we placed the machines side by side, without the cups and string. The test succeeded because the room was quiet. We got 300 bps without any problems, and I believe we could have reached higher speeds.

In practice, we set up the software as follows. Since I'm on macOS, I started the pulseaudio server to interact with the microphone and speakers.

```bash
pulseaudio --exit-idle-time=-1 --verbose
```

Then we positioned everything and made sure the string was taut and free of obstacles. Next, we set up my machine to receive the message.

We used *[minimodem](http://www.whence.com/minimodem/)*, a program written by Kamal Mostafa, available in many Linux distributions and installable via Brew.

At that distance and without error correction, we reduced the speed to 16 bps. The low speed is due to several noise sources, such as wind on the string and cars passing on the street. Also, we only used the machines' built-in microphones and speakers, with no external peripherals. This is the command to receive the transmission.

```bash
minimodem 16 --rx
```

On Vitória's machine, we set up *minimodem* to transmit. We used the *echo* command to send the message to *minimodem*'s standard input, which modulated the data into audio and transmitted it through the speakers.

```bash
echo só a verdade liberta | minimodem 16 --tx
```

After several attempts and adjustments, we managed to receive the data. It was a fun experiment.

## Room for improvement

- Keeping the string tension constant makes a difference.
- We should have used microphones and speakers mounted near the mouth of the cups, but I didn't want to overcomplicate the fun.
- The cup size, material, and string diameter affect the result, but everything had to be done with what we had at home.
- Running the experiment in a quieter place with less wind would have helped.

The next interesting idea would be to load a program directly from a tape recorder, like I did back in the *TK85* days (a Brazilian clone of the *ZX Spectrum*); the problem is finding a tape recorder that doesn't cost a fortune.

Video demonstrating the experiment:

@[youtube](YGYx1DNLqNk)

Until next time!

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
