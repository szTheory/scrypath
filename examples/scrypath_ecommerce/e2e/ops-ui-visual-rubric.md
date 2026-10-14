# Scrypath UI critique rubric

Current authority is the repository's `DESIGN.md` and maintained operator role/job/language model. This optional judge sees a sampled set of screenshots, so it cannot certify whole-app coverage, user journeys, hidden states, or backend outcomes. It is supplemental; the complete workflow is `examples/scrypath_ecommerce/e2e/UI-REVIEW.md`.

Review the supplied images against these claims and report uncertainty when an image cannot support one:

- The operator can identify the current observation, affected object, limits, and safe next action.
- Each surface has a task-specific hierarchy rather than interchangeable dashboard cards. Primary actions, secondary evidence, and advanced controls have distinguishable importance.
- Light mode uses the current cool neutral floor; dark mode has clear neutral surface separation. The shell is flat. Do not request the retired violet background wash, copper/cream halos, status-colored cards, or a new palette.
- Active navigation uses the documented soft selection. The theme picker has one legible neutral selected preference, and primary actions and focus cues remain distinct.
- Typography, spacing, borders, density, and color work as a coherent system across the supplied screens; compact layouts do not hide essential decisions or overflow.
- Copy helps complete the task, uses consistent precise terms, and separates queue jobs from backend tasks, accepted work from completion, settings agreement from document visibility, and saved definitions from run outcomes. Don't erase relevant engineering terms or request a blanket terminology replacement.
- Look for unreported issues beyond known maintainer examples: excessive explanation, jargon without context, competing actions, misleading empty/success states, inaccessible contrasts, truncation, and inconsistent handoffs.
- Preserve useful incumbent behavior and brand details. Recommend the smallest coherent repair with a concrete user consequence and evidence; a taste preference or numeric beauty score isn't sufficient.

Review the operator-guide destination and missing interaction/state coverage separately. A screenshot filename, mock response, or successful axe scan does not establish a design pass. Never auto-update screenshot baselines to clear findings.
