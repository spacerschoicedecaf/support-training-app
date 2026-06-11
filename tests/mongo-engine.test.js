import { describe, it, expect } from 'vitest';
import {
  unwrap,
  getPath,
  matchesFilter,
  applySort,
  applyProjection,
  extractParens,
  parseTwoJsonArgs,
  parseCommand,
} from '../js/mongo-engine.js';

// ── unwrap ────────────────────────────────────────────────────────────────────

describe('unwrap', () => {
  it('returns $oid string', () => {
    expect(unwrap({ $oid: 'abc123' })).toBe('abc123');
  });
  it('returns $date string', () => {
    expect(unwrap({ $date: '2024-01-01T00:00:00Z' })).toBe('2024-01-01T00:00:00Z');
  });
  it('passes through primitives', () => {
    expect(unwrap(42)).toBe(42);
    expect(unwrap('hello')).toBe('hello');
    expect(unwrap(null)).toBe(null);
  });
  it('passes through plain objects', () => {
    const obj = { a: 1 };
    expect(unwrap(obj)).toBe(obj);
  });
});

// ── getPath ───────────────────────────────────────────────────────────────────

describe('getPath', () => {
  const doc = { a: { b: { c: 42 } }, x: { $oid: 'id1' } };

  it('reads a top-level field', () => {
    expect(getPath({ status: 'ok' }, 'status')).toBe('ok');
  });
  it('reads a nested field via dot notation', () => {
    expect(getPath(doc, 'a.b.c')).toBe(42);
  });
  it('unwraps $oid at leaf', () => {
    expect(getPath(doc, 'x')).toBe('id1');
  });
  it('returns undefined for missing path', () => {
    expect(getPath(doc, 'a.z.c')).toBeUndefined();
  });
  it('returns undefined when intermediate is null', () => {
    expect(getPath({ a: null }, 'a.b')).toBeUndefined();
  });
});

// ── matchesFilter ─────────────────────────────────────────────────────────────

describe('matchesFilter', () => {
  const docs = [
    { _id: 1, status: 'active',   score: 90, region: 'us' },
    { _id: 2, status: 'inactive', score: 45, region: 'eu' },
    { _id: 3, status: 'active',   score: 72, region: 'eu' },
    { _id: 4, status: 'pending',  score: 10, region: 'us' },
  ];

  const match = (filter) => docs.filter(d => matchesFilter(d, filter));

  it('matches empty filter (all docs)', () => {
    expect(match({})).toHaveLength(4);
  });

  it('direct equality', () => {
    expect(match({ status: 'active' })).toHaveLength(2);
  });

  it('$eq', () => {
    expect(match({ status: { $eq: 'inactive' } })).toHaveLength(1);
  });

  it('$ne', () => {
    expect(match({ status: { $ne: 'active' } })).toHaveLength(2);
  });

  it('$gt / $lt', () => {
    expect(match({ score: { $gt: 70 } })).toHaveLength(2);
    expect(match({ score: { $lt: 50 } })).toHaveLength(2);
  });

  it('$gte / $lte', () => {
    expect(match({ score: { $gte: 72 } })).toHaveLength(2);
    expect(match({ score: { $lte: 45 } })).toHaveLength(2);
  });

  it('$in', () => {
    expect(match({ region: { $in: ['us', 'eu'] } })).toHaveLength(4);
    expect(match({ status: { $in: ['active', 'pending'] } })).toHaveLength(3);
  });

  it('$nin', () => {
    expect(match({ status: { $nin: ['active'] } })).toHaveLength(2);
  });

  it('$exists true', () => {
    const mixedDocs = [{ a: 1 }, { b: 2 }, { a: null }];
    expect(mixedDocs.filter(d => matchesFilter(d, { a: { $exists: true } }))).toHaveLength(1);
  });

  it('$exists false', () => {
    const mixedDocs = [{ a: 1 }, { b: 2 }];
    expect(mixedDocs.filter(d => matchesFilter(d, { a: { $exists: false } }))).toHaveLength(1);
  });

  it('$regex match', () => {
    expect(match({ status: { $regex: '^act' } })).toHaveLength(2);
  });

  it('$regex with $options i', () => {
    // /ACTIVE/i matches 'active' (×2) and 'inactive' (substring) — 3 total
    expect(match({ status: { $regex: 'ACTIVE', $options: 'i' } })).toHaveLength(3);
    // anchored pattern matches only exact 'active' docs
    expect(match({ status: { $regex: '^active$', $options: 'i' } })).toHaveLength(2);
  });

  it('$not reversal', () => {
    expect(match({ score: { $not: { $gt: 70 } } })).toHaveLength(2);
  });

  it('$or', () => {
    expect(match({ $or: [{ status: 'pending' }, { score: { $gt: 80 } }] })).toHaveLength(2);
  });

  it('$and', () => {
    expect(match({ $and: [{ status: 'active' }, { region: 'eu' }] })).toHaveLength(1);
  });

  it('$nor', () => {
    // excludes active (×2) and inactive (×1) — only pending (×1) remains
    expect(match({ $nor: [{ status: 'active' }, { status: 'inactive' }] })).toHaveLength(1);
  });

  it('multi-field filter (implicit AND)', () => {
    expect(match({ status: 'active', region: 'eu' })).toHaveLength(1);
  });

  it('matches $oid equality', () => {
    const doc = { _id: { $oid: 'abc' }, name: 'test' };
    expect(matchesFilter(doc, { _id: { $oid: 'abc' } })).toBe(true);
    expect(matchesFilter(doc, { _id: { $oid: 'xyz' } })).toBe(false);
  });

  it('dot-notation field access in filter', () => {
    const doc = { meta: { env: 'prod' } };
    expect(matchesFilter(doc, { 'meta.env': 'prod' })).toBe(true);
    expect(matchesFilter(doc, { 'meta.env': 'staging' })).toBe(false);
  });
});

