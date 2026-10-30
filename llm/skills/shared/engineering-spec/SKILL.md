---
name: engineering-spec
description: Write or revise an engineering spec in a fixed, traceable format, where every requirement, decision and open question has a permanent ID tagged as [ID] exactly where it is defined, so the spec can be grepped and parsed. Use this whenever the user wants an engineering spec, technical spec, design spec, system spec, requirements document or architecture spec for a new project or a new phase of one, even if they just say "write up the spec" or "turn this plan into a spec". Also use it to settle an open question, add or withdraw a requirement, or check IDs in a spec already written this way.
---

# Engineering spec

Write specs that stay organized as they grow. Every binding statement is a short, numbered requirement with a permanent ID. Status lives only in two registers. Each ID is tagged `[ID]` exactly once, where it is defined, so `grep` or a small parser finds definitions without wading through mentions.

Why this shape. Specs degrade when decisions get appended to paragraphs ("decided", "resolved") and bullets grow into essays. A reader then has to parse prose to find what is true. Fixed requirement IDs, separate registers, and one definition tag per ID keep every fact in exactly one findable place, and let tools track progress against IDs.

## Workflow

1. **Gather what is settled and what is open.** Pull scope, constraints, decisions and open questions from the conversation and any attached material. Ask only about gaps that would change the structure, such as who the users are or what is out of scope. Anything still unknown becomes an open question, not a blocker.
2. **Choose the prefixes.** One prefix per area, two to five capital letters (`ARCH`, `SEC`, `PERF`). `D` and `Q` are reserved for decisions and open questions. Keep the prefix set small, since each prefix is a section a reader must learn.
3. **Copy the template.** Start from `assets/spec_template.md`. Section 0 is project-agnostic and is copied as written, with only the prefix table and header filled in. Then write the project sections.
4. **Write requirements.** Follow the rules below.
5. **Fill the registers.** Every choice made during planning gets a decision. Every choice still open gets a question with an owner and what it blocks.
6. **Check the IDs.** Run `python scripts/spec_ids.py check <spec.md> [other specs]` and fix every error before delivering. Pass companion documents too, so IDs cited across documents resolve.
7. **Deliver as a markdown file.**

## The tag rule

This is the core of the format. Get it exactly right.

- **A definition is tagged.** Write `[PREFIX-NN]` once, at the start of the paragraph that defines a requirement, or in the first cell of the register row that defines a decision or question.
- **A mention is never tagged.** Cite an ID anywhere else as the bare ID, `ARCH-05` or `Q-07`, with no brackets and no bold.
- **Each ID is defined exactly once** across every document that shares an ID space.
- **Never follow a tag with a colon.** In markdown, a line starting `[ID]:` is a link reference definition and disappears when rendered.
- **Examples go in fenced code blocks.** The ID tooling skips fenced code, so an example tag in section 0 never counts as a definition.
- **Numbering.** Two digits, zero-padded (`ARCH-01`), three digits once a prefix passes 99. Number in the order requirements appear when the spec is first written. After that, new IDs take the next unused number wherever they are placed. Never renumber.
- **Named requirements.** When a requirement has a short name, put it in bold after the tag, as in `[P-04] **Deterministic where an exact answer exists.** Geometry is plain code.` The tag still comes first.
- **Avoid collisions with domain identifiers.** Pick prefixes that do not match real-world tokens in the subject (an airspace named `P-56` collides with a `P` prefix). Where a collision is unavoidable, write the domain token in inline code, which the tooling ignores.
- **Withdrawn IDs stay.** Mark them `[ARCH-07] *Withdrawn.* Replaced by ARCH-12.` so a reference never points at the wrong rule.

Definition forms, as they appear in the spec.

```markdown
[ARCH-01] Each package must belong to exactly one layer.

_Why._ A package in two layers makes the import rules unenforceable.

| ID     | Question                             | Why it matters                      | Blocks  | Owner  | Status |
| ------ | ------------------------------------ | ----------------------------------- | ------- | ------ | ------ |
| [Q-04] | Which system supplies obstacle data? | SRC-01 forbids a source without one | Phase 1 | Client | Open   |
```

## Writing requirements

