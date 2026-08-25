# qrspi

A five-phase workflow — **Q**uestion, **R**esearch, **S**tructure, **P**lan, **I**mplement — for scoping and executing software changes with [Claude Code](https://code.claude.com).

Each phase writes a markdown artifact that the next phase reads, so a change goes from a vague request to a reviewed, executed plan with a clear paper trail at every step.

[![QRSPI walkthrough](https://img.youtube.com/vi/YwZR6tc7qYg/0.jpg)](https://www.youtube.com/watch?v=YwZR6tc7qYg)

## Install

```
/plugin marketplace add wireframe/qrspi
/plugin install qrspi@qrspi
```

## Commands

- **`/qrspi:question <topic>`** — Surface design decisions through structured questioning before any research or implementation. Writes `decisions.md`.
- **`/qrspi:research <plans-folder>`** — Research the codebase based on scoped questions from `/qrspi:question`'s decisions. Writes `research.md`.
- **`/qrspi:structure <plans-folder>`** — Break the work into 3-5 independently testable phases based on research findings. Writes `structure.md`.
- **`/qrspi:plan <plans-folder>`** — Create a detailed implementation plan with bite-sized tasks grouped by structure phases. Writes `plan.md`.
- **`/qrspi:implement <plans-folder>`** — Execute the plan, running a quality gate (`/simplify` + `/code-review`) at every phase boundary. Once the plan is done, drafts a pull request body from the plan's artifacts and offers to open it with `gh pr create`.

Run them in order on a new folder under `docs/plans/YYYY-MM-DD-<topic>/`:

```
/qrspi:question add rate limiting to the API
/qrspi:research docs/plans/2026-01-01-rate-limiting
/qrspi:structure docs/plans/2026-01-01-rate-limiting
/qrspi:plan docs/plans/2026-01-01-rate-limiting
/qrspi:implement docs/plans/2026-01-01-rate-limiting
```

## License

MIT
