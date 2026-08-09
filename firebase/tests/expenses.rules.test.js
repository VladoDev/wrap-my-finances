const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  Timestamp,
} = require('firebase/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

const validExpense = () => ({
  id: 'exp_890123',
  amountMinor: 15000,
  currencyCode: 'MXN',
  categoryId: 'cat_food',
  date: Timestamp.fromDate(new Date('2026-08-07T14:30:00Z')),
  monthKey: '2026-08',
  note: 'Lunch',
  createdAt: Timestamp.fromDate(new Date('2026-08-07T14:30:02Z')),
  syncedAt: null,
  deletedAt: null,
  schemaVersion: 1,
});

describe('expenses security rules', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'wrap-my-finances-rules-test',
      firestore: { rules: fs.readFileSync(RULES_PATH, 'utf8') },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('owner can create a valid expense', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), validExpense()),
    );
  });

  it('owner can read their own expense', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), validExpense()),
    );
    await assertSucceeds(getDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1')));
  });

  it('owner can update an expense without changing createdAt', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), validExpense()),
    );
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/expenses/exp_1'),
        { ...validExpense(), note: 'Updated note' },
      ),
    );
  });

  it('owner cannot change createdAt on update', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), validExpense()),
    );
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), {
        ...validExpense(),
        createdAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')),
      }),
    );
  });

  it('owner can delete their own expense', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1'), validExpense()),
    );
    await assertSucceeds(deleteDoc(doc(alice.firestore(), 'users/alice/expenses/exp_1')));
  });

  it('a different user cannot read alice\'s expenses', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice/expenses/exp_1'), validExpense());
    });
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(getDoc(doc(bob.firestore(), 'users/alice/expenses/exp_1')));
  });

  it('a negative amountMinor is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_bad'), {
        ...validExpense(),
        amountMinor: -100,
      }),
    );
  });

  it('a zero amountMinor is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_bad'), {
        ...validExpense(),
        amountMinor: 0,
      }),
    );
  });

  it('an oversized amountMinor is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_bad'), {
        ...validExpense(),
        amountMinor: 100000001,
      }),
    );
  });

  it('a decimal (double) amountMinor is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_bad'), {
        ...validExpense(),
        amountMinor: 150.5,
      }),
    );
  });

  it('a malformed monthKey is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/expenses/exp_bad'), {
        ...validExpense(),
        monthKey: '2026-8',
      }),
    );
  });

  it('unauthenticated access is denied on every operation', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice/expenses/exp_1'), validExpense());
    });
    const anon = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(anon.firestore(), 'users/alice/expenses/exp_1')));
    await assertFails(
      setDoc(doc(anon.firestore(), 'users/alice/expenses/exp_2'), validExpense()),
    );
    await assertFails(deleteDoc(doc(anon.firestore(), 'users/alice/expenses/exp_1')));
  });

  it('denies writes to an undeclared top-level collection via the catch-all', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'undeclared_collection/doc1'), { foo: 'bar' }),
    );
  });
});