- **One checkable statement each.** If a requirement needs "and" to join two obligations a reviewer would check separately, split it. Aim for one or two sentences.
- **Keywords.** "Must" and "must not" are binding. "Should" is a strong default that needs a recorded reason to break. Avoid "may" for obligations.
- **State what is true, not history.** Never write "we decided", "now", "previously" or "resolved" in a requirement. History belongs in the decision register and changelog.
- **Rationale is optional and separate.** One sentence starting `*Why.*` under the requirement. Not binding, not tagged.
- **Guidance is labelled.** Blocks headed `**Guidance.**` describe the current plan. Once code exists the code wins, and guidance is edited to match without special review.
- **Cite, don't restate.** Point to another requirement by its bare ID rather than repeating it.
- **Put structure in tables.** Data models, field lists, state machines, choice matrices, stack choices and phase plans read better as tables than as bullets. A table cell holds a phrase or one short sentence.
- **Bullets stay short.** A bullet over two lines is a sign it is a requirement, a table row or its own paragraph.
- **Leave status out of requirements.** Implementation progress is tracked against IDs outside the spec (for example tests or tickets named by ID), because a spec that records its own progress goes stale.

## Prose style

- Short, plain sentences. Cut filler and restatement.
- No colons in prose. Split the sentence or use a comma. Colons inside code, values, URLs and titles are fine.
- No em-dashes. Use commas, parentheses or separate sentences.
- Bold lead-ins end with a period, as in `**Keywords.** Must is binding.`

## Document structure

Use this order. Sections the project does not need may be dropped, but keep the order of the rest so specs stay familiar to readers.

| Section                   | Holds                                                                                                                                         |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Header table              | Title, version, date, scope, document status                                                                                                  |
| 0. How to read this spec  | Requirement format, tag rule, prefix table, where status lives, how the spec changes. From the template                                       |
| 1. Purpose                | What the system does, its users, the scope boundary                                                                                           |
| 2. Principles             | The few rules every design choice answers to                                                                                                  |
| 3. Scope                  | Capabilities, out of scope, initial coverage                                                                                                  |
| 4. Glossary               | Terms a new reader would misread                                                                                                              |
| 5 onward. Design sections | Architecture, boundaries, contracts, data, behaviour, quality attributes, verification, engineering practice. One prefix per section or group |
| Delivery plan             | Ordered phases with exit criteria and the questions each needs answered                                                                       |
| Open question register    | Every open choice                                                                                                                             |
| Decision register         | Every settled choice                                                                                                                          |
| Changelog                 | Version, date, IDs changed                                                                                                                    |

Registers sit at the end so they are easy to find and so the design sections read without interruption.

### Register columns

| Register       | Columns                                             |
| -------------- | --------------------------------------------------- |
| Open questions | ID, Question, Why it matters, Blocks, Owner, Status |
| Decisions      | ID, Decision, Affects, Date                         |
| Changelog      | Version, Date, Requirements changed                 |

Question status is `Open` or `Closed by D-nn`. A decision's Affects column lists the bare IDs it settles.

## Changing a spec in this format

When the user asks for an edit, give copy-and-paste ready markdown and name the file and the ID or section it replaces.

- **Change a requirement.** Give its full replacement text with the same tag.
- **Settle an open question.** Give all three edits together.
  1. The new decision row.
  2. Each affected requirement, rewritten to state the outcome directly.
  3. The question row with status `Closed by D-nn`.
- **Add an item.** Use the next unused number in its prefix.
- **Withdraw an item.** Keep the tag and mark it withdrawn, naming any replacement.
- **Changelog.** Add a row naming every ID that changed, and raise the version for any binding change.

## Before delivering

- `scripts/spec_ids.py check` passes for the spec and its companions.
- Every prefix used appears in the section 0 prefix table.
- Every `Q-nn` named in a requirement exists, and every open question names what it blocks.
- No requirement contains status words or history.
- No colons in prose and no em-dashes.

## The ID tool

`scripts/spec_ids.py` uses only the Python standard library.

| Command           | Does                                                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `check FILE...`   | Reports duplicate definitions, mentions of undefined IDs, and tags not at the start of a paragraph or in a first table cell. Exits 1 on any error |
| `list FILE...`    | Prints every definition as tab-separated ID, file, line, withdrawn flag and text                                                                  |
| `show ID FILE...` | Prints one definition in full                                                                                                                     |

A mention is only checked when its prefix has at least one definition, so unrelated tokens such as `DO-200B` or `M-25-21` are ignored. Inline code and fenced code are skipped entirely. The same format works for companion reference documents with their own prefixes.
