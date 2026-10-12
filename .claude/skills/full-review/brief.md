# Task: full code review of Temporal Proxy Demo, with every fix applied

Two modes, set by whoever launched you:

- **Delegated**, when the `cat >` command under "Final signal" targets a
  real file under `/tmp`: you run in a dedicated Casper workspace, a Git
  worktree of `temporal-proxy-demo` on your own branch created from
  `{{BASE}}`, with its own `.env` and its own port. Work autonomously:
  nobody watches this session in real time. Do NOT merge into `main`, do
  NOT push, and do NOT delete the workspace: the user reviews and merges.
- **Foreground**, when that command still shows a placeholder in double
  braces: you run in the user's own checkout, on its current branch, while
  the user follows along. Commit there.

## Scope

The whole repository: `cmd/` (Worker, API, embedded page, KMS server),
`internal/`, their tests, `k8s/` (manifests, chart values, the Kind config
template), `Makefile`, `Dockerfile`, `.dockerignore`, `.env.example`,
`.github/workflows/`, `.casper.json`, `README.md`, `CLAUDE.md` and
`.claude/project-memory/`. Leave `.claude/skills/full-review/` unchanged.

## Rules

1. **Simplify the code as much as possible and delete dead code**: unused
   functions, parameters, variables, files and branches in the Go code;
   unused CSS, Alpine state and markup in `cmd/app/templates/index.html`;
   manifest and values fields that restate a default; Make targets and
   variables nobody uses; and the same in the docs (`README.md`,
   `CLAUDE.md`) and the project memory (stale, duplicated or contradicting
   notes and their `MEMORY.md` lines). This is a demo: every file must be
   explainable on a slide.
2. **Be rigorous about the accuracy of every claim the demo makes**, in the
   README, the page, comments, log messages and the memory. Check each one
   against a primary source: the temporal-proxy repository and docs (see the
   upstream-resources memory note; the source of the pinned version is
   also in the Go module cache, `go list -m -f '{{.Dir}}'
   github.com/temporalio/temporal-proxy`) for what temporal-proxy does and
   how it is configured; the Temporal documentation (context7 or
   docs.temporal.io) for Temporal concepts (Workflows, Activities, Workers,
   Task Queues, Namespaces, payload codecs, API keys); the upstream docs of
   Kind, Helm, Traefik, cert-manager and secretgen-controller for theirs.
   Fix every inaccurate, misleading or over-simplified claim, keeping the
   wording accessible to the demo's audience (see the demo-scope note).
3. **Keep the Go code neutral about its endpoint.** No `temporal-proxy`, no
   proxy vocabulary ("proxy", "gateway", "upstream") in Go comments, log
   messages, errors or identifiers, and no TLS material, credentials or
   fully-qualified Namespace in the client. Run the grep of the
   agnostic-app-code memory note and fix every unexpected match. The page
   (`index.html`) and the deployment files are exempt.
4. **Remove duplication**: logic the Worker, the API and the KMS server
   repeat, helpers duplicated across packages or tests, and configuration
   repeated across `k8s/` directories or between the Makefile and the
   manifests. Merge only where the result stays easier to explain than the
   copies.
5. **Clean up remaining workarounds**: hard-coded values that compensate
   for another bug, sleeps and retries that hide a race, CSS hacks,
   duplicated fixes, `TODO` / `FIXME` / "workaround" comments. Fix the root
   cause, then delete the workaround and any memory note that only
   documents it.
6. **Apply every recommendation** from the review. None is left as a
   "follow-up". If one truly cannot be applied (it would contradict a rule of
   `CLAUDE.md` or a user decision recorded in the project memory), say why
   in the final report. Version bumps are out of scope: report an outdated
   pin, do not change it.

## Constraints

- `CLAUDE.md` and the project memory are the source of truth for the
  conventions: read both in full before starting (`MEMORY.md` and every note
  it links). Line lengths: 80 columns for Markdown, 120 for code.
- **Behaviour stays the same unless a change is intended.** The API answers
  with the same responses, the Workflow and its Activity keep their
  contract, and the page renders the same. Before touching
  `index.html`, render the template to a copy outside the repository and
  screenshot it at 1440x950, as the verifying-a-page-change note describes;
  after each change to it, capture the same view again and compare. Only
  accuracy fixes and deliberate workaround removals may change what the
  page shows; look at those captures and check they are right.
- temporal-proxy is pre-release: re-check its config schema against the
  upstream repository before changing `k8s/charts/temporal-proxy.yaml`, and
  keep its chart version and image tag pinned.
- Follow `CLAUDE.md`: delegate every code change to the
  **skillbox:code-writer** agent; persist and prune memory with the
  **skillbox:project-memory** skill.

## Process

1. Run `make worktree-init` if `k8s/kind-config.yaml` does not exist yet.
   Check that `.env` holds `TEMPORAL_CLOUD_API_KEY` and `KMS_MASTER_SECRET`
   (values not shown). Run `make check` on the base commit and capture the
   reference renders of the page.
2. Review with **skillbox:code-reviewer** agents in parallel, giving each
   one the rules above: one for the Go code and its tests (`cmd/`,
   `internal/`); one for the page (`index.html` and `cmd/app/ui.go`,
   against the page notes of the memory); one for the deployment (`k8s/`,
   `Makefile`, `Dockerfile`, CI, `.casper.json`); one for the accuracy of
   every claim against its primary source; one for duplication across the
   whole repository; one for docs and memory.
3. Merge the findings into one list, then apply all of them, in small
   logical commits (English messages) on this branch.
4. Verify: `make check`, the neutrality grep, the page render comparison,
   then `make app-up` and the end-to-end test of the e2e-means-the-browser
   memory note (a Workflow run from the page in the browser, its greeting,
   Workflow ID and duration rendered with an empty console, a 1440x950
   screenshot). `make demo` is a supporting check, not the end-to-end test.
5. Run a last **skillbox:code-reviewer** pass on the whole branch diff and
   apply what it finds, then verify again.

## Final signal

**Foreground**: report to the user in the conversation, with the content
listed below.

**Delegated** (mandatory): when everything is applied, verified and
committed, write the completion file:

```bash
cat > {{DONE_FILE}} <<'END_OF_REPORT'
DONE
<report: findings per rule and how each was fixed, accuracy corrections
 with their source, lines of code removed, what changed on the page on
 purpose, the end-to-end result, outdated pins, recommendations not
 applied and why, commits>
END_OF_REPORT
```

The first line of the file is `DONE`; the heredoc ends at `END_OF_REPORT`,
so never use that word alone on a line of the report.

Then run `casper notify --message "The full code review is done"`.

If you hit a blocker you cannot resolve on your own (a decision only the
user can make, a missing credential, a broken tool), still write that file,
with `BLOCKED` on its first line followed by the reason, run
`casper notify` and `casper status set blocked`, and ask your question in
this session. Another session waits on that file: never end without
writing it.
