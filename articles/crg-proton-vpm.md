---
title: "macOSでVPNを使う"
emoji: "🔒"
type: "tech"
topics: ["networking", "macos", "vpn"]
published: true
---

Like any tool, a [VPN](https://en.wikipedia.org/wiki/Virtual_private_network) is only effective if you know exactly which problem you want to solve with it. Some people want to keep their internet traffic anonymous, others want to protect their data, and so on. My own use is very specific: some internet providers are blocking important ports I need to reach certain services. For example, a well-known provider here in São Paulo is blocking TCP port 22, the one we use for SSH. Note that this is not the provider blocking incoming connections, which was already common, but outgoing ones — meaning that using any service that depends on SSH, like [GitHub](https://github.com/crgimenes), or reaching a machine hosted on Google Cloud Platform's Compute Engine becomes impossible.

To get those ports back, the provider wants you to buy a much more expensive business plan. It is literally creating a problem in order to sell a solution, and a VPN ends up being a better and cheaper alternative.

On top of that, this same provider is using the router installed in customers' homes to feed its own Wi-Fi network, which is extremely worrying — not to mention that it is using my electricity for free, but that's a topic for another day.

So my use for a VPN is to cross that first mile: out of my internal network, which sits behind my firewall, through the provider's router/modem, past god knows what else along the way, until it reaches an exit server somewhere on the internet.

Your VPN needs are very likely quite different from mine, so you should do your homework: study every characteristic of the VPN provider you pick and check whether it fits what you actually want.

Right now I'm using ProtonVPN for this, for two main reasons: I have friends who use it and speak well of the service, and both they and I tested the free version for a good while. But those are the things that matter to me. For other people it might be, say, the company being headquartered outside the US, the number of nodes spread around the world, and so on. Again, you have to look at what is important for your own needs.

## Free version

The free version of ProtonVPN was a pleasant surprise — it's perfectly usable. I've spent whole days connected without any major issues. Of course speed drops, but for work it's fine. I haven't tested it for gaming or streaming shows, at most maybe videos on [YouTube](https://www.youtube.com/@crgimenes).

## Confusing shopping sites

Shopping sites, location-based searches, and online ads get pretty confused depending on what you do. For instance, right now I'm getting ads from Australia on YouTube because that's where my exit server is. Try not to switch countries in the middle of an online purchase.

## Their own client

ProtonVPN provides its own client to manage connections, which is nice for making things easier if you'd rather not deal with it. But I like the idea of configuring my own environment. As a client on macOS I use Tunnelblick, which is a great OpenVPN client.

## Setting up the free version

First, go to the ProtonVPN site and create a free account. You'll need your login credentials to access the servers, so pick a great password you haven't used anywhere else — remember, longer passwords are better.

Then go to `Downloads`, then `Server Configs`, open the countries you find interesting, and download the free servers. It's a bit tedious to open each country's tab looking for free servers, but it's a one-time thing.

Now simply drag the ".ovpn" files onto the panel on the left side of the Tunnelblick window.

When you click connect, the system will ask for the password. You'll need to enter it once for each file, but you can choose to save the password in the macOS Keychain. That's useful for me because I use some scripts and they don't work if a password prompt shows up.

You can also rename the connection to something simpler, but in my case I'm keeping the original names. The downside is that sometimes I need to quote them so the name doesn't get in the way of AppleScript.

If everything worked so far, you have the free version up and running. Needless to say, I have no affiliation with the company — I'm just describing my own experience. And I'm also not responsible for anything you break on your own system.

## Automating the connection

Sometimes I need to automate the connection, and for that I usually use AppleScript. It's not my favorite scripting language, but since Tunnelblick supports it natively it's simply convenient. Here's an example of connecting via AppleScript:

```bash
tell application "Tunnelblick"
    connect "us-free-01.protonvpn.com.tcp443"
end tell
```

To make sure the VPN came up, I usually check whether the machine's IP changed. For that you just need a service like [SeeIP](https://seeip.org) or [ipify](https://www.ipify.org)

```bash
curl 'https://api.ipify.org?format=json'
```

That's good for automation, though Tunnelblick itself will warn you if the IP doesn't change.

## Other free VPN providers

The Tunnelblick site has a [list of VPN providers that donated to the project, some of them free](https://tunnelblick.net/cGettingVPNService.html) — worth a look.
