/**
 * mongo-engine.js
 * Pure filter/projection/parse logic for the simulated MongoDB shell.
 * No DOM dependencies — importable by both challenge.html (as a classic script)
 * and the Vitest test suite (as an ES module).
 */

// ── Extended JSON unwrap ──────────────────────────────────────────────────────

function unwrap(val) {
  if (val && typeof val === 'object') {
    if (val.$oid)  return val.$oid;
    if (val.$date) return val.$date;
  }
  return val;
}

// ── Dot-notation field access ─────────────────────────────────────────────────

function getPath(doc, path) {
  let cur = doc;
  for (const part of path.split('.')) {
    if (cur == null) return undefined;
    cur = typeof cur === 'object' ? cur[part] : undefined;
  }
  return unwrap(cur);
}

// ── Field-level operator evaluation ──────────────────────────────────────────

function checkFieldOp(docVal, op, opVal, parentObj) {
  switch (op) {
    case '$eq':     return unwrap(docVal) === unwrap(opVal);
    case '$ne':     return unwrap(docVal) !== unwrap(opVal);
    case '$gt':     return docVal >  opVal;
    case '$gte':    return docVal >= opVal;
    case '$lt':     return docVal <  opVal;
    case '$lte':    return docVal <= opVal;
    case '$in':     return Array.isArray(opVal) && opVal.map(unwrap).includes(unwrap(docVal));
    case '$nin':    return Array.isArray(opVal) && !opVal.map(unwrap).includes(unwrap(docVal));
    case '$exists': { const e = docVal !== undefined && docVal !== null; return e === !!opVal; }
    case '$regex':  { try { return new RegExp(opVal, parentObj?.$options || '').test(String(docVal ?? '')); } catch { return false; } }
    case '$options': return true; // consumed by $regex
    default: return true;
  }
}

// ── Document filter ───────────────────────────────────────────────────────────

function matchesFilter(doc, filter) {
  if (!filter || typeof filter !== 'object' || Array.isArray(filter)) return true;

  for (const [key, value] of Object.entries(filter)) {
    // Logical operators (top-level)
    if (key === '$or')  { if (!Array.isArray(value) || !value.some(f  => matchesFilter(doc, f))) return false; continue; }
    if (key === '$and') { if (!Array.isArray(value) || !value.every(f => matchesFilter(doc, f))) return false; continue; }
    if (key === '$nor') { if (!Array.isArray(value) ||  value.some(f  => matchesFilter(doc, f))) return false; continue; }

    const docVal = getPath(doc, key);

    if (value !== null && typeof value === 'object' && !value.$oid && !value.$date && !Array.isArray(value)) {
      // Operator expression(s)
      for (const [op, opVal] of Object.entries(value)) {
        if (op === '$not') {
          const innerPasses = Object.entries(opVal).every(([iop, ival]) => checkFieldOp(docVal, iop, ival, opVal));
          if (innerPasses) return false;
        } else {
          if (!checkFieldOp(docVal, op, opVal, value)) return false;
        }
      }
    } else {
      // Direct equality
      if (unwrap(docVal) !== unwrap(value)) return false;
    }
  }
  return true;
}

// ── Sort ──────────────────────────────────────────────────────────────────────

function applySort(docs, sort) {
  if (!sort) return docs;
  const entries = Object.entries(sort);
  return [...docs].sort((a, b) => {
    for (const [field, dir] of entries) {
      const av = getPath(a, field), bv = getPath(b, field);
      if (av < bv) return -dir;
      if (av > bv) return  dir;
    }
    return 0;
  });
}

// ── Projection ────────────────────────────────────────────────────────────────

function setNestedPath(obj, parts, val) {
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (cur[parts[i]] == null || typeof cur[parts[i]] !== 'object') cur[parts[i]] = {};
    cur = cur[parts[i]];
  }
  cur[parts[parts.length - 1]] = val;
}

function deleteNestedPath(obj, parts) {
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (!cur || cur[parts[i]] == null) return;
    cur = cur[parts[i]];
  }
  if (cur) delete cur[parts[parts.length - 1]];
}

function projectDoc(doc, proj) {
  if (!proj || !Object.keys(proj).length) return doc;
  const entries = Object.entries(proj);
  const isInclusive = entries.some(([k, v]) => v === 1 && k !== '_id');

  if (isInclusive) {
    const result = {};
    if (proj._id !== 0 && doc._id !== undefined) result._id = doc._id;
    for (const [field, val] of entries) {
      if (val === 1 && field !== '_id') {
        const v = getPath(doc, field);
        if (v !== undefined) setNestedPath(result, field.split('.'), v);
      }
    }
    return result;
  } else {
    const result = JSON.parse(JSON.stringify(doc));
    for (const [field, val] of entries) {
      if (val === 0) deleteNestedPath(result, field.split('.'));
    }
    return result;
  }
}

