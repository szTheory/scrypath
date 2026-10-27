const LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1"]);
const INVALID_TARGET_REASON = "A valid verifier URL is required.";
const PREVIEW_TARGET_REASON = "Run against the owned disposable verifier, never the retained preview.";

export function previewRefusalReason(baseURL) {
  if (typeof baseURL !== "string" || baseURL.trim() === "") return INVALID_TARGET_REASON;

  let target;
  try {
    target = new URL(baseURL);
  } catch {
    return INVALID_TARGET_REASON;
  }

  if (!["http:", "https:"].includes(target.protocol) || !target.hostname) {
    return INVALID_TARGET_REASON;
  }

  if (LOOPBACK_HOSTS.has(target.hostname) && target.port === "4002") {
    return PREVIEW_TARGET_REASON;
  }

  return null;
}

export async function guardVerificationTarget(baseURL, onRefusal, action) {
  const reason = previewRefusalReason(baseURL);
  if (reason) return onRefusal(reason);
  return action();
}
