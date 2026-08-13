const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, deleteDoc } = require('firebase/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

const validDefaultCategory = {
  id: 'cat_food',
  nameKey: 'category_food',
  name: null,
  color: '#FF5722',
  iconName: 'restaurant',
  isDefault: true,
  sortOrder: 1,
  isActive: true,
  usageCount: 0,
  schemaVersion: 1,
};

const validUserCategory = {
  id: 'cat_9f2ac1',
  nameKey: null,
  name: 'Side Hustle',
  color: '#00BFA5',
  iconName: 'briefcase',
  isDefault: false,
  sortOrder: 12,
  isActive: true,
  usageCount: 0,
  schemaVersion: 1,
};

describe('categories security rules', () => {
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

  it('owner can create a valid default category (nameKey set, name null)', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/categories/cat_food'),
        validDefaultCategory,
      ),
    );
  });

  it('owner can create a valid user category (name set, nameKey null)', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/categories/cat_9f2ac1'),
        validUserCategory,
      ),
    );
  });

  it('owner can update a valid category', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/categories/cat_food'),
        validDefaultCategory,
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/categories/cat_food'),
        { ...validDefaultCategory, usageCount: 5 },
      ),
    );
  });

  it('a category with both nameKey and name set is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/categories/cat_bad'), {
        ...validDefaultCategory,
        name: 'Also has a name',
      }),
    );
  });

  it('a category with neither nameKey nor name set is rejected', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'users/alice/categories/cat_bad'), {
        ...validDefaultCategory,
        nameKey: null,
        name: null,
      }),
    );
  });

  it('a different user cannot read alice\'s categories', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'users/alice/categories/cat_food'),
        validDefaultCategory,
      );
    });
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      getDoc(doc(bob.firestore(), 'users/alice/categories/cat_food')),
    );
  });

  // Owner delete — added by 007 (specs/007-account-linking-integrity), so
  // AuthRepository.deleteAccount() can remove every category document
  // client-side. See contracts/security-rules-delta.md.

  it('owner can delete their own category', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(
        doc(alice.firestore(), 'users/alice/categories/cat_food'),
        validDefaultCategory,
      ),
    );
    await assertSucceeds(
      deleteDoc(doc(alice.firestore(), 'users/alice/categories/cat_food')),
    );
  });

  it('a different user cannot delete alice\'s category', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'users/alice/categories/cat_food'),
        validDefaultCategory,
      );
    });
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      deleteDoc(doc(bob.firestore(), 'users/alice/categories/cat_food')),
    );
  });
});
