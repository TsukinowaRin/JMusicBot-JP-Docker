---
name: local-skill-bootstrap
description: Create or update a repo-local shared skill when the user asks for a new reusable workflow, or when repeated repo-specific instructions should become a local skill instead of ad-hoc prompting or downloading a third-party skill.
---

# Local Skill Bootstrap

Use this skill when a repeatable workflow should become a repo-local skill under `.agents/skills/`.

Do not use this for:
- one-off task notes that belong in `docs/REQS.md`
- downloading or installing third-party skills from the internet
- tiny single-use prompts that do not justify a reusable workflow

## Workflow

1. Check whether an existing skill already covers the need.
2. Choose a hyphen-case skill name and a precise trigger description.
3. Run `scripts/init_skill.py` in this skill directory to scaffold the new shared skill.
4. Edit the generated `SKILL.md` and any optional `scripts/`, `references/`, or `assets/`.
5. Run `python3 scripts/sync_shared_skills_to_claude.py` so `.claude/skills/` stays in sync.
6. If the new skill changes repo workflow, update the minimum relevant docs.

## Commands

Create a minimal skill:

```bash
python3 .agents/skills/local-skill-bootstrap/scripts/init_skill.py \
  --name my-skill \
  --description "Explain exactly when this skill should trigger."
```

Create a skill with bundled folders:

```bash
python3 .agents/skills/local-skill-bootstrap/scripts/init_skill.py \
  --name my-skill \
  --description "Explain exactly when this skill should trigger." \
  --with-scripts \
  --with-references
```

## Authoring Rules

- Keep `SKILL.md` concise and explicit about when to use and not use the skill.
- Put reusable code in `scripts/` only when determinism or repetition justifies it.
- Put detailed reference material in `references/` instead of bloating `SKILL.md`.
- Do not create extra README or changelog files inside the skill.
- Prefer updating an existing skill over creating a near-duplicate.

## Validation

- `find .agents/skills/<skill-name> -maxdepth 3 -type f | sort`
- `find .claude/skills/<skill-name> -maxdepth 3 -type f | sort`
- `python3 scripts/sync_shared_skills_to_claude.py`

For Gemini CLI, reload if needed with `/skills reload`.
