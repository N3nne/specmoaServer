import * as assert from 'node:assert/strict';
import { test } from 'node:test';
import { normalizeSpecData, REQUIRED_SPEC_FIELDS, specTitle } from '../src/specs/spec-field-policy';
import { SpecType } from '../src/specs/spec-types';

for (const type of Object.values(SpecType)) {
  test(`${type}: every prototype input is optional`, () => {
    assert.deepEqual(REQUIRED_SPEC_FIELDS[type], []);
    assert.deepEqual(normalizeSpecData(type, {}), {});
    assert.equal(specTitle(type, {}), null);
  });
}

test('manual certification needs no catalog id, date or number', () => {
  assert.deepEqual(normalizeSpecData(SpecType.CERTIFICATION, { name: '  사내 자격증  ', issuer: null, acquiredOn: '' }), { name: '사내 자격증' });
});
test('missing GPA scale and paired period fields are allowed', () => {
  assert.deepEqual(normalizeSpecData(SpecType.EDUCATION_RECORD, { gpa: 4.12 }), { gpa: 4.12 });
  assert.deepEqual(normalizeSpecData(SpecType.PROJECT, { endedMonth: '2026-09' }), { endedMonth: '2026-09' });
});
test('zero and false are values, not missing input', () => {
  assert.deepEqual(normalizeSpecData(SpecType.EDUCATION_RECORD, { gpa: 0, hasAdditionalMajor: false }), { gpa: 0, hasAdditionalMajor: false });
});
test('only supplied values are validated, including strict calendar dates', () => {
  for (const input of [{ acquiredOn: '2026-02-30' }, { acquiredOn: '2026-2-03' }, { acquiredOn: '2099-01-01' }, { lifetime: 'true' }, { certificationId: 'not-an-id' }, { result: 88 }]) {
    assert.throws(() => normalizeSpecData(SpecType.CERTIFICATION, input));
  }
  assert.throws(() => normalizeSpecData(SpecType.EDUCATION_RECORD, { gpa: 4.7, gpaScale: 4.5 }));
  assert.throws(() => normalizeSpecData(SpecType.LANGUAGE_SCORE, { score: 991, exam: 'TOEIC' }));
  assert.throws(() => normalizeSpecData(SpecType.TRAINING, { hours: 0 }));
});
test('conditional optional data is cleared without requiring replacement fields', () => {
  assert.deepEqual(normalizeSpecData(SpecType.PROJECT, { ongoing: true, endedMonth: '2026-09' }), { ongoing: true });
  assert.deepEqual(normalizeSpecData(SpecType.CERTIFICATION, { lifetime: true, expiresOn: '2026-09-01' }), { lifetime: true });
  assert.throws(() => normalizeSpecData(SpecType.PROJECT, { startedMonth: '2026-10', endedMonth: '2026-09' }));
});
test('tags are normalized, deduplicated and capped only where specified', () => {
  assert.deepEqual(normalizeSpecData(SpecType.CERTIFICATION, { keywords: [' #SQL ', 'SQL', ' '] }), { keywords: ['SQL'] });
  assert.throws(() => normalizeSpecData(SpecType.CERTIFICATION, { keywords: ['1', '2', '3', '4', '5', '6'] }));
  assert.throws(() => normalizeSpecData(SpecType.PROJECT, { action: 'a'.repeat(501) }));
  assert.throws(() => normalizeSpecData(SpecType.AWARD, { relatedUrl: 'javascript:alert(1)' }));
});
test('undeclared fields cannot inject ownership, certification or AI results', () => {
  for (const key of ['userId', 'verification', 'status', 'attachments', 'aiScore', 'notes', '__proto__']) {
    assert.throws(() => normalizeSpecData(SpecType.CERTIFICATION, JSON.parse(`{"${key}":"injected"}`)));
  }
});
