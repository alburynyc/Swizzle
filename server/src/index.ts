import Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import { z } from "zod";

// The bartender server behind Swizzle's "Ask the bartender". The app sends the bottles on the
// person's shelf, Claude invents drinks from them, and the app checks every drink against the
// shelf again before showing it. The Anthropic API key lives only here, as a Cloudflare secret.

interface Env {
  ANTHROPIC_API_KEY: string;
  MODEL: string;
  ASK_LIMIT: RateLimit;
}

const Ask = z.object({
  bottles: z.array(z.string().trim().min(1).max(60)).min(1).max(80),
  count: z.number().int().min(1).max(4).default(3),
  // Names of drinks the bartender already invented for this person, so it doesn't repeat itself.
  avoid: z.array(z.string().max(60)).max(24).default([]),
});

const Menu = z.object({
  drinks: z.array(
    z.object({
      name: z.string().describe("A short, elegant name for a new drink, not a well-known classic"),
      glass: z
        .string()
        .describe("One of rocks, highball, collins, coupe, martini, nicknora, margarita, flute, wine, hurricane, snifter, cordial"),
      categories: z.array(z.string()).describe("One or two of: color, fruity, spirit, brunch"),
      colors: z
        .array(z.string())
        .describe("Three or four vivid hex colors such as #C8102E, taken from this drink's own ingredients, most prominent first"),
      ingredients: z
        .array(
          z.object({
            amount: z.string().describe("Such as 1.5 oz, 2 dashes or 1 barspoon"),
            item: z.string().describe("A bottle written exactly as it appears on the shelf, or a pantry item such as Lime juice"),
          }),
        )
        .describe("Two to six ingredients"),
      steps: z
        .array(
          z.object({
            verb: z.string().describe("One short verb in capitals, such as SHAKE, STIR, STRAIN, POUR, TOP, BUILD, MUDDLE or GARNISH"),
            text: z.string().describe("One clear sentence"),
          }),
        )
        .describe("Two to four steps"),
    }),
  ),
});

const SYSTEM = `You are the bartender in Swizzle, a cocktail app. You invent original, balanced cocktails that \
someone can make at home tonight with only the bottles on their shelf plus fridge and pantry items.

Rules:
- Every alcoholic ingredient must be one of the shelf bottles, written exactly as the shelf names it. \
Never add a spirit, liqueur, wine, vermouth, amaro or bitters that isn't on the shelf.
- Anything else must be an everyday fridge or pantry item: citrus juice, simple syrup, honey, agave, sugar, \
soda water, tonic, ginger beer, fruit juice, fresh herbs, fruit, egg white, salt, spices, coffee or tea.
- Don't reproduce well-known classics or their obvious riffs. Vary the styles across the drinks.
- Amounts in US measures (oz, dashes, barspoons). Keep methods short and practical.`;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname !== "/bartender") return json({ error: "Not found" }, 404);
    if (request.method !== "POST") return json({ error: "Use POST" }, 405);

    const device = request.headers.get("x-swizzle-device") ?? request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.ASK_LIMIT.limit({ key: device });
    if (!success) return json({ error: "The bartender needs a minute. Try again shortly." }, 429);

    const ask = Ask.safeParse(await request.json().catch(() => null));
    if (!ask.success) return json({ error: "Bad request" }, 400);
    const { bottles, count, avoid } = ask.data;

    const prompt = [
      `The bottles on my shelf: ${bottles.join(", ")}.`,
      `Invent ${count} original cocktails I can make with them.`,
      avoid.length ? `You've already given me these, so make something different: ${avoid.join(", ")}.` : "",
    ]
      .filter(Boolean)
      .join("\n");

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY, maxRetries: 1, timeout: 50_000 });
    try {
      const message = await client.beta.messages.parse({
        model: env.MODEL,
        max_tokens: 8000,
        system: SYSTEM,
        messages: [{ role: "user", content: prompt }],
        output_config: { effort: "low", format: betaZodOutputFormat(Menu) },
        // If a safety check declines the request, the API retries it on a suitable model by itself.
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
      });
      if (message.stop_reason === "refusal" || !message.parsed_output) {
        return json({ error: "The bartender couldn’t come up with anything. Try again." }, 502);
      }
      return json({ drinks: message.parsed_output.drinks.slice(0, count) });
    } catch (error) {
      if (error instanceof Anthropic.RateLimitError) {
        return json({ error: "The bartender is busy. Try again in a minute." }, 503);
      }
      if (error instanceof Anthropic.AuthenticationError) {
        console.error("The ANTHROPIC_API_KEY secret is missing or wrong.");
        return json({ error: "The bartender isn’t set up yet." }, 503);
      }
      if (error instanceof Anthropic.APIError) {
        console.error("Anthropic API error", error.status, error.message);
        return json({ error: "The bartender couldn’t come up with anything. Try again." }, 502);
      }
      console.error("Bartender failed", error);
      return json({ error: "The bartender couldn’t come up with anything. Try again." }, 502);
    }
  },
} satisfies ExportedHandler<Env>;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}