// ── applySort ─────────────────────────────────────────────────────────────────

describe('applySort', () => {
  const docs = [
    { name: 'charlie', score: 50 },
    { name: 'alice',   score: 90 },
    { name: 'bob',     score: 50 },
  ];

  it('sorts ascending (1)', () => {
    const result = applySort(docs, { score: 1 });
    expect(result[0].score).toBe(50);
    expect(result[2].score).toBe(90);
  });

  it('sorts descending (-1)', () => {
    const result = applySort(docs, { score: -1 });
    expect(result[0].score).toBe(90);
  });

  it('multi-key sort: primary desc, secondary asc', () => {
    const result = applySort(docs, { score: -1, name: 1 });
    expect(result[0].name).toBe('alice');
    // Among score=50 docs, bob < charlie alphabetically
    expect(result[1].name).toBe('bob');
    expect(result[2].name).toBe('charlie');
  });

  it('returns original array unchanged (no mutation)', () => {
    const copy = [...docs];
    applySort(docs, { score: 1 });
    expect(docs).toEqual(copy);
  });

  it('returns docs unchanged when sort is null', () => {
    expect(applySort(docs, null)).toEqual(docs);
  });
});

// ── applyProjection ───────────────────────────────────────────────────────────

describe('applyProjection', () => {
  const docs = [
    { _id: 1, name: 'alice', score: 90, region: 'us' },
    { _id: 2, name: 'bob',   score: 45, region: 'eu' },
  ];

  it('empty projection returns all fields', () => {
    expect(applyProjection(docs, {})[0]).toEqual(docs[0]);
  });

  it('inclusive projection keeps _id by default', () => {
    const result = applyProjection(docs, { name: 1 });
    expect(result[0]).toEqual({ _id: 1, name: 'alice' });
    expect(result[0].score).toBeUndefined();
  });

  it('inclusive projection with _id:0', () => {
    const result = applyProjection(docs, { name: 1, _id: 0 });
    expect(result[0]).toEqual({ name: 'alice' });
  });

  it('exclusive projection removes specified fields', () => {
    const result = applyProjection(docs, { score: 0 });
    expect(result[0].score).toBeUndefined();
    expect(result[0].name).toBe('alice');
    expect(result[0]._id).toBe(1);
  });

  it('exclusive projection with _id:0', () => {
    const result = applyProjection(docs, { score: 0, _id: 0 });
    expect(result[0]._id).toBeUndefined();
    expect(result[0].score).toBeUndefined();
  });

  it('dot-notation inclusion', () => {
    const nested = [{ _id: 1, meta: { env: 'prod', version: '2.1' }, name: 'x' }];
    const result = applyProjection(nested, { 'meta.env': 1 });
    expect(result[0].meta.env).toBe('prod');
    expect(result[0].meta.version).toBeUndefined();
  });

  it('dot-notation exclusion', () => {
    const nested = [{ _id: 1, meta: { env: 'prod', version: '2.1' } }];
    const result = applyProjection(nested, { 'meta.version': 0 });
    expect(result[0].meta.env).toBe('prod');
    expect(result[0].meta.version).toBeUndefined();
  });
});

// ── extractParens ─────────────────────────────────────────────────────────────

describe('extractParens', () => {
  it('extracts simple inner content', () => {
    const r = extractParens('find({a:1})');
    expect(r.inner).toBe('{a:1}');
    expect(r.after).toBe('');
  });

  it('handles nested parens correctly', () => {
    const r = extractParens('find({a:{$gt:1}}).limit(5)');
    expect(r.inner).toBe('{a:{$gt:1}}');
    expect(r.after).toBe('.limit(5)');
  });

  it('returns null when no open paren', () => {
    expect(extractParens('noparen')).toBeNull();
  });

  it('extracts empty parens', () => {
    const r = extractParens('getCollectionNames()');
    expect(r.inner).toBe('');
  });
});

