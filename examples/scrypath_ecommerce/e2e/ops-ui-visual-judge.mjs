#!/usr/bin/env node

import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCREENSHOT_DIR = process.env.ADMIN_SCREENSHOT_DIR || path.resolve(__dirname, "../test-results/admin-screenshots");
const REPORT_JSON = process.env.OPS_UI_VISUAL_JUDGE_JSON || path.resolve(__dirname, "../test-results/ops-ui-visual-judge.json");
const REPORT_MD = process.env.OPS_UI_VISUAL_JUDGE_MD || path.resolve(__dirname, "../test-results/ops-ui-visual-judge.md");
const RUBRIC_PATH = path.resolve(__dirname, "ops-ui-visual-rubric.md");
const MODEL = process.env.OPS_UI_LLM_MODEL || "gpt-4.1";
const REQUIRED = process.env.OPS_UI_LLM_JUDGE_REQUIRED === "1" || process.argv.includes("--required");

const REVIEW_SHOTS = [
  "00-control-room--dark--desktop--incident.png",
  "03-sync-drift--dark--desktop--drift.png",
  "06-search--dark--desktop--results.png",
  "08-search--dark--mobile--zero-results.png",
  "09-playbooks--dark--desktop--empty-workspace.png",
  "04-control-room--light--desktop--all-green.png"
];

const JUDGE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["status", "summary", "findings", "screens_reviewed", "claim_verdicts"],
  properties: {
    status: { type: "string", enum: ["pass", "needs_review"] },
    summary: { type: "string" },
    findings: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["severity", "screen", "issue", "evidence", "recommended_action"],
        properties: {
          severity: { type: "string", enum: ["blocker", "major", "minor", "cosmetic"] },
          screen: { type: "string" },
          issue: { type: "string" },
          evidence: { type: "string" },
          recommended_action: { type: "string" }
        }
      }
    },
    screens_reviewed: {
      type: "array",
      items: { type: "string" }
    },
    claim_verdicts: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["claim", "status", "evidence", "screens"],
        properties: {
          claim: { type: "string" },
          status: { type: "string", enum: ["pass", "needs_review"] },
          evidence: { type: "string" },
          screens: {
            type: "array",
            items: { type: "string" }
          }
        }
      }
    }
  }
};

async function writeReports(report) {
  await mkdir(path.dirname(REPORT_JSON), { recursive: true });
  await mkdir(path.dirname(REPORT_MD), { recursive: true });
  await writeFile(REPORT_JSON, `${JSON.stringify(report, null, 2)}\n`);

  const findings = report.findings?.length
    ? report.findings.map((finding) => `- ${finding.severity}: ${finding.screen} - ${finding.issue}`).join("\n")
    : "- none";
  const claimVerdicts = report.claim_verdicts?.length
    ? report.claim_verdicts.map((claim) => `- ${claim.status}: ${claim.claim} (${claim.screens.join(", ")})`).join("\n")
    : "- none";

  const lines = [
    "# Ops UI Visual Judge",
    "",
    `- status: ${report.status}`,
    `- model: ${report.model ?? "n/a"}`,
    `- required_mode: ${report.required === true}`,
    `- skipped_reason: ${report.skipped_reason ?? "none"}`,
    `- generated_at_utc: ${report.generated_at_utc}`,
    "",
    "## Summary",
    "",
    report.summary ?? "",
    "",
    "## Screens Reviewed",
    "",
    ...(report.screens_reviewed ?? []).map((screen) => `- ${screen}`),
    "",
    "## Findings",
    "",
    findings,
    "",
    "## Claim Verdicts",
    "",
    claimVerdicts,
    ""
  ];

  await writeFile(REPORT_MD, `${lines.join("\n")}`);
}

function outputText(response) {
  if (typeof response.output_text === "string") return response.output_text;

  for (const item of response.output ?? []) {
    for (const content of item.content ?? []) {
      if (content.type === "output_text" && typeof content.text === "string") {
        return content.text;
      }
    }
  }

  throw new Error("OpenAI response did not contain output text");
}

