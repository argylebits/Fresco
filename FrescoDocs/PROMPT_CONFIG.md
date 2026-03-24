# Fresco — Prompt Configuration

## Overview

The image prompt is a single string set via the `FRESCO_PROMPT` environment variable. This prompt is sent directly to the Gemini Imagen API on each generation.

```bash
FRESCO_PROMPT="A fresco like the ones you'd see in central Texas, tagged with graffiti art that says Fresco. 4:1."
```

---

## Writing good prompts

**Be specific about place and time.** Generic descriptions produce generic images. Named places, specific seasons, particular times of day all push the model toward more grounded results.

```bash
# More specific → better results
FRESCO_PROMPT="The Guadalupe River at noon in July, tubers drifting, cypress shade. Fresco style, 4:1."

# Less specific → more generic
FRESCO_PROMPT="A river scene in summer."
```

**Include style direction.** Tell the model what kind of image you want — fresco, illustration, photography, etc.

**Include aspect ratio.** Add something like `4:1` or `16:9` at the end of the prompt to control the output dimensions.

---

## Verifying your prompt

Check your `FRESCO_PROMPT` value in `.env` to verify it's configured correctly before running `fresco generate`.

---

## Future: subject rotation

A future refinement may add support for a curated list of subjects that rotate daily by date hash, providing meaningful variation without repetition. For now, the single prompt string keeps things simple.
