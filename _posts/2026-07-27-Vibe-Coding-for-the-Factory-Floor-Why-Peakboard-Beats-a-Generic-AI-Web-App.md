---
layout: post
title: Vibe Coding for the Factory Floor - Why Peakboard Beats a Generic AI Web App
date: 2023-03-01 00:00:00 +0200
tags: ai bestpractice
image: /assets/2026-07-27/title.png
image_header: /assets/2026-07-27/title.png
bg_alternative: true
read_more_links:
  - name: The Industrial Vibe Coding Tutorial - Peakboard's New Paradigm in Action
    url: /The-Industrial-Vibe-Coding-Tutorial-Peakboards-New-Paradigm-in-Action.html
  - name: Peakboard 4.3 - Optimized, Refined, and Ready for Scale
    url: /Peakboard-4.3-Optimized-Refined-and-Ready-for-Scale.html
  - name: More articles around AI topics
    url: /category/ai
---
Vibe coding is having a moment. With a single prompt and a coffee break we can now generate a slick web app, a landing page, or a marketing dashboard from tools like v0, Lovable, Bolt or Claude Code. It is genuinely impressive, and for a lot of internal tools the result is good enough to ship the same afternoon. The natural next question is whether we can do the same thing for the kind of applications we build with Peakboard - factory floor terminals, OEE dashboards, kiosks, label printing stations, kitchen displays. The short answer is: yes, and we have already shown that in our [Industrial Vibe Coding Tutorial](/The-Industrial-Vibe-Coding-Tutorial-Peakboards-New-Paradigm-in-Action.html). The longer and more interesting question is whether we should reach for a generic web-app generator or for Peakboard's purpose-built vibe coding, and on that one we have strong opinions.

This article is the case for industrial vibe coding done inside Peakboard, written for engineers who already use Peakboard, and equally for teams who are evaluating whether to point their next shop floor project at a general-purpose AI tool. We will look at where the generic tools shine, where they quietly fall apart, and what Peakboard does differently to make AI-assisted application development actually work in an industrial environment. We will compare what each side ships out of the box: how the generated code is exposed to us, how the application reaches the data sources that already exist on the plant network, how it ends up running on a screen on the line, and what happens when something inevitably needs to change six months later.

The headline is simple: a beautiful React app that lives in someone's browser is the wrong shape for the factory floor. Industrial applications have a different runtime profile, different data sources, different deployment story, different lifecycle and very different non-functional requirements. Building them with a tool that was designed for marketing sites is possible, but it means fighting the tool every step of the way. Building them with a tool that was designed for exactly this purpose feels, well, different.

The rest of the article walks through the concrete arguments. We will fill them in over the coming days.

## It runs where the work happens, not in a browser tab

A Peakboard application is executed directly at the worker's workplace, on the Box next to the line or on the tablet in the operator's hand. That is not a cosmetic detail. Because the app runs locally, it can talk to the gear that is physically there - barcode scanners, RFID and NFC readers, foot switches, andon lamps, buttons, label printers, the tablet camera - by adding the device as a data source and dragging it onto the screen. A generated web app can technically reach some of this through WebUSB, WebHID, WebSerial and friends, but each of those comes with browser-version quirks, per-profile permission prompts, exotic devices with no API at all, and drivers that break the next time IT updates the kiosk image. The usual workaround is to write a native helper service that the web app talks to over a local socket, which is exactly the kind of moving part vibe coding was supposed to eliminate.

## Production stays on-prem, full stop

The other thing that gets lost in a typical vibe coding demo is where the resulting application actually runs. The generic tools assume a happy path that ends with the app deployed to a public cloud, talking to a public database, behind a public URL. That is fine for an internal tool at a SaaS company. In typical environments where Peakboard is an essential part of the process, that path is a non-starter. A lot of plants do not want any cloud contact from the production facility at all, and the ones who do allow it allow it through tightly controlled gateways with audited rules. A fully cloud-hosted vibe environment that wants to host both the IDE and the running app is simply not going to clear that review. Peakboard runs on a Box on-prem, talks to the local PLC over OPC UA on the local network, and only reaches out when the project explicitly points it at an external API. The vibe coding itself happens in the local Designer, against the local project. Nothing leaves the plant unless the operator decides it should.

## No black box, no lock-in to the prompt history

The other dirty secret of generic vibe coding is what the output actually looks like once we stop squinting at the rendered preview. A pile of generated React components, ad-hoc state management, hand-rolled API routes and a database schema invented on the fly is fine for a throwaway demo or a Mickey-Mouse internal page. It is a maintenance horror story for an application that has to run a production line for the next four years. The only person who can confidently change it is the original author, because the context lives in the prompt history and not in the codebase, and even then the next round of changes tends to introduce just as much new mess as it cleans up. Industrial applications cannot afford that. They get touched by different engineers, they survive personnel changes, and they get adjusted as the line changes. Peakboard's vibe coding sidesteps this entirely because the output is just a regular Peakboard project. Every variable, screen, data source and script that the prompt produces is identical to one a human would have built by hand. Switching between AI-generated and manually designed parts is a non-event - prompt a feature into the project, open the screen, tweak the layout in the Designer, write a script by hand if that is faster, then ask for one more change in natural language. No black box, no architectural surprises, no dependency on whoever happened to write the original prompt.

## Conclusion

_To be filled in._