// ── parseTwoJsonArgs ──────────────────────────────────────────────────────────

describe('parseTwoJsonArgs', () => {
  it('empty string returns empty objects', () => {
    const r = parseTwoJsonArgs('');
    expect(r.first).toEqual({});
    expect(r.second).toEqual({});
  });

  it('single JSON object', () => {
    const r = parseTwoJsonArgs('{"status":"active"}');
    expect(r.first).toEqual({ status: 'active' });
    expect(r.second).toEqual({});
  });

  it('two JSON objects separated by comma', () => {
    const r = parseTwoJsonArgs('{"status":"active"}, {"name":1}');
    expect(r.first).toEqual({ status: 'active' });
    expect(r.second).toEqual({ name: 1 });
  });

  it('nested braces do not confuse the splitter', () => {
    const r = parseTwoJsonArgs('{"score":{"$gt":50}}, {"name":1,"_id":0}');
    expect(r.first).toEqual({ score: { $gt: 50 } });
    expect(r.second).toEqual({ name: 1, _id: 0 });
  });

  it('returns error on malformed first arg', () => {
    const r = parseTwoJsonArgs('{bad json}');
    expect(r.error).toBeDefined();
  });
});

// ── parseCommand ──────────────────────────────────────────────────────────────

describe('parseCommand', () => {
  it('show dbs', () => {
    expect(parseCommand('show dbs')).toEqual({ cmd: 'show_dbs' });
    expect(parseCommand('show db')).toEqual({ cmd: 'show_dbs' });
  });

  it('show collections', () => {
    expect(parseCommand('show collections')).toEqual({ cmd: 'getcollectionnames' });
  });

  it('db.getCollectionNames()', () => {
    expect(parseCommand('db.getCollectionNames()')).toEqual({ cmd: 'getcollectionnames' });
  });

  it('use <db>', () => {
    expect(parseCommand('use mydb')).toEqual({ cmd: 'use', dbName: 'mydb' });
  });

  it('clear / cls', () => {
    expect(parseCommand('clear')).toEqual({ cmd: 'clear' });
    expect(parseCommand('cls')).toEqual({ cmd: 'clear' });
    expect(parseCommand('CLS')).toEqual({ cmd: 'clear' });
  });

  it('find with no args', () => {
    const r = parseCommand('db.users.find()');
    expect(r.cmd).toBe('find');
    expect(r.colName).toBe('users');
    expect(r.filter).toEqual({});
    expect(r.projection).toEqual({});
  });

  it('find with filter', () => {
    const r = parseCommand('db.orders.find({"status":"active"})');
    expect(r.cmd).toBe('find');
    expect(r.colName).toBe('orders');
    expect(r.filter).toEqual({ status: 'active' });
  });

  it('find with filter and projection', () => {
    const r = parseCommand('db.orders.find({"status":"active"}, {"name":1,"_id":0})');
    expect(r.filter).toEqual({ status: 'active' });
    expect(r.projection).toEqual({ name: 1, _id: 0 });
  });

  it('findOne', () => {
    const r = parseCommand('db.users.findOne({"_id":{"$oid":"abc"}})');
    expect(r.cmd).toBe('findone');
    expect(r.filter).toEqual({ _id: { $oid: 'abc' } });
  });

  it('find with .sort() chain', () => {
    const r = parseCommand('db.users.find().sort({"score":-1})');
    expect(r.sort).toEqual({ score: -1 });
    expect(r.limit).toBeNull();
  });

  it('find with .limit() chain', () => {
    const r = parseCommand('db.users.find().limit(10)');
    expect(r.limit).toBe(10);
    expect(r.sort).toBeNull();
  });

  it('find with .sort().limit() chained', () => {
    const r = parseCommand('db.users.find().sort({"score":-1}).limit(5)');
    expect(r.sort).toEqual({ score: -1 });
    expect(r.limit).toBe(5);
  });

  it('countDocuments', () => {
    const r = parseCommand('db.logs.countDocuments({"level":"error"})');
    expect(r.cmd).toBe('countdocuments');
    expect(r.filter).toEqual({ level: 'error' });
  });

  it('distinct', () => {
    const r = parseCommand('db.users.distinct("region")');
    expect(r.cmd).toBe('distinct');
    expect(r.fieldArg).toBe('region');
  });

  it('distinct with single quotes', () => {
    const r = parseCommand("db.users.distinct('status')");
    expect(r.fieldArg).toBe('status');
  });

  it('returns unknown for unrecognised commands', () => {
    const r = parseCommand('db.whoami()');
    expect(r.cmd).toBe('unknown');
  });

  it('returns error on unmatched paren', () => {
    const r = parseCommand('db.users.find({');
    expect(r.cmd).toBe('error');
  });
});
