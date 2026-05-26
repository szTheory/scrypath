# Scrypath GSD Instructions

## Architectural Decisions and Phase Planning
When researching gray areas, architectural decisions, or milestone/phase planning:
- Automatically perform deep research using subagents and the context available in the `prompts/` directory (e.g., Elixir/Ecto/Phoenix best practices).
- Provide deep, cohesive, one-shot recommendations. Do not ask the user for input unless it is a highly impactful, major decision point and you have already narrowed down the options.
- Include pros/cons/tradeoffs for each approach, considering examples.
- Emphasize what is idiomatic for Elixir/Plug/Ecto/Phoenix for this type of library/ecosystem.
- Incorporate lessons learned from popular, successful tools in the same space (including other languages/frameworks) – highlight what they did right and common footguns to avoid.
- Prioritize great developer ergonomics (DX), user-friendliness, the principle of least surprise, and great UI/UX where applicable.
- Ensure all recommendations are coherent and align with the project's vision and high-quality software engineering standards.
- Shift this decision-making "left" to be autonomous and automated, minimizing the need to prompt the user for intermediate steps.
