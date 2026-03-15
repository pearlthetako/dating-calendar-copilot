# dating-calendar-copilot

A Codex/OpenClaw skill for dating conversation coaching and calendar-based date scheduling.

This skill helps turn dating app chats into better next steps without pretending to be you. It can help rewrite bios, draft replies, judge when a conversation is ready for an in-person ask, and convert availability into a few natural date options.

## What it does

- Rewrite dating bios and prompts in the user's voice
- Draft openers, replies, and follow-ups
- Judge whether a match seems ready for a low-pressure invite
- Suggest 2 to 3 date options from calendar availability
- Keep the workflow human-in-the-loop and privacy-aware

## Guardrails

- Do not impersonate the user
- Do not auto-send messages
- Do not invent feelings, intentions, or shared facts
- Do not expose sensitive calendar details beyond useful availability windows
- Keep suggestions respectful and low-pressure

## Repository layout

```text
.
|-- SKILL.md
|-- README.md
|-- LICENSE
|-- .gitignore
|-- agents/
|   `-- openai.yaml
|-- references/
|   |-- messaging-playbook.md
|   `-- privacy-and-safety.md
|-- scripts/
|   `-- find-date-slots.ps1
`-- examples/
    |-- busy-sample.json
    `-- prompts.md
```

## Install

Place this repository in your local skills folder:

```text
$CODEX_HOME/skills/dating-calendar-copilot
```

If your setup supports direct local skill references, you can also keep it anywhere on disk and point your agent to the folder.

## Use

Example prompts:

- `Use $dating-calendar-copilot to rewrite my Tinder bio so it sounds playful but not try-hard.`
- `Use $dating-calendar-copilot to draft a reply to this match and keep it concise.`
- `Use $dating-calendar-copilot to decide if this chat is ready for asking her out.`
- `Use $dating-calendar-copilot to suggest three date options from my availability this week.`

## Scheduling example

The starter PowerShell script reads busy calendar blocks from JSON and returns candidate date slots.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\find-date-slots.ps1 `
  -BusyFile .\examples\busy-sample.json `
  -RangeStart 2026-03-17 `
  -RangeEnd 2026-03-21 `
  -SlotMinutes 90 `
  -MaxSlots 3
```

Example output:

```json
[
  {
    "start": "2026-03-17T19:00:00",
    "end": "2026-03-17T20:30:00",
    "day": "Tuesday"
  },
  {
    "start": "2026-03-18T18:00:00",
    "end": "2026-03-18T19:30:00",
    "day": "Wednesday"
  }
]
```

## Included files

- `SKILL.md`: Core skill instructions and operating modes
- `agents/openai.yaml`: UI-facing skill metadata
- `references/messaging-playbook.md`: Drafting heuristics and examples
- `references/privacy-and-safety.md`: Guardrails for authenticity and privacy
- `scripts/find-date-slots.ps1`: Starter availability-to-slot conversion script
- `examples/`: Sample prompts and sample busy-calendar input

## Good next upgrades

- Add Google Calendar integration
- Add Apple Calendar export guidance
- Add message tone presets
- Add a helper that converts slot output into a draft text message
