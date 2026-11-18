import { isIP } from "node:net";

function isLoopback(hostname) {
  const host = hostname.replace(/^\[|\]$/g, "").replace(/\.$/, "");
  const version = isIP(host);
  return host === "localhost" ||
    (version === 4 && host.startsWith("127.")) ||
    (version === 6 && (host === "::1" || /^::ffff:7f[0-9a-f]{2}:/i.test(host)));
}
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

  if (isLoopback(target.hostname) && target.port === "4002") {
    return PREVIEW_TARGET_REASON;
  }

  return null;
}

export async function guardVerificationTarget(baseURL, onRefusal, action) {
  const reason = previewRefusalReason(baseURL);
  if (reason) return onRefusal(reason);
  return action();
}
