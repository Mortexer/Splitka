import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  writeBatch, serverTimestamp, runTransaction, increment,
} from 'firebase/firestore';

const projectId = 'demo-splitka';
const roomId = 'room-one';
const code = '0123456789abcdef0123456789abcdef';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1', port: 8085,
      rules: await readFile('firestore.rules', 'utf8'),
    },
  });
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

function db(uid) {
  return uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
}

function roomData(uid, id = roomId, inviteCode = code) {
  return {
    schemaVersion: 2, roomCode: id, inviteCode, createdBy: uid, updatedBy: uid,
    updatedAt: serverTimestamp(), revision: 1,
    household: {
      id, members: [{ id: 'danus', name: 'Danus', color: '#64D487' }],
      receipts: [], shoppingLists: {}, updatedAt: 1,
    },
  };
}

async function createRoom(uid = 'owner', id = roomId, inviteCode = code) {
  const client = db(uid);
  const batch = writeBatch(client);
  batch.set(doc(client, 'households', id), roomData(uid, id, inviteCode));
  batch.set(doc(client, 'households', id, 'members', uid), {
    uid, inviteCode, joinedAt: serverTimestamp(),
  });
  batch.set(doc(client, 'invites', inviteCode), {
    roomId: id, createdBy: uid, createdAt: serverTimestamp(),
  });
  await batch.commit();
}

async function join(uid, inviteCode = code, id = roomId) {
  const client = db(uid);
  await setDoc(doc(client, 'households', id, 'members', uid), {
    uid, inviteCode, joinedAt: serverTimestamp(),
  });
}

test('room, creator membership and invite are created atomically', async () => {
  await assertSucceeds(createRoom());
  await assertSucceeds(getDoc(doc(db('owner'), 'households', roomId)));
});

test('creation also works in a write-only mobile-style transaction', async () => {
  const client = db('owner');
  await assertSucceeds(runTransaction(client, async (tx) => {
    tx.set(doc(client, 'households', roomId), roomData('owner'));
    tx.set(doc(client, 'households', roomId, 'members', 'owner'), {
      uid: 'owner', inviteCode: code, joinedAt: serverTimestamp(),
    });
    tx.set(doc(client, 'invites', code), {
      roomId, createdBy: 'owner', createdAt: serverTimestamp(),
    });
  }));
});

test('signed-out clients and uninvited signed-in clients cannot read or edit rooms', async () => {
  await createRoom();
  for (const uid of [null, 'outsider']) {
    const client = db(uid);
    await assertFails(getDoc(doc(client, 'households', roomId)));
    await assertFails(updateDoc(doc(client, 'households', roomId), { revision: 2 }));
    await assertFails(deleteDoc(doc(client, 'households', roomId)));
  }
  await assertFails(getDoc(doc(db(null), 'invites', code)));
});

test('a known invite lets a second roommate join and edit with equal rights', async () => {
  await createRoom();
  const client = db('roommate');
  await assertSucceeds(getDoc(doc(client, 'invites', code)));
  await assertSucceeds(join('roommate'));
  await assertSucceeds(updateDoc(doc(client, 'households', roomId), {
    'household.receipts': [{ id: 'receipt-1' }],
    revision: 2, updatedBy: 'roommate', updatedAt: serverTimestamp(),
  }));
  const result = await getDoc(doc(db('owner'), 'households', roomId));
  assert.equal(result.data().household.receipts.length, 1);
});

test('roommates can update shopping lists but malformed lists are rejected', async () => {
  await createRoom();
  await join('roommate');
  const client = db('roommate');
  await assertSucceeds(updateDoc(doc(client, 'households', roomId), {
    'household.shoppingLists': {
      common: [{ id: 'milk', name: 'Milk', completed: false, createdAt: 1 }],
    },
    revision: 2, updatedBy: 'roommate', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(client, 'households', roomId), {
    'household.shoppingLists': 'invalid',
    revision: 3, updatedBy: 'roommate', updatedAt: serverTimestamp(),
  }));
});

test('groups support up to twenty editable participants', async () => {
  await createRoom();
  const client = db('owner');
  const members = Array.from({ length: 20 }, (_, index) => ({
    id: `member-${index}`, name: `Person ${index + 1}`, color: '#45B164', active: true,
  }));
  await assertSucceeds(updateDoc(doc(client, 'households', roomId), {
    'household.members': members,
    revision: 2, updatedBy: 'owner', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(client, 'households', roomId), {
    'household.members': [...members, { id: 'member-20', name: 'Too many', color: '#499FE3' }],
    revision: 3, updatedBy: 'owner', updatedAt: serverTimestamp(),
  }));
});

test('joining can transactionally check an absent own membership', async () => {
  await createRoom();
  const client = db('roommate');
  await assertSucceeds(runTransaction(client, async (tx) => {
    const invite = await tx.get(doc(client, 'invites', code));
    const membership = doc(client, 'households', invite.data().roomId, 'members', 'roommate');
    if (!(await tx.get(membership)).exists()) {
      tx.set(membership, { uid: 'roommate', inviteCode: code, joinedAt: serverTimestamp() });
    }
  }));
});

test('codes cannot be listed or used to join another household', async () => {
  await createRoom();
  await createRoom('another-owner', 'another-room', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
  await assertFails(getDocs(collection(db('owner'), 'invites')));
  await assertFails(getDocs(collection(db('owner'), 'households')));
  await assertFails(join('outsider', code, 'another-room'));
  await assertFails(join('outsider', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'));
});

test('membership cannot be forged for another user or bootstrapped without a room', async () => {
  await createRoom();
  await assertFails(setDoc(doc(db('outsider'), 'households', roomId, 'members', 'someone-else'), {
    uid: 'someone-else', inviteCode: code, joinedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('outsider'), 'households', 'new-room'), roomData('outsider', 'new-room')));
  await assertFails(updateDoc(doc(db('owner'), 'households', roomId, 'members', 'owner'), { uid: 'outsider' }));
});

test('stale revisions, tampered identities and malformed records are rejected', async () => {
  await createRoom();
  const client = db('owner');
  const base = { revision: 2, updatedBy: 'owner', updatedAt: serverTimestamp() };
  for (const invalid of [
    { ...base, revision: 1 }, { ...base, revision: 3 },
    { ...base, updatedBy: 'someone-else' }, { ...base, createdBy: 'someone-else' },
    { ...base, inviteCode: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
    { ...base, 'household.id': 'another-room' },
    { ...base, 'household.members': [] }, { ...base, 'household.receipts': 'invalid' },
    { ...base, 'household.shoppingLists': 'invalid' },
    { ...base, schemaVersion: 1 }, { ...base, extra: true },
  ]) {
    await assertFails(updateDoc(doc(client, 'households', roomId), invalid));
  }
});

test('concurrent transactional edits keep both receipts', async () => {
  await createRoom();
  await join('roommate');
  const append = (uid, receiptId) => {
    const client = db(uid);
    return runTransaction(client, async (tx) => {
      const ref = doc(client, 'households', roomId);
      const current = (await tx.get(ref)).data();
      tx.update(ref, {
        'household.receipts': [...current.household.receipts, { id: receiptId }],
        revision: increment(1), updatedBy: uid, updatedAt: serverTimestamp(),
      });
    });
  };
  await Promise.all([append('owner', 'one'), append('roommate', 'two')]);
  const result = (await getDoc(doc(db('owner'), 'households', roomId))).data();
  assert.equal(result.revision, 3);
  assert.deepEqual(result.household.receipts.map((receipt) => receipt.id).sort(), ['one', 'two']);
});
