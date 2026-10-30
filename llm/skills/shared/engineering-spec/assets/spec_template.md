# <System name>: Engineering Spec

| Field                   | Value                                                                    |
| ----------------------- | ------------------------------------------------------------------------ |
| Version                 | 0.1 draft                                                                |
| Date                    | <Day, DD-Mon-YY>                                                         |
| Scope                   | <One sentence on what the system is>                                     |
| Status of this document | Draft. Open questions must be answered before the work they block starts |

<Two or three sentences on what the system does and the one boundary that matters most.>

---

## 0. How to read this spec

### 0.1 Requirement format

Every rule in this spec is a numbered requirement with a permanent ID. Each one is a short statement that can be checked.

- **Definition tag.** An ID appears in square brackets exactly once, where it is defined. A requirement's tag starts its paragraph. A decision's or question's tag is the first cell of its register row.
- **Mentions.** Everywhere else an ID is cited bare, without brackets, so a search for the bracketed form finds only its definition.
- **Keywords.** "Must" and "must not" are binding. "Should" is a strong default that needs a recorded reason to break.
- **Rationale.** A requirement may be followed by one sentence starting with _Why_. Rationale is not binding.
- **Guidance.** Blocks headed **Guidance** describe the current plan. Once code exists, the code wins over guidance. Update guidance to match the code.
- **IDs are permanent.** IDs are never renumbered or reused. A removed requirement keeps its ID, marked _Withdrawn_, so references never point at the wrong rule.

A requirement and a mention look like this.

```markdown
[ARCH-01] Each package must belong to exactly one layer.

[ARCH-02] Import rules must be enforced in CI, so ARCH-01 holds on every change.
```

| Prefix   | Area           | Section |
| -------- | -------------- | ------- |
| P        | Principles     | 2       |
| <PREFIX> | <Area>         | <n>     |
| Q        | Open questions | <n>     |
| D        | Decisions      | <n>     |

### 0.2 Where status lives

Status never sits inside prose. It lives in two registers.

- **Open question register.** Every choice still open, with an owner and what it blocks.
- **Decision register.** Every choice that settles an open point, naming the requirements it affects.

Requirements cite these by ID only, as in "the budget is set by Q-07". To settle a question, follow these steps.

1. Add a decision to the decision register.
2. Edit the affected requirements so they state the outcome directly.
3. Mark the question _Closed by D-nn_ in the open question register.

Never add "decided" or "resolved" notes to a requirement. A requirement states what is true now.

### 0.3 Changing this spec

- **Binding changes** go through review by <named roles>.
- **Guidance changes** follow the code and need no special review.
- **Version bumps.** The version in the header goes up on every binding change. A changelog entry names the IDs that changed.

---

## 1. Purpose

<What the system does, as a short list of steps or outcomes.>

### 1.1 Users

| Group   | What they do in the system |
| ------- | -------------------------- |
| <Group> | <Actions>                  |

### 1.2 Scope boundary

[P-01] <The boundary the system must never cross.>

_Why._ <One sentence.>

---

## 2. Principles

[P-02] **<Short name>.** <The principle in one or two sentences.>

---

## 3. Scope

### 3.1 Capabilities

| Capability   | What it does   |
| ------------ | -------------- |
| <Capability> | <One sentence> |

### 3.2 Out of scope

- <Item.>

---

## 4. Glossary

| Term   | Meaning   |
| ------ | --------- |
| <Term> | <Meaning> |

---

## 5. <Design section>

[<PREFIX>-01] <Requirement.>

**Guidance.** <Current plan, if any.>

---

## <n>. Delivery plan

| Phase     | Delivers | Exit criteria            | Needs answered |
| --------- | -------- | ------------------------ | -------------- |
| 0. <Name> | <What>   | <How we know it is done> | <Q-nn>         |

---

## <n>. Open question register

| ID     | Question    | Why it matters | Blocks         | Owner   | Status |
| ------ | ----------- | -------------- | -------------- | ------- | ------ |
| [Q-01] | <Question?> | <Reason>       | <IDs or phase> | <Owner> | Open   |

---

## <n>. Decision register

| ID     | Decision   | Affects | Date         |
| ------ | ---------- | ------- | ------------ |
| [D-01] | <Decision> | <IDs>   | <YYYY-MM-DD> |

---

## Changelog

| Version   | Date         | Requirements changed |
| --------- | ------------ | -------------------- |
| 1.0 draft | <YYYY-MM-DD> | Initial version      |
