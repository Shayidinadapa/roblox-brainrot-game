// Brainrot Bay: the entry program (Node 22, standard library only).
// It hands the game in: copies game.rbxl, src/, screenshots/ and PLAY.json
// from this repository into /output, then writes /output/dossier.json with
// the kit's buildDossier library, which is the summary the judge reads.
// Runs twice in the grader; both runs must write the same bytes, so this
// program does nothing time-dependent and copies nothing with a name
// starting with a dot (a .gitkeep or .DS_Store anywhere under /output
// fails the entry).

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const here = fileURLToPath(new URL(".", import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Leave out every file or directory whose name starts with a dot.
const notDotted = (path: string): boolean => !basename(path).startsWith(".");

mkdirSync(out, { recursive: true });
copyFileSync(join(here, "game.rbxl"), join(out, "game.rbxl"));
copyFileSync(join(here, "PLAY.json"), join(out, "PLAY.json"));
cpSync(join(here, "src"), join(out, "src"), { recursive: true, filter: notDotted });
mkdirSync(join(out, "screenshots"), { recursive: true });
if (existsSync(join(here, "screenshots"))) {
	cpSync(join(here, "screenshots"), join(out, "screenshots"), { recursive: true, filter: notDotted });
}
writeFileSync(join(out, "dossier.json"), buildDossier(out, { text_max_bytes: 65536 }));
