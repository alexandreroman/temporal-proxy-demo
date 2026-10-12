---
name: "Runtime log messages follow one grammar"
description: "Lowercase, no trailing punctuation, constant per call site: two outcome shapes and a present participle for a phase"
type: feedback
---

# Runtime log messages follow one grammar

Every runtime log message in the Go code is a short
phrase that starts with a lowercase letter and
carries no trailing punctuation. Two shapes cover
outcomes, and a present participle reports a phase:

- `<subject> <past-participle>` for something that
  happened — `worker started`, `app stopped`,
  `workflow started`, `hello workflow started`.
- `<gerund ...> failed` for something that did not —
  `rendering the page failed`,
  `writing response failed`,
  `building the keyring failed`.
- a present participle for a phase the process is
  in — `connecting to Temporal`, `shutting down`.

A message that reads as a bare label (`Greeting`) or
as a sentence about the program's intent
(`Failed to serve`, `Starting hello workflow`) does
not belong.

Detail belongs in structured fields, never in the
message: the message is the stable key, and
`"name"`, `"error"`, `"address"`, `"workflow_id"`
carry the values. The message text is therefore
constant per call site — no formatting, no
interpolation.

An uppercase letter is allowed only for a proper
noun mid-phrase (`connecting to Temporal`). A
missing environment variable is reported the same
way as any other detail: `cmd/kms` logs
`required variable not set` with the variable's
name in a field.

The message a binary logs when it stops names the
component, matching the surviving process's
vocabulary: `cmd/kms` logs `kms stopped` where
`cmd/app` logs `app stopped` and `cmd/worker` logs
`worker stopped`. All three carry the error as a
field.

The rule binds runtime logs only. Test assertions
(`t.Fatalf`, `t.Errorf`) and error strings built
with `fmt.Errorf` are out of scope and keep their
own conventions — an `fmt.Errorf` string is a
clause that composes into a wrapped chain, not a
message.

**Why:** log messages are read as a stream during a
live demo, often projected. One grammar makes the
stream scannable, and a constant message per call
site is what makes a line greppable and groupable.

**How to apply:** when adding a log call, pick one
of the shapes above and put every variable part in a
field. To audit the tree:

```sh
grep -rnE '\.(Debug|Info|Warn|Error|Fatal)f?\("[A-Z]' \
  --include='*.go' . | grep -v '_test\.go'
```

Only proper nouns may match.
Checked by hand — `make check` runs `go test` and
`go vet`, not this grep.
