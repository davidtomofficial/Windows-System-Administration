import test from 'node:test';
import assert from 'node:assert/strict';
import { planRange, planList, validateNames } from '../demos/name-planner.mjs';
test('default padded range is deterministic', () => assert.deepEqual(planRange({prefix:'LAB-',start:'1',end:'3'}), ['LAB-01','LAB-02','LAB-03']));
test('range grows beyond padding without truncation', () => assert.deepEqual(planRange({prefix:'PC',start:99,end:100,pad:2}), ['PC99','PC100']));
test('range may start at zero', () => assert.deepEqual(planRange({prefix:'PC',start:0,end:0,pad:1}), ['PC0']));
test('list deduplicates case-insensitively, preserving first spelling', () => assert.deepEqual(planList('LAB-01,lab-01,LAB-02'), ['LAB-01','LAB-02']));
test('single letter and embedded hyphens are valid', () => assert.deepEqual(validateNames(['A','PC-A1','A1B']), ['A','PC-A1','A1B']));
for (const invalid of ['LAB-01\n','LAB*','ABC.local','192.0.2.3','LAB_01',' LAB','LAB ','-LAB','LAB-','1234','A'.repeat(16),'LAB;whoami','','LAB\r']) {
  test('rejects invalid list token ' + JSON.stringify(invalid), () => assert.throws(() => planList(invalid), /Invalid name|Supply between/));
}
for (const invalid of ['LAB-\n','-LAB','LAB_','123','A'.repeat(15),'LAB.']) {
  test('rejects invalid prefix ' + JSON.stringify(invalid), () => assert.throws(() => planRange({prefix:invalid,start:1,end:2}), /Prefix/));
}
test('trailing comma is not silently dropped', () => assert.throws(() => planList('LAB-01,'), /Invalid name/));
test('bad later element yields no partial result', () => assert.throws(() => planList('LAB-01,LAB*'), /Invalid name/));
test('descending and over-cap ranges fail', () => {
  assert.throws(() => planRange({prefix:'PC',start:5,end:4}), /End/);
  assert.throws(() => planRange({prefix:'PC',start:1,end:257,maximum:256}), /exceeds/);
});
test('final name length checked after range generation', () => assert.throws(() => planRange({prefix:'ABCDEFGHIJKLMN',start:1,end:1}), /Invalid name/));
test('decimals, negatives, leading zeros and empty fields fail', () => {
  for (const start of ['1.5','-1','01','','1\n']) assert.throws(() => planRange({prefix:'PC',start,end:2}), /Start/);
});
test('256 allowed, 257 rejected', () => {
  assert.equal(planRange({prefix:'PC',start:0,end:255,maximum:256}).length, 256);
  assert.throws(() => planRange({prefix:'PC',start:0,end:256,maximum:256}), /exceeds/);
});
test('limits explicit input and unique outputs', () => {
  assert.throws(() => validateNames(Array(257).fill('PC')), /256/);
  assert.throws(() => planList('PC1,PC2',1), /maximum/);
});
