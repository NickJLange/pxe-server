<!-- OPENSPEC:START -->
# OpenSpec Instructions

These are instructions for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Engineering Preferences

These preferences shape all work on this project. Apply them before any other consideration.

- **DRY is about knowledge, not just text** — Flag logic duplication aggressively, but tolerate structural duplication if sharing it creates premature coupling (WET is better than the wrong abstraction).
- **Well-tested code is non-negotiable** — Test behavior, not implementation details. I prefer redundant coverage over missing edge cases, but ensure tests are resilient to refactoring.
- **Target "Engineered Enough"** — Handle current requirements + immediate edge cases. **Apply YAGNI**: do not build for hypothetical future use cases. Abstract only when you see the pattern for the third time (Rule of Three).
- **Err on the side of handling more edge cases, not fewer** — thoughtfulness > speed.
- **Bias toward explicit over clever.**

---

## Review Process (Plan Mode)

Before starting a review, you **MUST** ask:

> **BIG CHANGE or SMALL CHANGE?**
> 1. **BIG CHANGE**: Work through this interactively, one section at a time (Architecture → Code Quality → Tests → Performance) with at most 4 top issues in each section.
> 2. **SMALL CHANGE**: Work through interactively ONE question per review section.

### Review Sections

Walk through these four sections **in order**, presenting one section at a time. Wait for user feedback before proceeding to the next.

1. **Architecture review** — overall system design, component boundaries, dependency graph, coupling, data flow, scaling, security.
2. **Code quality review** — organization, module structure, DRY violations, error handling patterns, missing edge cases, tech debt hotspots, and over/under-engineering relative to preferences.
3. **Test review** — coverage gaps (unit, integration, e2e), test quality, assertion strength, missing edge cases, untested failure modes, and error paths.
4. **Performance review** — N+1 queries, database access patterns, memory-usage concerns, caching opportunities, slow or high-complexity code paths.

### Issue Format

For every specific issue (bug, smell, design concern, or risk):

- Describe the problem concretely, with file and line references.
- Present 2-3 options, including "do nothing" where reasonable.
- For each option, specify: implementation effort, risk, impact on other code, and **maintenance burden**.
- Give an opinionated recommendation and why, mapped to the engineering preferences.
- Explicitly ask whether the user agrees or wants a different direction before proceeding.

**Formatting Rules**:
- **NUMBER issues** (1, 2, 3...) and then give **LETTERS for options** (A, B, C...).
- The recommended option must always be the 1st option (Option A).
- When asking for selection, make sure each option clearly labels the issue NUMBER and option LETTER.
