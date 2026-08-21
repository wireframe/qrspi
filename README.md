# qrspi

A five-phase workflow — **Q**uestion, **R**esearch, **S**tructure, **P**lan, **I**mplement — for scoping and executing software changes with [Claude Code](https://code.claude.com).

Each phase writes a markdown artifact that the next phase reads, so a change goes from a vague request to a reviewed, executed plan with a clear paper trail at every step.

## Install

```
/plugin marketplace add wireframe/qrspi
/plugin install qrspi@qrspi
```

## Commands

- **`/question <topic>`** — Surface design decisions through structured questioning before any research or implementation. Writes `decisions.md`.
- **`/research <plans-folder>`** — Research the codebase based on scoped questions from `/question`'s decisions. Writes `research.md`.
- **`/structure <plans-folder>`** — Break the work into 3-5 independently testable phases based on research findings. Writes `structure.md`.
- **`/plan <plans-folder>`** — Create a detailed implementation plan with bite-sized tasks grouped by structure phases. Writes `plan.md`.
- **`/implement <plans-folder>`** — Execute the plan, running a quality gate (`/simplify` + `/code-review`) at every phase boundary.

Run them in order on a new folder under `docs/plans/YYYY-MM-DD-<topic>/`:

```
/question add rate limiting to the API
/research docs/plans/2026-01-01-rate-limiting
/structure docs/plans/2026-01-01-rate-limiting
/plan docs/plans/2026-01-01-rate-limiting
/implement docs/plans/2026-01-01-rate-limiting
```

`skills/code-review/SKILL.md` is vendored verbatim from the author's personal dotfiles so `/implement`'s quality gate works standalone; it doesn't sync automatically if the source changes.

## License

MIT
