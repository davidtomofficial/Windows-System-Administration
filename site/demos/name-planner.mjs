// Pure, browser-safe synthetic planner. No I/O, global state, or Windows calls.
// (?![\s\S]) enforces an absolute end, unlike JavaScript's final-LF-permissive $.
const NAME = /^(?=.{1,15}(?![\s\S]))(?=[\s\S]*[A-Za-z])[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?![\s\S])/;
const PREFIX = /^[A-Za-z][A-Za-z0-9-]{0,13}(?![\s\S])/;
function integer(value, label, min, max) {
  const raw = String(value);
  if (!/^(0|[1-9][0-9]*)(?![\s\S])/.test(raw)) {
    throw new Error(label + ' must be a whole number from ' + min + ' to ' + max + '.');
  }
  const number = Number(raw);
  if (!Number.isSafeInteger(number) || number < min || number > max) {
    throw new Error(label + ' must be a whole number from ' + min + ' to ' + max + '.');
  }
  return number;
}
export function validateNames(candidates, maximum = 50) {
  const limit = integer(maximum, 'Maximum', 1, 256);
  if (!Array.isArray(candidates) || candidates.length < 1 || candidates.length > 256) {
    throw new Error('Supply between 1 and 256 explicit names.');
  }
  const results = [];
  const seen = new Set();
  // Validate every entry before returning anything, even duplicates.
  for (const candidate of candidates) {
    if (typeof candidate !== 'string' || !NAME.test(candidate)) {
      throw new Error('Invalid name: use 1–15 ASCII letters/digits and internal hyphens, including a letter. No spaces, wildcards, or line breaks.');
    }
    const normalized = candidate.toLowerCase();
    if (!seen.has(normalized)) { seen.add(normalized); results.push(candidate); }
  }
  if (results.length > limit) throw new Error('The unique selection exceeds the maximum.');
  return results;
}
export function planRange({ prefix, start, end, pad = 2, maximum = 50 }) {
  const first = integer(start, 'Start', 0, 9999);
  const last = integer(end, 'End', 0, 9999);
  const digits = integer(pad, 'Digits', 1, 4);
  const limit = integer(maximum, 'Maximum', 1, 256);
  if (typeof prefix !== 'string' || !PREFIX.test(prefix)) {
    throw new Error('Prefix must start with an ASCII letter and contain at most 14 letters, digits, or hyphens.');
  }
  if (last < first) throw new Error('End must be greater than or equal to Start.');
  if (last - first + 1 > limit) throw new Error('The requested range exceeds the maximum.');
  const candidates = Array.from({ length: last - first + 1 }, (_, i) =>
    prefix + String(first + i).padStart(digits, '0'));
  return validateNames(candidates, limit);
}
export function planList(input, maximum = 50) {
  if (typeof input !== 'string') throw new Error('Supply comma-separated explicit names.');
  // Do not trim: whitespace and final newlines should fail validation.
  return validateNames(input.split(','), maximum);
}
