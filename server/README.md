# Swizzle bartender server

A small Cloudflare Worker that answers the app's **Ask the bartender**. The app sends the bottles on
the shelf, the server asks Claude for three new drinks, and the app checks each drink against the
shelf before showing it. The Anthropic API key is stored only in Cloudflare, never in the app or
this repo.

## What you need

- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com) (API Keys → Create Key),
  with some credit and a monthly **spend limit** set under Limits.
- A free Cloudflare account at [dash.cloudflare.com](https://dash.cloudflare.com).
- Node.js (the LTS version from [nodejs.org](https://nodejs.org)). Check with `node -v` in Terminal.

## Put it live

In Terminal, from the repo folder:

```sh
cd server
npm install
npx wrangler login                        # opens your browser to connect Cloudflare
npx wrangler secret put ANTHROPIC_API_KEY # paste the key when it asks; it goes straight to Cloudflare
npm run deploy                            # prints the server's address
```

`npm run deploy` ends with an address like `https://swizzle-bartender.yourname.workers.dev`. The
first time, Cloudflare may ask you to pick a `workers.dev` subdomain; any name works.

Paste that address into `Swizzle/App/Config.swift`:

```swift
static let bartenderServer = "https://swizzle-bartender.yourname.workers.dev"
```

Then run the app again from Xcode. The For You card now asks Claude.

## Check it from Terminal

```sh
curl -X POST https://swizzle-bartender.yourname.workers.dev/bartender \
  -H 'content-type: application/json' \
  -d '{"bottles":["Tanqueray London Dry Gin","Campari","Cointreau"]}'
```

You should get back three drinks as JSON. `npx wrangler tail` shows the server's log live while you
use the app.

## Cost and limits

- The model is set by `MODEL` in `wrangler.jsonc` (Claude Opus 5.5 to start, at low effort for speed).
  Each ask costs a few cents. To change models, edit that line and run `npm run deploy` again.
- Each phone can ask at most 6 times a minute (`ratelimits` in `wrangler.jsonc`).
- In the app, free accounts get 3 asks a day and Premium is unlimited (`AppStore.freeAsksPerDay`).
- The spend limit you set in the Anthropic console is the hard cap on the bill.

## Change a setting or the key

- New key: run `npx wrangler secret put ANTHROPIC_API_KEY` again.
- Try changes locally: copy `.dev.vars.example` to `.dev.vars`, add your key, and run `npm run dev`.
  `.dev.vars` is ignored by git.
- `npm run check` type-checks the code.
