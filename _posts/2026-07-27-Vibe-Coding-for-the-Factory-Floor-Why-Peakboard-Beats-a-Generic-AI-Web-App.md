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

## It runs where the work happens, not in a browser tab

A Peakboard application is executed directly at the worker's workplace, on the Box next to the line or on the tablet in the operator's hand. That is not a cosmetic detail. Because the app runs locally, it can talk to the gear that is physically there - barcode scanners, RFID and NFC readers, foot switches, andon lamps, buttons, label printers, the tablet camera - by adding the device as a data source and dragging it onto the screen. A generated web app can technically reach some of this through WebUSB, WebHID, WebSerial and friends, but each of those comes with browser-version quirks, per-profile permission prompts, exotic devices with no API at all, and drivers that break the next time IT updates the kiosk image. The usual workaround is to write a native helper service that the web app talks to over a local socket, which is exactly the kind of moving part vibe coding was supposed to eliminate.

## Industrial data sources are not REST plus JSON

A generic AI tool, asked to build a dashboard, will reach for what it knows: an HTTP endpoint that returns a tidy JSON document. That mental model is so deeply baked in that almost any prompt about fetching data ends up as `fetch().then(res => res.json())` against a freshly invented schema. The factory floor does not play by those rules. A PLC speaks OPC UA, S7 or Modbus over TCP, hands back binary values from specific data blocks, and expects a long-lived session with subscriptions instead of polling with GET. SAP speaks RFC, with its own connector libraries and nested table structures. An MQTT broker pushes topics with quality-of-service levels, retained messages and last-will payloads that have no analogue in HTTP. None of this fits the request-response shape web tooling assumes by default.

Asking a generic vibe coder to wire that up produces plausible-looking middleware - a Node service importing an OPC UA library it half-understands - that goes silent the first time the PLC restarts, a subscription drops or a switch reboots, in a way nobody on the floor can debug. Peakboard ships these protocols as part of the product: OPC UA, MQTT, SAP RFC, S7, Modbus, SQL, historians and dozens more, with session handling, reconnect logic and type mapping already solved. The AI wires up existing tags instead of writing SDK glue.

## Built to run continuously, not in a tab someone might close

A Peakboard project is built for a runtime that does not get closed. Boxes boot straight into the application, render full-screen with no browser chrome, recover automatically when something goes wrong, and keep running for months at a time. When the network blips - and on a plant floor it will - the local Box keeps rendering the last known state and reconnects transparently when the link comes back. A generic vibe-coded web app inherits the entire browser lifecycle: tabs, automatic updates, extensions, memory leaks, somebody pressing F5 mid-shift, the cloud backend being briefly unreachable and showing a spinner. That model is fine for a colleague who opens the app twice a day on a laptop. It is the wrong model for a screen on a forklift charging bay that has to be readable at 6 AM on a Tuesday after a power blip.

## Production stays on-prem, full stop

The other thing that gets lost in a typical vibe coding demo is where the resulting application actually runs. The generic tools assume a happy path that ends with the app deployed to a public cloud, talking to a public database, behind a public URL. That is fine for an internal tool at a SaaS company. In typical environments where Peakboard is an essential part of the process, that path is a non-starter. A lot of plants do not want any cloud contact from the production facility at all, and the ones who do allow it allow it through tightly controlled gateways with audited rules. A fully cloud-hosted vibe environment that wants to host both the IDE and the running app is simply not going to clear that review. Peakboard runs on a Box on-prem, talks to the local PLC over OPC UA on the local network, and only reaches out when the project explicitly points it at an external API. The vibe coding itself happens in the local Designer, against the local project. Nothing leaves the plant unless the operator decides it should.

## No web stack to maintain

Once a generic vibe coding session ends, the result is not just an app - it is a stack. There is a Node or Next.js runtime, a database the AI invented, a hosting environment, an SSL certificate, an auth layer, secrets to rotate, a CI pipeline to keep green, and an npm dependency tree that needs patching every few weeks. For a single marketing site behind a small ops team, that is acceptable overhead. For a fleet of industrial applications that the plant IT team has to live with, it is a full second job, repeated per screen. Peakboard is a single executable on a Box. Updates are handled by Peakboard, the data connectors are part of the product, there is no bespoke database to back up, no certificate to renew per app, no Node version to upgrade. IT gets one well-known artefact to manage, no matter how many lines, terminals or dashboards the line managers prompt into existence.

## No black box, no lock-in to the prompt history

The other dirty secret of generic vibe coding is what the output actually looks like once we stop squinting at the rendered preview. A pile of generated React components, ad-hoc state management, hand-rolled API routes and a database schema invented on the fly is fine for a throwaway demo or a Mickey-Mouse internal page. It is a maintenance horror story for an application that has to run a production line for the next four years. The only person who can confidently change it is the original author, because the context lives in the prompt history and not in the codebase, and even then the next round of changes tends to introduce just as much new mess as it cleans up. Industrial applications cannot afford that. They get touched by different engineers, they survive personnel changes, and they get adjusted as the line changes. Peakboard's vibe coding sidesteps this entirely because the output is just a regular Peakboard project. Every variable, screen, data source and script that the prompt produces is identical to one a human would have built by hand. Switching between AI-generated and manually designed parts is a non-event - prompt a feature into the project, open the screen, tweak the layout in the Designer, write a script by hand if that is faster, then ask for one more change in natural language. No black box, no architectural surprises, no dependency on whoever happened to write the original prompt.

## One licence, not a per-app cloud bill

The economics of generic vibe coding tend to surface a few months after the demo. Each generated app needs hosting, the database has to live somewhere, the AI service has metered API calls, the auth provider charges per active user, observability is a separate line item, and the bill scales with the number of screens, lines and plants. Peakboard ships under a licence the customer already owns, with the data connectors, the Designer, the runtime and the AI assistance bundled in. A second OEE screen on the same line, a third terminal on the line next door, a fourth dashboard for the morning meeting - none of those add a new monthly invoice. For a company running fifty production screens across three plants, the difference between a flat licence and a per-app cloud subscription stops being a rounding error very quickly.

## Conclusion

Generic vibe coding is brilliant at what it was built for: throwaway web apps that live in a browser tab. Industrial software is a different animal, and Peakboard's vibe coding is built for that animal. The case in seven bullets:

- **It runs at the workplace, not in a browser tab.** Native access to scanners, RFID and NFC readers, foot switches, label printers, andon lamps and the tablet camera - no WebUSB gymnastics, no native helper service to babysit.
- **Industrial data is not REST plus JSON.** OPC UA, MQTT, SAP RFC, S7 and friends bring sessions, subscriptions, binary types and vendor quirks that a generic AI has barely seen. Peakboard speaks all of them out of the box; the AI wires up tags, not REST endpoints.
- **Built to run continuously.** Full-screen on a Box, automatic recovery, last-known-state rendering when the network blips - not the lifecycle of a tab someone might close.
- **On-prem by default.** Designer and runtime both live inside the plant. Nothing leaves the facility unless we explicitly send it.
- **No web stack to maintain.** A single executable on a Box, not a Node runtime plus a database plus a certificate plus an auth provider plus a CI pipeline - per app.
- **The output is a real Peakboard project, not a prompt artefact.** Any engineer can open it in the Designer, tweak a layout, write a script by hand, prompt one more change - and ship. The application survives the next personnel rotation.
- **One licence, not a per-app cloud bill.** New screens and new dashboards do not turn into new monthly invoices.

The short version is even shorter: a beautiful React app in a browser tab is the wrong shape for the factory floor. Peakboard's vibe coding produces the right shape on the first try, and keeps it the right shape years later.
