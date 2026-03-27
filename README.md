# deploytarot-action

> Should I deploy today? Let the cards decide.

A GitHub Action that consults [Deploy Tarot](https://deploytarot.com) before your workflow proceeds. Three cards from the Major Arcana. One verdict. Zero accountability.

---

## Usage

### Zero config

Drop it in. Role and intent are auto-detected from the workflow event and the actor who triggered it.

```yaml
- uses: rembish/deploytarot-action@v1.2
```

The action posts a colored verdict banner directly on the run page and a full card reading to the job summary — no clicking required.

### With explicit role and intent

```yaml
- uses: rembish/deploytarot-action@v1.2
  with:
    role: senior-dev
    intent: db-migration
```

### Block deploys on a bad reading

```yaml
- uses: rembish/deploytarot-action@v1.2
  with:
    fail_on_abort: "true"
```

The step exits with a non-zero code if the verdict is **Abort Mission**, blocking any subsequent steps.

### Use the verdict downstream

```yaml
- uses: rembish/deploytarot-action@v1.2
  id: tarot

- name: Deploy
  if: steps.tarot.outputs.verdict != 'abort-mission'
  run: ./deploy.sh
```

---

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `role` | No | auto-detect | Your role. See [valid values](https://deploytarot.com/api#valid-roles). Bot actors are automatically recognised as `ai-agent`. |
| `intent` | No | auto-detect | What you are deploying. See [valid values](https://deploytarot.com/api#valid-intents). |
| `fail_on_abort` | No | `false` | Exit with a non-zero code when the verdict is Abort Mission. |

## Outputs

| Output | Description |
|---|---|
| `verdict` | Machine-readable verdict: `ship-it`, `tread-carefully`, or `abort-mission`. |
| `verdict_label` | Human-readable verdict label, e.g. `Ship It 🚀`. |

---

## Auto-detection

### Role

The action inspects `github.actor`. No configuration needed.

| Actor | Detected role |
|---|---|
| Any actor ending in `[bot]` (dependabot, renovate, copilot, …) | `ai-agent` |
| `github-actions` | `ai-agent` |
| Any human | `devops` |

Set `role` explicitly to override.

### Intent

The action inspects the workflow event and branch name.

| Event / condition | Detected intent |
|---|---|
| `release` published | `full-release` |
| `push` to `main` / `master` / tag | `full-release` |
| PR · branch `fix/*` or `hotfix/*` | `hotfix-prod` |
| PR · branch `feat/*` or `feature/*` | `new-feature` |
| PR · branch `refactor/*` or `chore/*` | `refactor` |
| PR · branch `db/*` or `migration/*` | `db-migration` |
| PR · branch `infra/*` or `ops/*` | `infra-change` |
| PR · branch `docs/*` | `public-doc-release` |
| PR · branch `security/*` | `security-patch` |
| Dependabot / Renovate PR | `dependency-update` |
| `schedule` | `dependency-update` |
| `workflow_dispatch` | `just-vibes` |
| Anything else | `quick-fix` |

Set `intent` explicitly to override.

---

## Full workflow example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Consult the cards
        uses: rembish/deploytarot-action@v1.1
        with:
          role: devops
          intent: full-release
          fail_on_abort: "true"

      - name: Deploy
        run: ./deploy.sh
```

---

## API

The action calls `deploytarot.com/api/reading` directly. You can also call it yourself:

```
GET https://deploytarot.com/api/reading?role=devops&intent=full-release
```

Full API reference: [deploytarot.com/api](https://deploytarot.com/api)

---

## Annotations

The verdict appears as a colored banner on the run page:

| Verdict | Color |
|---|---|
| Ship It 🚀 | Blue notice |
| Tread Carefully ⚠️ | Yellow warning |
| Abort Mission 🛑 | Red error |

The banner shows all three cards and the full verdict text. The job summary contains the complete reading with narratives and a share link.

---

## Notes

- Each run generates a fresh reading. The same role and intent will produce different cards each time.
- If the service is unreachable, the action emits a warning and exits cleanly (no failure).
- The API is rate-limited to 60 requests per minute per IP. GitHub Actions runners use different IPs per job, so this limit will not affect normal CI usage.
- The cards are not real. The anxiety they surface might be.

---

[deploytarot.com](https://deploytarot.com) · Built by [Alex Rembish](https://rembish.org)
