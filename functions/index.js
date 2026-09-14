const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

exports.notifyHouseholdUpdate = onDocumentUpdated(
  {document: 'households/{roomId}', region: 'europe-west1'},
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const oldHousehold = before.household || {};
    const household = after.household || {};
    const notifications = findNotifications(oldHousehold, household);
    if (notifications.length === 0) return;

    const devicesSnapshot = await event.data.after.ref
      .collection('notificationDevices')
      .get();
    const devices = devicesSnapshot.docs.map((doc) => ({
      ref: doc.ref,
      ...doc.data(),
    }));
    const authorDevice = devices.find((device) => device.uid === after.updatedBy);
    const author = memberName(household, authorDevice?.memberId) || 'Ktoś';
    const recipients = devices.filter(
      (device) => device.uid !== after.updatedBy && typeof device.token === 'string',
    );
    if (recipients.length === 0) return;

    for (const notification of notifications) {
      const response = await getMessaging().sendEachForMulticast({
        tokens: recipients.map((device) => device.token),
        notification: {
          title: String(household.name || 'Splitka').slice(0, 60),
          body: `${author} ${notification.body}`.slice(0, 180),
        },
        data: {
          roomId: event.params.roomId,
          type: notification.type,
        },
        android: {
          priority: 'high',
          notification: {channelId: 'splitka_updates'},
        },
        apns: {payload: {aps: {sound: 'default'}}},
      });
      const invalid = response.responses
        .map((result, index) => ({result, device: recipients[index]}))
        .filter(({result}) => isInvalidToken(result.error));
      await Promise.all(invalid.map(({device}) => device.ref.delete()));
    }
  },
);

function findNotifications(before, after) {
  const result = [];
  const oldReceiptIds = new Set((before.receipts || []).map((item) => item.id));
  for (const receipt of after.receipts || []) {
    if (!oldReceiptIds.has(receipt.id)) {
      const name = receipt.title || receipt.storeName || 'Nowy rachunek';
      result.push({type: 'receipt', body: `dodał(a) rachunek: ${name}`});
    }
  }

  const oldItems = before.shoppingLists?.common || [];
  const oldItemIds = new Set(oldItems.map((item) => item.id));
  for (const item of after.shoppingLists?.common || []) {
    if (!oldItemIds.has(item.id)) {
      result.push({
        type: 'shopping_item',
        body: `dodał(a) do wspólnej listy: ${item.name}`,
      });
    }
  }
  return result.slice(0, 10);
}

function memberName(household, memberId) {
  return (household.members || []).find((member) => member.id === memberId)?.name;
}

function isInvalidToken(error) {
  return error && [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
  ].includes(error.code);
}

exports._test = {findNotifications, memberName};
