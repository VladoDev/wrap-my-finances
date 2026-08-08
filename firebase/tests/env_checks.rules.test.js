const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

const validProbe = {
  id: 'probe1',
  environmentName: 'dev',
  createdAtMillis: 1700000000000,
  label: 'probe',
};

describe('env_checks security rules', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'wrap-my-finances-rules-test',
      firestore: {
        rules: fs.readFileSync(RULES_PATH, 'utf8'),
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('accepts a well-formed authenticated probe write', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'env_checks/probe1'), validProbe),
    );
  });

  it('rejects an authenticated probe write with a malformed type', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'env_checks/probe2'), {
        ...validProbe,
        id: 'probe2',
        createdAtMillis: 'not-a-number',
      }),
    );
  });

  it('rejects an authenticated probe write with an extra field', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'env_checks/probe3'), {
        ...validProbe,
        id: 'probe3',
        extra: 'field',
      }),
    );
  });

  it('rejects an authenticated probe write with an oversized label', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'env_checks/probe4'), {
        ...validProbe,
        id: 'probe4',
        label: 'x'.repeat(41),
      }),
    );
  });

  it('rejects an unauthenticated probe write', async () => {
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(anon.firestore(), 'env_checks/probe5'), {
        ...validProbe,
        id: 'probe5',
      }),
    );
  });

  it('denies writes to an undeclared top-level collection via the catch-all', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      setDoc(doc(alice.firestore(), 'undeclared_collection/doc1'), {
        foo: 'bar',
      }),
    );
  });
});
