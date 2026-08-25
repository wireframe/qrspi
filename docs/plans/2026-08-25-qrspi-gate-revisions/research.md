# Research: QRSPI phase-transition gate — inline revisions
Date: 2026-08-25
Decisions: [decisions.md](decisions.md)

## Continue Gate consistency across command files
**Findings:**
- `question.md:68-75`, `research.md:63-70`, `structure.md:61-68`, `plan.md:73-80` each have a section literally titled "Continue Gate" with exactly 3 AskUserQuestion options: Continue to `<next phase>`, "I have revisions", "Stop here for now".
- All four "I have revisions" branches use identical wording: *"ask what to change (free text), apply the changes by editing `<file>` in place (do not ask before saving), re-print the updated `<contents|outline>`, then run this gate again."* — `question.md:73`, `research.md:68`, `structure.md:66`, `plan.md:78`. None mention capturing free text inline in the same question/turn.
- All four "Stop" branches use identical wording: *"acknowledge and end the turn."* — `question.md:74`, `research.md:69`, `structure.md:67`, `plan.md:79`.
- All four "Continue" branches chain automatically into the next command file's `.md`, except `research.md:67`, which alone adds an extra clause: *"If unresolved Open Decisions remain, note them as a caveat in this option's text."* — not present in the other three.
- `implement.md` does **not** follow this pattern. It has no section titled "Continue Gate." Its closest equivalent is the "Prepare Pull Request" step-4 gate (`implement.md:103-109`), with 3 options — "Open the PR now", "I want to edit the body first", "Don't open a PR" — that mirror the Continue/Revise/Stop shape but gate a `gh pr create` call rather than a hand-off to another command file (there is no phase after implement). Its revision branch (`implement.md:106`) uses the same "ask what to change (free text) ... then run this gate again" wording as the other four.
- None of the five files mention any validation or empty/blank-input handling for the revision branch.
- Reference (git provenance): commit `d67faa8` ("Add continue/revise/stop gate to phase transitions, trim inline output", 2026-08-24) introduced this gate across `question.md`, `research.md`, `structure.md`, `plan.md`, `implement.md` in one change, bumping the plugin to 0.3.0.

## AskUserQuestion "Other" free-text capability
**Findings:**
- No file in the plugin directory or this repo documents AskUserQuestion's "Other" behavior — it is not referenced anywhere except in this session's own new `decisions.md`.
- From the tool's own definition (available to this session, not the codebase): every AskUserQuestion question automatically includes an "Other" choice that lets the user type custom text, returned as the answer to that same tool call. This is a fixed, built-in behavior of the tool — options are declared with `label`/`description` fields, but "Other" is added by the host, not by the caller, and its label/description cannot be overridden per-question.
- No alternative mechanism was found (in the plugin, in this repo, or in the tool's own schema) for attaching a custom label or description to a free-text-capable option.

## Blank/trivial "Other" answer handling
**Findings:**
- No existing handling found. A repo-wide search for blank/empty/trivial-input handling on any revision-style question returned nothing in either the plugin directory or this worktree.
- The current revision-branch wording in all five command files (`question.md:73`, `research.md:68`, `structure.md:66`, `plan.md:78`, `implement.md:106`) has no blank-input check — whatever text is given is applied directly.

## Patterns Observed
- The four phase-to-phase gates (`question.md`, `research.md`, `structure.md`, `plan.md`) are near-verbatim templates of each other, differing only in file names and the one extra clause in `research.md`'s Continue option.
- `implement.md` reuses the same 3-option Continue/Revise/Stop shape but relabels it around a terminal action (open a PR) rather than a phase hand-off, and its AskUserQuestion-unavailable fallback phrasing ("yes/no") doesn't match the other four's ("yes/no/revise") — a pre-existing wording drift unrelated to this redesign.

## Constraints Discovered
- **The command files being read and edited live in a plugin cache directory** (`/Users/ryansonnek/.claude/plugins/cache/qrspi/qrspi/0.3.1/commands/`), not in this git worktree, and are not tracked by any git repository at all (the enclosing repo at that path is the user's unrelated `~/.homesick/repos/dotfiles`). There is no git history for these files, and no CHANGELOG/HISTORY file — version tracking for this plugin is by commit message + version bump only (e.g. `d67faa8` bumped to 0.3.0). This means any implementation of this redesign edited directly in the cache directory would not persist across a plugin reinstall/update and wouldn't be reviewable via this repo's git history — the actual QRSPI plugin source repository (wherever it's authored/published from) would need to be located and edited instead. The decisions phase didn't anticipate this.
- **D1's "all gates" scope needs to account for `implement.md`'s structural difference**: it isn't a phase-to-phase Continue Gate and has no "next command file" to chain into, so applying one consistent design to "all QRSPI gates" means either treating `implement.md`'s PR gate as a fourth variant of the same pattern (relabeled) or explicitly scoping it out.
- **D2 is effectively resolved by this research**: since AskUserQuestion's "Other" cannot be given a custom label or description, there is no tool-level way to have a labeled, discoverable option that *also* captures free text in the same call. Option (a) from `decisions.md` (drop the explicit label, rely on "Other") is the only mechanism available for one-turn capture; option (b) (keep a labeled hint) cannot actually route text through that label — selecting it would still require a second, separate free-text step, contradicting the one-turn goal. No third alternative was found.
- **D3's "blank/trivial Other" research focus area found no existing behavior to preserve** — this would be newly designed handling, not a documented gap in current behavior.

## Findings outline
- Continue Gate consistency across command files — 8 findings
- AskUserQuestion "Other" free-text capability — 3 findings
- Blank/trivial "Other" answer handling — 2 findings
- Patterns Observed — 2 entries
- Constraints Discovered — 4 entries
