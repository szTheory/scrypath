export function previewRefusalReason(_baseURL) {
  return "Run against the owned disposable verifier, never the retained preview.";
}

export async function guardVerificationTarget(baseURL, onRefusal, action) {
  const reason = previewRefusalReason(baseURL);
  if (reason) return onRefusal(reason);
  return action();
}
