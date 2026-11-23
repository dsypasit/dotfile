# Mermaid: what silently breaks, and how to prove the blocks parse

## Characters that end a statement

| Char | Where it bites | Fix |
| --- | --- | --- |
| `;` | Sequence/figure messages: `A->>B: require x; then y` — the `;` ends the statement and the parser demands an arrow where it finds the newline | split into two messages, or use `,` / `then` |
| `\` | `\d+_+\d`, `\\x28` — backslash escapes are not a label escape | rephrase in words (`digits_underscore_digits`) |
| `#` | starts an entity; `#42`, `#1` become entity refs and can swallow text | write `no. 42` or escape as `#35;` |
| `%%` | starts a comment, truncating the rest of the line | avoid at line start inside labels |

## Labels

- Quote every flowchart node label: `A["POST /api/v1/x (v1)"]`. Unquoted labels break on `(`, `)`,
  `[`, `]`, `{`, `}`, `:`, `;`, `#`, quotes and arrows.
- Rhombus: `A{"decision?"}`. Subroutine/cylinder: `A[("store")]`. Fine when quoted.
- `<br/>` works for line breaks in both flowcharts and sequence messages.
- `end` as a bare node id or an unquoted label can terminate a subgraph; quote it.
- A link to a node id declared later is legal; mermaid is order-independent inside one graph.

## Sequence diagrams

- Message text is everything after the first `:` — colons after that are fine.
- `Note over A,B: text` takes the same treatment: no `;`, no raw `\`.
- Participant aliases cannot contain spaces: `participant G as "GCS"` is what you want to show a
  spaced label.

## Prove it (do not eyeball)

Extract every block and run mermaid's own parser:

```bash
mkdir -p /tmp/mmd && cd /tmp/mmd
python3 - <<'PY'
import glob, os, re
src = "<docs root>"
files = glob.glob(os.path.join(src, "**/*.md"), recursive=True)
n = 0
for p in files:
    t = open(p).read()
    for i, m in enumerate(re.finditer(r"```mermaid\n(.*?)```", t, re.S), 1):
        n += 1
        name = os.path.basename(p)[:-3] + f"-{i}.mmd"
        open(name, "w").write(m.group(1))
print(n, "blocks")
PY
npm i --silent mermaid@11 jsdom@25
cat > check.mjs <<'EOF'
import fs from 'fs';
import { JSDOM } from 'jsdom';
const dom = new JSDOM('<!DOCTYPE html><body></body>', { pretendToBeVisual: true });
global.window = dom.window;
global.document = dom.window.document;
global.HTMLElement = dom.window.HTMLElement;
global.SVGElement = dom.window.SVGElement;
const mermaid = (await import('mermaid')).default;
mermaid.initialize({ startOnLoad: false });
let bad = 0;
for (const f of fs.readdirSync('.').filter((f) => f.endsWith('.mmd')).sort()) {
  try { await mermaid.parse(fs.readFileSync(f, 'utf8')); console.log('OK   ' + f); }
  catch (e) { bad++; console.log('FAIL ' + f + ' :: ' + String(e.message || e).split('\n')[0]); }
}
console.log(bad === 0 ? 'all parsed' : bad + ' failed');
EOF
node check.mjs
```

Notes: do not assign `global.navigator` on Node 24 (`only a getter`); mermaid only needs `window`,
`document` and the two element constructors. Rendered appearance is still a human judgement —
parsing proves the syntax, nothing more. Say "parsed", not "renders correctly".