async function imageContent(filename) {
  const imagePath = path.join(SCREENSHOT_DIR, filename);
  const data = await readFile(imagePath);
  return {
    type: "input_image",
    image_url: `data:image/png;base64,${data.toString("base64")}`,
    detail: "low"
  };
}

async function runMock() {
  return {
    schema: "scrypath.ops-ui-visual-judge.v1",
    status: "pass",
    summary: "Mock visual judge completed with no findings.",
    findings: [],
    screens_reviewed: REVIEW_SHOTS,
    claim_verdicts: [
      {
        claim: "Shell wash reads as one quiet top-left violet ambient glow and not a discrete purple blob.",
        status: "pass",
        evidence: "Mock mode assumes deterministic shell wash gate supplied the blocking visual proof.",
        screens: REVIEW_SHOTS
      }
    ],
    model: "mock",
    required: REQUIRED,
    skipped_reason: null,
    generated_at_utc: new Date().toISOString()
  };
}

async function runOpenAI() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (process.env.OPS_UI_LLM_JUDGE !== "1") {
    return skipped("OPS_UI_LLM_JUDGE is not set to 1");
  }
  if (!apiKey) {
    return skipped("OPENAI_API_KEY is not available");
  }

  const rubric = await readFile(RUBRIC_PATH, "utf8");
  const content = [
    {
      type: "input_text",
      text: [
        "You are an adversarial visual QA judge for Scrypath's Phoenix operator UI.",
        "Use the rubric below. Return only JSON matching the schema.",
        "For every pass-only claim in the rubric, include one claim_verdicts entry.",
        "Set top-level status to needs_review if any finding exists or any claim verdict is needs_review.",
        "If deterministic tests should catch an issue, still report the visible symptom if it appears in the screenshots.",
        "",
        rubric,
        "",
        `Screens, in order: ${REVIEW_SHOTS.join(", ")}`
      ].join("\n")
    }
  ];

  for (const shot of REVIEW_SHOTS) {
    content.push(await imageContent(shot));
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: MODEL,
      input: [{ role: "user", content }],
      text: {
        format: {
          type: "json_schema",
          name: "ops_ui_visual_judge",
          strict: true,
          schema: JUDGE_SCHEMA
        }
      },
      max_output_tokens: 1600,
      store: false
    })
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OpenAI visual judge request failed: HTTP ${response.status} ${body.slice(0, 500)}`);
  }

  const parsed = JSON.parse(outputText(await response.json()));
  return {
    schema: "scrypath.ops-ui-visual-judge.v1",
    ...parsed,
    model: MODEL,
    required: REQUIRED,
    skipped_reason: null,
    generated_at_utc: new Date().toISOString()
  };
}

function skipped(reason) {
  return {
    schema: "scrypath.ops-ui-visual-judge.v1",
    status: "skipped",
    summary: "Advisory visual judge skipped.",
    findings: [],
    screens_reviewed: [],
    claim_verdicts: [],
    model: MODEL,
    required: REQUIRED,
    skipped_reason: reason,
    generated_at_utc: new Date().toISOString()
  };
}

try {
  const report = process.argv.includes("--mock") || process.env.OPS_UI_LLM_JUDGE_MOCK === "1"
    ? await runMock()
    : await runOpenAI();
  await writeReports(report);
  console.log(`ops-ui-visual-judge: ${report.status}`);
  if (REQUIRED && report.status !== "pass") {
    console.error(`ops-ui-visual-judge: required mode failed (${report.status})`);
    process.exitCode = 1;
  }
} catch (error) {
  const report = {
    schema: "scrypath.ops-ui-visual-judge.v1",
    status: "error",
    summary: "Advisory visual judge failed without blocking deterministic CI gates.",
    findings: [],
    screens_reviewed: [],
    claim_verdicts: [],
    model: MODEL,
    required: REQUIRED,
    skipped_reason: error instanceof Error ? error.message : String(error),
    generated_at_utc: new Date().toISOString()
  };
  await writeReports(report);
  console.log(`ops-ui-visual-judge: error (${report.skipped_reason})`);
  if (REQUIRED) {
    process.exitCode = 1;
  }
}
