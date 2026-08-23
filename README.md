<div align="center">

<img width="100%" alt="header" src="https://capsule-render.vercel.app/api?type=waving&height=210&text=Redtube%20Bot&fontAlign=50&fontAlignY=36&fontSize=56&desc=Auto%20Spin%20%7C%20Auto%20Tasks%20%7C%20Auto%20Ads%20%7C%20Multi-Account&descAlign=50&descAlignY=58"/>

<img alt="typing" src="https://readme-typing-svg.demolab.com?font=Inter&size=18&duration=3000&pause=650&center=true&vCenter=true&width=900&lines=Auto+Spin+%7C+Claim+Rewards+Until+No+Spins+Left;Auto+Complete+Special+Tasks+%7C+Claim+Points;Auto+Watch+Ads+%7C+Multi-Network+with+Cooldown+Handling;Proxy+Support+%7C+Multi-Account"/>

<p>
  <img alt="ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby&logoColor=white"/>
  <img alt="platform" src="https://img.shields.io/badge/Platform-Redtube%20Miniapp-111111"/>
  <img alt="multi-account" src="https://img.shields.io/badge/Multi--Account-Supported-111111"/>
  <img alt="proxy" src="https://img.shields.io/badge/Proxy-Supported-111111"/>
  <img alt="author" src="https://img.shields.io/badge/by-Yuurisandesu-111111"/>
</p>

<p>
  <b>Redtube Bot</b> is a full automation bot for the Redtube Telegram Miniapp.<br/>
  It handles the complete daily cycle: spinning for rewards until all spins are used, completing all available special tasks to earn points, and watching ads across multiple ad networks with automatic cooldown handling -- all running automatically across multiple accounts with proxy support and a live countdown between cycles.<br/>
  Built and distributed by <b>Yuurisandesu</b>.
</p>

</div>

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Bot](#running-the-bot)
- [Features](#features)
- [File Structure](#file-structure)
- [Disclaimer](#disclaimer)

---

## Requirements

- Ruby `3.2+`
- Bundler

---

## Installation

**Clone the repository:**

```bash
git clone https://github.com/Yuurisan-N1/Redtube-Miniapp.git
cd Redtube-Miniapp
```

**Install dependencies:**

```bash
bundle install
```

---

## Configuration

### 1. Accounts (data.txt)

Fill `data.txt` with Telegram WebApp `initData` for each account, one per line:

```
user=%7B%22id%22...&hash=abc123
user=%7B%22id%22...&hash=def456
```

> `initData` can be obtained from the browser DevTools when opening Redtube on Telegram Web.

### 2. Proxy (proxy.txt)

Fill `proxy.txt` with proxies, one per line (optional, leave empty to run without proxy):

```
host:port
host:port:user:pass
http://user:pass@host:port
```

Proxies are assigned to accounts by index in round-robin order.

### 3. Bot Settings (config.json)

`sleep_seconds` controls how many seconds the bot waits between cycles. If `config.json` is missing, it is created automatically with a default of `3600` seconds.

---

## Running the Bot

```bash
ruby bot.rb
```

Press `Ctrl+C` at any time to stop the bot cleanly.

---

## Features

### Auto Spin
The bot checks the number of available spins for each account. If spins are available, it sends spin requests in a loop until all spins are used. Each spin result logs the reward type, reward amount, and remaining spins. If a spin cooldown is encountered, the bot waits with a live `H:MM:SS` countdown before continuing automatically.

### Auto Tasks
The bot fetches the full list of special tasks and filters for those not yet completed. Each pending task is claimed individually and the reward points and new balance are logged. Tasks already completed are skipped automatically.

### Auto Ads
The bot checks all available ad networks and the watch limit for each. It then claims ad rewards from each network in sequence. For each successful claim, the reward, total watched, and limit are logged. When a network is on cooldown, the bot waits with a live `H:MM:SS` countdown for the shortest active cooldown before retrying. This continues until all networks reach their daily limit.

### Multi Account
All accounts in `data.txt` are processed sequentially within every cycle. Each account authenticates independently and runs its full daily cycle before moving to the next.

### Proxy Support
Proxies are loaded from `proxy.txt` and assigned to accounts by position. Proxy credentials are masked in log output. Running without proxies is fully supported.

### Auto Countdown
After all accounts complete a cycle, the bot displays a live `H:MM:SS` countdown until the next cycle starts.

---

## File Structure

```text
Redtube-Miniapp/
├── bot.rb          # Main bot, full daily cycle automation
├── config.json     # Sleep duration between cycles
├── data.txt        # Account initData, one per line
├── proxy.txt       # Proxy list, one per line (optional)
├── gemfile         # Ruby gem dependencies
├── LICENSE         # License file
└── utils/
    └── banner.rb   # Banner display on startup
```

---

## Disclaimer

This tool is built for educational and technical exploration purposes. Use it wisely and at your own responsibility.

---

<div align="center">
<img width="100%" alt="footer" src="https://capsule-render.vercel.app/api?type=waving&height=120&section=footer"/>
</div>