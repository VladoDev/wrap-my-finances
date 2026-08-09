const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

const validUser = (uid) => ({
  uid,
  createdAt: '2026-08-07T20:00:00Z',
  lastLogin: '2026-08-07T20:00:00Z',
  isAnonymous: true,
  currencyCode: 'MXN',
  locale: 'es-MX',
  timeZone: 'America/Mexico_City',
  defaultCategoryId: 'cat_food',
  wrappedLastSeenMonth: '2026-07',
  hapticsEnabled: true,
  schemaVersion: 1,
});

describe('users security rules', () => {
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

  it('owner can create their own user document', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice'), validUser('alice')),
    );
  });

  it('owner can read their own user document', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice'), validUser('alice'));
    });
    await assertSucceeds(
      require('firebase/firestore').getDoc(doc(alice.firestore(), 'users/alice')),
    );
  });

  it('a different user cannot read alice\'s document', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice'), validUser('alice'));
    });
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      require('firebase/firestore').getDoc(doc(bob.firestore(), 'users/alice')),
    );
  });

  it('owner can update their own document, keeping uid unchanged', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice'), validUser('alice')),
    );
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), 'users/alice'), { hapticsEnabled: false }),
    );
  });

  it('owner cannot change their own uid on update', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice'), validUser('alice')),
    );
    await assertFails(
      updateDoc(doc(alice.firestore(), 'users/alice'), { uid: 'mallory' }),
    );
  });

  it('delete is always denied', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'users/alice'), validUser('alice')),
    );
    await assertFails(deleteDoc(doc(alice.firestore(), 'users/alice')));
  });

  it('denies writes to an undeclared top-level collection via the catch-all', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'undeclared_collection/doc1'), { foo: 'bar' }),
    );
  });

  it('unauthenticated access is denied', async () => {
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(anon.firestore(), 'users/alice'), validUser('alice')),
    );
  });
});
