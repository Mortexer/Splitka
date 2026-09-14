const test = require('node:test');
const assert = require('node:assert/strict');
const {findNotifications, memberName} = require('./index')._test;

test('finds only new receipts and common shopping items', () => {
  const before = {
    receipts: [{id: 'old'}],
    shoppingLists: {common: [{id: 'milk', name: 'Mleko'}]},
  };
  const after = {
    receipts: [{id: 'new', title: 'Biedronka'}, {id: 'old'}],
    shoppingLists: {
      common: [
        {id: 'milk', name: 'Mleko', completed: true},
        {id: 'bread', name: 'Chleb'},
      ],
      danus: [{id: 'private', name: 'Kawa'}],
    },
  };
  assert.deepEqual(findNotifications(before, after), [
    {type: 'receipt', body: 'dodał(a) rachunek: Biedronka'},
    {type: 'shopping_item', body: 'dodał(a) do wspólnej listy: Chleb'},
  ]);
});

test('resolves author from household members', () => {
  assert.equal(memberName({members: [{id: 'd', name: 'Damian'}]}, 'd'), 'Damian');
});
