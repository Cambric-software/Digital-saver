# Agent instructions — Digital Saver

## Read the roadmap first

`ROADMAP.md` in this repository is the authoritative, ordered list of work for
this product and its sibling **Max Tools**. Read it before starting anything.
Work it top to bottom.

Do not start a lower phase while a higher phase has an open item unless the user
says otherwise.

## The principle

**Cambric for all, to all.** Products are flexible and customisable, built
around a few things a person does every day. Three features used daily beat a
hundred opened once. Every feature must explain itself well enough for anyone —
any age, any language, any job.

## Standing rules

- Verify before claiming done. `flutter analyze` for errors; `flutter test` for
  behaviour; the UI capture harness for both phone (390px) and laptop (1440px).
- Never present a computed value as a measurement.
- A reading of zero means "no reading" and renders as `--`, never as a number.
- Health status is always a label and an icon as well as a colour.
- Health data is handled with the care that implies. Do not overstate what the
  hardware can measure.
- Ask the user when a decision is theirs. Do not invent an answer.

## Commits

Use `git -c user.name="Cambric Software" -c user.email="dev@cambric.dev"`.