function applyProjection(docs, proj) {
  if (!proj || !Object.keys(proj).length) return docs;
  return docs.map(d => projectDoc(d, proj));
}

// ── Query parser ──────────────────────────────────────────────────────────────

function extractParens(str, startFrom = 0) {
  const open = str.indexOf('(', startFrom);
  if (open === -1) return null;
  let depth = 0;
  for (let i = open; i < str.length; i++) {
    if      (str[i] === '(') depth++;
    else if (str[i] === ')') { depth--; if (depth === 0) return { inner: str.slice(open+1, i).trim(), after: str.slice(i+1).trim() }; }
  }
  return null;
}

// Split "filter_json, projection_json" respecting brace depth
function parseTwoJsonArgs(str) {
  if (!str.trim()) return { first: {}, second: {} };
  try { return { first: JSON.parse(str), second: {} }; } catch {}
  let depth = 0, firstEnd = -1;
  for (let i = 0; i < str.length; i++) {
    if ('{['.includes(str[i])) depth++;
    else if ('}]'.includes(str[i])) { depth--; if (depth === 0) { firstEnd = i; break; } }
  }
  if (firstEnd === -1) return { error: `Could not parse arguments` };
  const firstStr = str.slice(0, firstEnd + 1);
  const rest     = str.slice(firstEnd + 1).trim().replace(/^,\s*/, '');
  try {
    const first  = JSON.parse(firstStr);
    const second = rest ? (() => { try { return JSON.parse(rest); } catch { return {}; } })() : {};
    return { first, second };
  } catch(e) {
    return { error: `Filter parse error: ${e.message}` };
  }
}

function parseCommand(raw) {
  const q = raw.trim();

  if (/^show dbs?$/i.test(q))          return { cmd: 'show_dbs' };
  if (/^show collections$/i.test(q))   return { cmd: 'getcollectionnames' };
  if (/^cl(s|ear)$/i.test(q))          return { cmd: 'clear' };
  const useM = q.match(/^use\s+(\S+)$/i);
  if (useM) return { cmd: 'use', dbName: useM[1] };

  if (/^db\.getCollectionNames\s*\(\s*\)$/i.test(q)) return { cmd: 'getcollectionnames' };

  const baseM = q.match(/^db\.(\w+)\.(\w+)\s*\(/i);
  if (!baseM) return { cmd: 'unknown', raw: q };

  const colName = baseM[1];
  const method  = baseM[2].toLowerCase();
  const parsed  = extractParens(q, q.indexOf('('));
  if (!parsed) return { cmd: 'error', msg: 'Unmatched parenthesis.' };

  const { inner, after } = parsed;

  let filter = {}, projection = {}, fieldArg = null, parseErr = null;

  if (inner) {
    if (method === 'distinct') {
      const fm = inner.match(/^["'](\w[\w.]*?)["']/);
      fieldArg = fm ? fm[1] : null;
      if (!fieldArg) parseErr = `distinct requires a quoted field name, e.g. distinct("status")`;
    } else {
      const two = parseTwoJsonArgs(inner);
      if (two.error) parseErr = two.error;
      else { filter = two.first || {}; projection = two.second || {}; }
    }
  }
  if (parseErr) return { cmd: 'error', msg: parseErr };

  let sort = null, limit = null, rest = after;
  for (let pass = 0; pass < 4; pass++) {
    if (/^\.sort\s*\(/i.test(rest)) {
      const sp = extractParens(rest, rest.indexOf('('));
      if (sp) { try { sort = JSON.parse(sp.inner); } catch {} rest = sp.after; continue; }
    }
    if (/^\.limit\s*\(/i.test(rest)) {
      const lp = extractParens(rest, rest.indexOf('('));
      if (lp) { limit = parseInt(lp.inner); rest = lp.after; continue; }
    }
    break;
  }

  return { cmd: method, colName, filter, projection, fieldArg, sort, limit };
}

// ── Exports (ES module — used by tests) ──────────────────────────────────────
// challenge.html uses these as plain globals via a <script> tag, so the
// export block is harmless in that context (browsers ignore unknown syntax
// when the script is loaded as text/javascript without type="module").

export {
  unwrap,
  getPath,
  checkFieldOp,
  matchesFilter,
  applySort,
  applyProjection,
  projectDoc,
  extractParens,
  parseTwoJsonArgs,
  parseCommand,
};
