const assert = require('node:assert/strict');
const { after, afterEach, before, test } = require('node:test');
const path = require('node:path');
const { readFileSync } = require('node:fs');

const {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
    addDoc,
    collection,
    doc,
    getDoc,
    setDoc,
    updateDoc,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-artist-community';

let testEnv;

before(async () => {
    testEnv = await initializeTestEnvironment({
        projectId: PROJECT_ID,
        firestore: {
            rules: readFileSync(
                path.resolve(__dirname, '..', '..', 'firestore.rules'),
                'utf8',
            ),
        },
    });
});

after(async () => {
    await testEnv.cleanup();
});

afterEach(async () => {
    await testEnv.clearFirestore();
});

function userDb(uid) {
    return testEnv.authenticatedContext(uid).firestore();
}

async function seedDoc(docPath, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), ...docPath), data);
    });
}

test('subscriptions: owner can create and read own document', async () => {
    const ownerDb = userDb('owner-uid');

    await assertSucceeds(
        setDoc(doc(ownerDb, 'subscriptions', 'sub-owner'), {
            userId: 'owner-uid',
            tier: 'basic',
            isActive: true,
            startDate: new Date(),
            renewalDate: new Date(),
            createdAt: new Date(),
        }),
    );

    await assertSucceeds(getDoc(doc(ownerDb, 'subscriptions', 'sub-owner')));
});

test('subscriptions: non-owner cannot read someone else subscription', async () => {
    await seedDoc(['subscriptions', 'sub-1'], {
        userId: 'owner-uid',
        tier: 'basic',
        isActive: true,
        startDate: new Date(),
        renewalDate: new Date(),
        createdAt: new Date(),
    });

    const attackerDb = userDb('attacker-uid');
    await assertFails(getDoc(doc(attackerDb, 'subscriptions', 'sub-1')));
});

test('subscriptions: owner can only deactivate with restricted fields', async () => {
    await seedDoc(['subscriptions', 'sub-2'], {
        userId: 'owner-uid',
        tier: 'premium',
        isActive: true,
        startDate: new Date(),
        renewalDate: new Date(),
        createdAt: new Date(),
        price: 29.99,
    });

    const ownerDb = userDb('owner-uid');

    await assertSucceeds(
        updateDoc(doc(ownerDb, 'subscriptions', 'sub-2'), {
            isActive: false,
            endDate: new Date(),
            updatedAt: new Date(),
        }),
    );

    await assertFails(
        updateDoc(doc(ownerDb, 'subscriptions', 'sub-2'), {
            price: 999.0,
        }),
    );
});

test('onboardingEvents: only matching user can create event under own doc', async () => {
    const ownerDb = userDb('user-a');
    const strangerDb = userDb('user-b');

    await assertSucceeds(
        addDoc(collection(ownerDb, 'users', 'user-a', 'onboardingEvents'), {
            eventType: 'mentor_selected',
            payload: { mentorName: 'Ava Mentor' },
            createdAt: new Date(),
        }),
    );

    await assertFails(
        addDoc(collection(strangerDb, 'users', 'user-a', 'onboardingEvents'), {
            eventType: 'mentor_selected',
            payload: { mentorName: 'Ava Mentor' },
            createdAt: new Date(),
        }),
    );
});

test('artworkOrders: owner can create and read, but cannot update', async () => {
    const ownerDb = userDb('buyer-uid');

    await assertSucceeds(
        setDoc(doc(ownerDb, 'artworkOrders', 'order-1'), {
            userId: 'buyer-uid',
            artworkId: 'post-1',
            artworkTitle: 'Sunset Study',
            amount: 150.0,
            status: 'checkout_created',
            createdAt: new Date(),
            updatedAt: new Date(),
        }),
    );

    await assertSucceeds(getDoc(doc(ownerDb, 'artworkOrders', 'order-1')));

    await assertFails(
        updateDoc(doc(ownerDb, 'artworkOrders', 'order-1'), {
            status: 'paid',
        }),
    );
});

test('artworkOrders: create denied when userId does not match auth uid', async () => {
    const attackerDb = userDb('attacker-uid');

    await assertFails(
        setDoc(doc(attackerDb, 'artworkOrders', 'order-2'), {
            userId: 'victim-uid',
            artworkId: 'post-1',
            artworkTitle: 'Mismatch',
            amount: 100.0,
            status: 'checkout_created',
            createdAt: new Date(),
            updatedAt: new Date(),
        }),
    );
});

test('collectorConversations/messages: participant can send, outsider cannot read', async () => {
    await seedDoc(['collectorConversations', 'conv-1'], {
        inquiryId: 'inq-1',
        postId: 'post-1',
        postTitle: 'Commission Portrait',
        postImageUrl: 'https://example.com/portrait.jpg',
        artistUid: 'artist-uid',
        artistName: 'Artist Name',
        buyerUid: 'buyer-uid',
        buyerName: 'Buyer Name',
        buyerEmail: 'buyer@example.com',
        intent: 'commission',
        latestMessage: 'Initial message',
        latestSenderUid: 'buyer-uid',
        participantUids: ['buyer-uid', 'artist-uid'],
        status: 'open',
        createdAt: new Date(),
        lastMessageAt: new Date(),
        lastReadAtBy: {
            'buyer-uid': new Date(),
            'artist-uid': new Date(),
        },
        unreadCountBy: {
            'buyer-uid': 0,
            'artist-uid': 0,
        },
    });

    const buyerDb = userDb('buyer-uid');
    const outsiderDb = userDb('outsider-uid');

    await assertSucceeds(
        setDoc(
            doc(
                buyerDb,
                'collectorConversations',
                'conv-1',
                'messages',
                'msg-1',
            ),
            {
                senderUid: 'buyer-uid',
                senderName: 'Buyer Name',
                senderEmail: 'buyer@example.com',
                text: 'Following up on timeline.',
                type: 'message',
                createdAt: new Date(),
            },
        ),
    );

    await assertFails(
        getDoc(
            doc(
                outsiderDb,
                'collectorConversations',
                'conv-1',
                'messages',
                'msg-1',
            ),
        ),
    );

    assert.ok(testEnv);
});
