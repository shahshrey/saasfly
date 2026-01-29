# Ralph Knowledge Base

> Read this FIRST at the start of each iteration.
> Append learnings at the END after each task.

---

## ⚠️ Guardrails (Pitfalls to Avoid)

### Sign: Read Before Writing
- **Trigger**: Before modifying any file
- **Do**: Always read the existing file first

### Sign: Test Before Marking Complete
- **Trigger**: Before setting `"passes": true`
- **Do**: Run tests, check browser, verify it actually works

### Sign: Commit Early and Often
- **Trigger**: After any significant change
- **Do**: Commit immediately - your commits ARE your memory across rotations

### Sign: Fix Services Before Proceeding
- **Trigger**: Database/server not running
- **Do**: Fix it first, don't skip or defer

### Sign: Don't Create Nested Git Repos
- **Trigger**: When scaffolding projects
- **Do**: Never run `git init` - repo already exists. Use `--no-git` flags.

---

## 🔧 Working Commands

```bash
# Add verified working commands here
# Example:
# bun dev           # Start dev server on :3000
# bun db:push       # Push schema to database
# bun test          # Run tests
```

---

## 🧠 Codebase Patterns

<!-- Add permanent patterns about this codebase here -->
<!-- Example: "API routes are in app/api/[resource]/route.ts" -->
<!-- Example: "Auth uses Clerk, get userId with auth()" -->

---

## 🔴 Error → Fix Map

| Error | Fix |
|-------|-----|
| <!-- ECONNREFUSED :5432 --> | <!-- docker compose up -d --> |

---

## 📝 Iteration Log

<!-- Append your learnings below this line -->
<!-- Format:
---
## Iteration N - task-id
- **Result**: PASS/FAIL
- **What was done**: Brief description
- **Learnings**:
  - Pattern discovered
  - Gotcha encountered
  - Command that worked
---
-->
