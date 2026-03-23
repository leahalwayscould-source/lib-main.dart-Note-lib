const admin = require('firebase-admin');
const functions = require('firebase-functions');
const Stripe = require('stripe');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();
const lifetimeRenewalDate = new Date('2099-12-31T00:00:00.000Z');

const PRINT_PRICING = {
    poster: { small: 12.99, medium: 19.99, large: 29.99, xlarge: 44.99 },
    canvas: { small: 29.99, medium: 49.99, large: 79.99, xlarge: 119.99 },
    framed: { small: 39.99, medium: 64.99, large: 99.99, xlarge: 149.99 },
    tote_bag: { small: 18.99, medium: 22.99, large: 22.99, xlarge: 22.99 },
    phone_case: { small: 16.99, medium: 16.99, large: 16.99, xlarge: 16.99 },
    adult_hoodie_pullover: { small: 39.99, medium: 42.99, large: 44.99, xlarge: 47.99 },
};

const HOODIE_COLORS = ['black', 'white', 'navy', 'charcoal', 'heather_gray', 'maroon', 'forest_green'];

function getServerUnitPrice(printType, size) {
    return PRINT_PRICING?.[printType]?.[size] ?? null;
}

function mapProviderStatusToAppStatus(providerStatus) {
    const value = String(providerStatus || '').toLowerCase();
    if (['created', 'submitted', 'accepted', 'in_production', 'processing'].includes(value)) {
        return 'processing';
    }
    if (['fulfilled', 'shipped', 'in_transit'].includes(value)) {
        return 'shipped';
    }
    if (['delivered', 'completed'].includes(value)) {
        return 'delivered';
    }
    if (['cancelled', 'canceled', 'failed', 'rejected'].includes(value)) {
        return 'cancelled';
    }
    return 'pending';
}

function getPrintProviderName() {
    return process.env.PRINT_PROVIDER || 'manual';
}

function toEnvKeyToken(value) {
    return String(value || '')
        .trim()
        .toUpperCase()
        .replace(/[^A-Z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '');
}

function resolvePrintfulVariantId(printType, size, productColor) {
    const typeToken = toEnvKeyToken(printType);
    const sizeToken = toEnvKeyToken(size);
    const colorToken = toEnvKeyToken(productColor);

    const colorKey = colorToken
        ? `PRINTFUL_VARIANT_${typeToken}_${sizeToken}_${colorToken}`
        : null;
    const baseKey = `PRINTFUL_VARIANT_${typeToken}_${sizeToken}`;
    const variantId =
        (colorKey ? process.env[colorKey] : null) ||
        process.env[baseKey] ||
        process.env.PRINTFUL_DEFAULT_VARIANT_ID;
    if (!variantId) {
        return null;
    }

    const numericId = Number(variantId);
    return Number.isFinite(numericId) ? numericId : null;
}

function buildPrintfulOrderPayload(orderId, order) {
    const variantId = resolvePrintfulVariantId(order.printType, order.size, order.productColor);
    if (!variantId) {
        throw new Error(
            `No Printful variant mapping found for ${order.printType}/${order.size}` +
            `${order.productColor ? `/${order.productColor}` : ''}. ` +
            'Set PRINTFUL_VARIANT_<PRINTTYPE>_<SIZE>_<COLOR>, PRINTFUL_VARIANT_<PRINTTYPE>_<SIZE>, ' +
            'or PRINTFUL_DEFAULT_VARIANT_ID.',
        );
    }

    return {
        external_id: orderId,
        confirm: true,
        recipient: {
            name: order.shippingName,
            address1: order.shippingAddress,
            city: order.shippingCity,
            country_code: String(order.shippingCountry || '').toUpperCase(),
            zip: order.shippingPostalCode,
        },
        items: [
            {
                variant_id: variantId,
                quantity: order.quantity,
                files: [
                    {
                        url: order.artworkImageUrl,
                    },
                ],
            },
        ],
    };
}

async function submitOrderToPrintful(orderId, order) {
    const token = process.env.PRINTFUL_API_TOKEN;
    if (!token) {
        throw new Error('PRINTFUL_API_TOKEN is not configured.');
    }

    const endpoint = process.env.PRINTFUL_API_BASE_URL || 'https://api.printful.com';
    const payload = buildPrintfulOrderPayload(orderId, order);

    const response = await fetch(`${endpoint}/orders`, {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok || !body?.result?.id) {
        const errorMessage = body?.error?.message || body?.message || `HTTP ${response.status}`;
        throw new Error(`Printful order submission failed: ${errorMessage}`);
    }

    return {
        providerOrderId: String(body.result.id),
        providerStatus: body.result.status || 'submitted',
        raw: body,
    };
}

async function submitPrintOrderToProvider(orderId, order) {
    const provider = getPrintProviderName();
    if (provider === 'printful') {
        return submitOrderToPrintful(orderId, order);
    }

    // Unknown providers default to queued/manual processing.
    return {
        providerOrderId: null,
        providerStatus: 'queued',
        raw: null,
    };
}

function assertAdminContext(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication is required.');
    }

    if (!context.auth.token || context.auth.token.admin !== true) {
        throw new functions.https.HttpsError('permission-denied', 'Admin privileges are required.');
    }
}

exports.retryFailedPrintOrderSubmission = functions.https.onCall(async (data, context) => {
    assertAdminContext(context);

    const orderId = data?.orderId;
    if (!orderId) {
        throw new functions.https.HttpsError('invalid-argument', 'orderId is required.');
    }

    const orderRef = db.collection('printOrders').doc(orderId);
    const snapshot = await orderRef.get();
    if (!snapshot.exists) {
        throw new functions.https.HttpsError('not-found', 'Print order not found.');
    }

    const order = snapshot.data();
    if (order.provider === 'manual') {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'Order provider is manual; there is no external submission to retry.',
        );
    }

    if (['cancelled', 'shipped', 'delivered'].includes(order.status)) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            `Cannot retry submission for order in status ${order.status}.`,
        );
    }

    try {
        const providerSubmission = await submitPrintOrderToProvider(orderId, order);
        const mappedStatus = mapProviderStatusToAppStatus(providerSubmission.providerStatus);

        await orderRef.set({
            providerOrderId: providerSubmission.providerOrderId,
            providerStatus: providerSubmission.providerStatus,
            status: mappedStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await addPrintOrderEvent(orderRef, 'provider_submission_retried', {
            provider: order.provider,
            providerOrderId: providerSubmission.providerOrderId,
            providerStatus: providerSubmission.providerStatus,
            status: mappedStatus,
        });

        await db.collection('printProviderQueue').doc(orderId).set({
            status: providerSubmission.providerStatus,
            provider: order.provider,
            providerOrderId: providerSubmission.providerOrderId,
            retryCount: admin.firestore.FieldValue.increment(1),
            retryLastAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        return {
            success: true,
            orderId,
            providerStatus: providerSubmission.providerStatus,
            status: mappedStatus,
        };
    } catch (error) {
        await addPrintOrderEvent(orderRef, 'provider_submission_retry_failed', {
            provider: order.provider,
            error: String(error.message || error),
        });

        await db.collection('printProviderQueue').doc(orderId).set({
            status: 'queued_retry_failed',
            retryCount: admin.firestore.FieldValue.increment(1),
            retryLastAt: admin.firestore.FieldValue.serverTimestamp(),
            retryError: String(error.message || error),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        throw new functions.https.HttpsError('internal', `Retry failed: ${String(error.message || error)}`);
    }
});

exports.monitorPrintOrderSla = functions.pubsub.schedule('every 30 minutes').onRun(async () => {
    const now = Date.now();
    const pendingCutoff = admin.firestore.Timestamp.fromMillis(now - (24 * 60 * 60 * 1000));
    const processingCutoff = admin.firestore.Timestamp.fromMillis(now - (72 * 60 * 60 * 1000));

    const monitoredStatuses = ['pending', 'processing'];
    const snapshot = await db
        .collection('printOrders')
        .where('status', 'in', monitoredStatuses)
        .get();

    if (snapshot.empty) {
        return null;
    }

    const batch = db.batch();
    let breachedCount = 0;

    for (const doc of snapshot.docs) {
        const order = doc.data();
        const createdAt = order.createdAt;
        if (!createdAt || typeof createdAt.toMillis !== 'function') {
            continue;
        }

        let shouldFlag = false;
        let rule = '';

        if (order.status === 'pending' && createdAt.toMillis() <= pendingCutoff.toMillis()) {
            shouldFlag = true;
            rule = 'pending_over_24h';
        }

        if (order.status === 'processing' && createdAt.toMillis() <= processingCutoff.toMillis()) {
            shouldFlag = true;
            rule = 'processing_over_72h';
        }

        if (!shouldFlag) {
            continue;
        }

        breachedCount += 1;
        const alertRef = db.collection('printOrderAlerts').doc(doc.id);

        batch.set(doc.ref, {
            slaBreached: true,
            slaRule: rule,
            slaBreachedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        batch.set(alertRef, {
            orderId: doc.id,
            userId: order.userId || null,
            provider: order.provider || getPrintProviderName(),
            status: order.status,
            providerStatus: order.providerStatus || null,
            slaRule: rule,
            alertOpen: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }

    if (breachedCount > 0) {
        await batch.commit();
    }

    return { scanned: snapshot.size, breached: breachedCount };
});

function verifyPodWebhookSignature(request) {
    const secret = process.env.POD_WEBHOOK_SECRET;
    if (!secret) {
        return true;
    }

    const signature = request.headers['x-pod-signature'];
    if (!signature || !request.rawBody) {
        return false;
    }

    const expected = crypto
        .createHmac('sha256', secret)
        .update(request.rawBody)
        .digest('hex');

    if (signature.length !== expected.length) {
        return false;
    }

    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}

async function addPrintOrderEvent(orderRef, eventType, details = {}) {
    await orderRef.collection('events').add({
        eventType,
        ...details,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

async function queueManualPrintOrder(orderId, orderData) {
    await db.collection('printProviderQueue').doc(orderId).set({
        orderId,
        provider: getPrintProviderName(),
        status: 'queued',
        orderData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}

exports.createPrintOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in to create print orders.');
    }

    const required = [
        'artistUid',
        'artworkId',
        'artworkTitle',
        'artworkImageUrl',
        'printType',
        'size',
        'quantity',
        'shippingName',
        'shippingAddress',
        'shippingCity',
        'shippingCountry',
        'shippingPostalCode',
    ];

    for (const key of required) {
        if (!data[key]) {
            throw new functions.https.HttpsError('invalid-argument', `${key} is required.`);
        }
    }

    const quantity = Number(data.quantity);
    if (!Number.isInteger(quantity) || quantity <= 0 || quantity > 20) {
        throw new functions.https.HttpsError('invalid-argument', 'quantity must be an integer between 1 and 20.');
    }

    const productColor = data.productColor ? String(data.productColor).trim().toLowerCase() : null;
    if (data.printType === 'adult_hoodie_pullover') {
        if (!productColor || !HOODIE_COLORS.includes(productColor)) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                `productColor is required for adult_hoodie_pullover and must be one of: ${HOODIE_COLORS.join(', ')}.`,
            );
        }
    }

    const unitPrice = getServerUnitPrice(data.printType, data.size);
    if (unitPrice == null) {
        throw new functions.https.HttpsError('invalid-argument', 'Unsupported printType or size combination.');
    }

    const totalPrice = Number((unitPrice * quantity).toFixed(2));
    const now = admin.firestore.FieldValue.serverTimestamp();
    const provider = getPrintProviderName();

    const orderPayload = {
        userId: context.auth.uid,
        artistUid: data.artistUid,
        artworkId: data.artworkId,
        artworkTitle: data.artworkTitle,
        artworkImageUrl: data.artworkImageUrl,
        printType: data.printType,
        productColor,
        size: data.size,
        quantity,
        unitPrice,
        totalPrice,
        status: 'pending',
        provider,
        providerStatus: provider === 'manual' ? 'manual_review_required' : 'queued',
        shippingName: String(data.shippingName).trim(),
        shippingAddress: String(data.shippingAddress).trim(),
        shippingCity: String(data.shippingCity).trim(),
        shippingCountry: String(data.shippingCountry).trim(),
        shippingPostalCode: String(data.shippingPostalCode).trim(),
        createdAt: now,
        updatedAt: now,
    };

    const orderRef = await db.collection('printOrders').add(orderPayload);
    await addPrintOrderEvent(orderRef, 'order_created', {
        provider,
        providerStatus: orderPayload.providerStatus,
    });

    let providerSubmission = null;
    if (provider !== 'manual') {
        try {
            providerSubmission = await submitPrintOrderToProvider(orderRef.id, orderPayload);

            await orderRef.set({
                providerOrderId: providerSubmission.providerOrderId,
                providerStatus: providerSubmission.providerStatus,
                status: mapProviderStatusToAppStatus(providerSubmission.providerStatus),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            await addPrintOrderEvent(orderRef, 'provider_order_submitted', {
                provider,
                providerOrderId: providerSubmission.providerOrderId,
                providerStatus: providerSubmission.providerStatus,
            });
        } catch (error) {
            await orderRef.set({
                providerStatus: 'queued_submission_failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            await addPrintOrderEvent(orderRef, 'provider_submission_failed', {
                provider,
                error: String(error.message || error),
            });
        }
    }

    await queueManualPrintOrder(orderRef.id, {
        ...orderPayload,
        orderId: orderRef.id,
        providerSubmission,
    });

    return {
        orderId: orderRef.id,
        status: orderPayload.status,
        provider,
        providerStatus:
            providerSubmission?.providerStatus || orderPayload.providerStatus,
        totalPrice,
        message:
            providerSubmission != null
                ? 'Print order created and submitted to provider.'
                : 'Print order created and queued for provider fulfillment.',
    };
});

exports.cancelPrintOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in to cancel print orders.');
    }

    const orderId = data.orderId;
    if (!orderId) {
        throw new functions.https.HttpsError('invalid-argument', 'orderId is required.');
    }

    const orderRef = db.collection('printOrders').doc(orderId);
    const snapshot = await orderRef.get();
    if (!snapshot.exists) {
        throw new functions.https.HttpsError('not-found', 'Print order not found.');
    }

    const order = snapshot.data();
    if (order.userId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'You can only cancel your own orders.');
    }

    if (['shipped', 'delivered', 'cancelled'].includes(order.status)) {
        throw new functions.https.HttpsError('failed-precondition', 'This order can no longer be cancelled.');
    }

    await orderRef.set({
        status: 'cancelled',
        providerStatus: 'cancel_requested',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await addPrintOrderEvent(orderRef, 'order_cancelled_by_user', {
        providerStatus: 'cancel_requested',
    });

    await db.collection('printProviderQueue').doc(orderId).set({
        status: 'cancel_requested',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true, orderId, status: 'cancelled' };
});

function getStripeClient() {
    const secretKey = process.env.STRIPE_SECRET_KEY;

    if (!secretKey) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'STRIPE_SECRET_KEY is not configured for Cloud Functions.',
        );
    }

    return new Stripe(secretKey);
}

function getBaseAppUrl(data) {
    const configuredAppUrl = process.env.APP_URL || data.appUrl;

    if (!configuredAppUrl) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'APP_URL is required to create Stripe Checkout sessions.',
        );
    }

    return configuredAppUrl.replace(/\/$/, '');
}

function buildCheckoutUrls(data) {
    const baseUrl = getBaseAppUrl(data);

    return {
        successUrl:
            data.successUrl ||
            `${baseUrl}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
        cancelUrl: data.cancelUrl || `${baseUrl}/subscription/cancel`,
    };
}

function getFallbackRenewalWindow(billingPeriod) {
    const startDate = new Date();

    if (billingPeriod === 'yearly') {
        const renewalDate = new Date(startDate.getTime() + 365 * 24 * 60 * 60 * 1000);
        return { renewalDate, endDate: renewalDate };
    }

    if (billingPeriod === 'lifetime') {
        return { renewalDate: lifetimeRenewalDate, endDate: null };
    }

    const renewalDate = new Date(startDate.getTime() + 30 * 24 * 60 * 60 * 1000);
    return { renewalDate, endDate: renewalDate };
}

async function syncUserSubscriptionSummary({
    userId,
    tier,
    billingPeriod,
    renewalDate,
    stripeCustomerId,
    isActive,
}) {
    await db.collection('users').doc(userId).set(
        {
            subscriptionTier: tier,
            subscriptionActive: isActive,
            subscriptionBillingPeriod: billingPeriod,
            subscriptionRenewalDate: admin.firestore.Timestamp.fromDate(renewalDate),
            stripeCustomerId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
    );
}

async function deactivateActiveSubscriptions(userId) {
    const activeSubscriptions = await db
        .collection('subscriptions')
        .where('userId', '==', userId)
        .where('isActive', '==', true)
        .get();

    if (activeSubscriptions.empty) {
        return;
    }

    const batch = db.batch();
    activeSubscriptions.docs.forEach((doc) => {
        batch.update(doc.ref, {
            isActive: false,
            endDate: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    await batch.commit();
}

async function createSubscriptionRecord({
    stripe,
    session,
    eventCreated,
}) {
    const metadata = session.metadata || {};
    const userId = session.client_reference_id || metadata.userId;
    const tier = metadata.tier || 'basic';
    const billingPeriod = metadata.billingPeriod || (tier === 'elite' ? 'lifetime' : 'monthly');
    const stripeCustomerId = typeof session.customer === 'string' ? session.customer : '';
    const stripeReferenceId = session.mode === 'subscription'
        ? (typeof session.subscription === 'string' ? session.subscription : session.id)
        : (typeof session.payment_intent === 'string' ? session.payment_intent : session.id);

    if (!userId) {
        throw new Error(`Checkout session ${session.id} is missing a user reference.`);
    }

    let renewalWindow = getFallbackRenewalWindow(billingPeriod);

    if (session.mode === 'subscription' && typeof session.subscription === 'string') {
        const stripeSubscription = await stripe.subscriptions.retrieve(session.subscription);
        if (stripeSubscription.current_period_end) {
            const renewalDate = new Date(stripeSubscription.current_period_end * 1000);
            renewalWindow = { renewalDate, endDate: renewalDate };
        }
    }

    await deactivateActiveSubscriptions(userId);

    const subscriptionRecord = {
        userId,
        tier,
        price: (session.amount_total || 0) / 100,
        billingPeriod,
        isActive: true,
        startDate: admin.firestore.Timestamp.fromMillis(eventCreated * 1000),
        endDate: renewalWindow.endDate
            ? admin.firestore.Timestamp.fromDate(renewalWindow.endDate)
            : null,
        stripeSubscriptionId: stripeReferenceId,
        stripeCustomerId,
        renewalDate: admin.firestore.Timestamp.fromDate(renewalWindow.renewalDate),
        postsUploaded: 0,
        isMentor: tier === 'elite',
        checkoutSessionId: session.id,
        createdAt: admin.firestore.Timestamp.fromMillis(eventCreated * 1000),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('subscriptions').doc(stripeReferenceId).set(subscriptionRecord, { merge: true });

    await syncUserSubscriptionSummary({
        userId,
        tier,
        billingPeriod,
        renewalDate: renewalWindow.renewalDate,
        stripeCustomerId,
        isActive: true,
    });

    await db.collection('checkoutSessions').doc(session.id).set(
        {
            status: 'completed',
            stripeCustomerId,
            stripeSubscriptionId: stripeReferenceId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
    );
}

async function createArtworkOrderRecord({
    session,
    eventCreated,
}) {
    const metadata = session.metadata || {};
    const userId = session.client_reference_id || metadata.userId;

    if (!userId) {
        throw new Error(`Artwork checkout session ${session.id} is missing a user reference.`);
    }

    const orderId = typeof session.payment_intent === 'string' ? session.payment_intent : session.id;

    await db.collection('artworkOrders').doc(orderId).set(
        {
            userId,
            artistName: metadata.artistName || '',
            artworkId: metadata.artworkId || '',
            artworkTitle: metadata.artworkTitle || 'Untitled artwork',
            amount: (session.amount_total || 0) / 100,
            currency: session.currency || 'usd',
            stripeSessionId: session.id,
            stripePaymentIntentId: typeof session.payment_intent === 'string' ? session.payment_intent : '',
            stripeCustomerId: typeof session.customer === 'string' ? session.customer : '',
            checkoutType: 'artwork',
            status: 'paid',
            createdAt: admin.firestore.Timestamp.fromMillis(eventCreated * 1000),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
    );

    await db.collection('checkoutSessions').doc(session.id).set(
        {
            status: 'completed',
            checkoutType: 'artwork',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
    );
}

async function markSubscriptionInactive(subscriptionId, status) {
    const matchingSubscriptions = await db
        .collection('subscriptions')
        .where('stripeSubscriptionId', '==', subscriptionId)
        .get();

    if (matchingSubscriptions.empty) {
        return;
    }

    const batch = db.batch();
    for (const doc of matchingSubscriptions.docs) {
        batch.set(
            doc.ref,
            {
                isActive: false,
                stripeStatus: status,
                endDate: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
        );

        const data = doc.data();
        const userId = data.userId;
        if (userId) {
            batch.set(
                db.collection('users').doc(userId),
                {
                    subscriptionActive: false,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true },
            );
        }
    }

    await batch.commit();
}

async function syncStripeSubscriptionStatus(subscription) {
    const matchingSubscriptions = await db
        .collection('subscriptions')
        .where('stripeSubscriptionId', '==', subscription.id)
        .get();

    if (matchingSubscriptions.empty) {
        return;
    }

    const batch = db.batch();
    for (const doc of matchingSubscriptions.docs) {
        batch.set(
            doc.ref,
            {
                stripeStatus: subscription.status,
                cancelAtPeriodEnd: !!subscription.cancel_at_period_end,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
        );
    }
    await batch.commit();
}

exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in to start checkout.');
    }

    const { priceId, email, tier, billingPeriod, lookupKey } = data;
    if (!priceId || !email || !tier || !billingPeriod) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'priceId, email, tier, and billingPeriod are required.',
        );
    }

    const stripe = getStripeClient();
    const mode = tier === 'elite' ? 'payment' : 'subscription';
    const { successUrl, cancelUrl } = buildCheckoutUrls(data);

    try {
        const session = await stripe.checkout.sessions.create({
            mode,
            customer_email: email,
            line_items: [{
                price: priceId,
                quantity: 1,
            }],
            billing_address_collection: 'auto',
            allow_promotion_codes: true,
            client_reference_id: context.auth.uid,
            success_url: successUrl,
            cancel_url: cancelUrl,
            metadata: {
                userId: context.auth.uid,
                tier,
                billingPeriod,
                lookupKey: lookupKey || '',
                email,
                displayName: data.name || '',
            },
        });

        await db.collection('checkoutSessions').doc(session.id).set({
            userId: context.auth.uid,
            email,
            name: data.name || '',
            tier,
            billingPeriod,
            lookupKey: lookupKey || '',
            priceId,
            provider: 'stripe',
            stripeSessionId: session.id,
            stripeCustomerId: typeof session.customer === 'string' ? session.customer : '',
            checkoutUrl: session.url || null,
            status: 'created',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (typeof session.customer === 'string' && session.customer) {
            await db.collection('users').doc(context.auth.uid).set(
                {
                    stripeCustomerId: session.customer,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true },
            );
        }

        return {
            sessionId: session.id,
            checkoutUrl: session.url || null,
            customerId: typeof session.customer === 'string' ? session.customer : '',
            message: 'Stripe Checkout session created. Complete payment before the subscription becomes active.',
        };
    } catch (error) {
        console.error('Error creating Stripe Checkout session:', error);
        throw new functions.https.HttpsError('internal', 'Failed to create Stripe Checkout session.');
    }
});

exports.createArtworkCheckoutSession = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in to start artwork checkout.');
    }

    const { email, amount, currency, artworkId, artworkTitle, artistName } = data;
    if (!email || !amount || !artworkTitle) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'email, amount, and artworkTitle are required.',
        );
    }

    const numericAmount = Number(amount);
    if (!Number.isFinite(numericAmount) || numericAmount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'amount must be a positive number.');
    }

    const stripe = getStripeClient();
    const baseUrl = getBaseAppUrl(data);
    const successUrl =
        data.successUrl ||
        `${baseUrl}/artwork/success?session_id={CHECKOUT_SESSION_ID}`;
    const cancelUrl = data.cancelUrl || `${baseUrl}/artwork/cancel`;

    try {
        const session = await stripe.checkout.sessions.create({
            mode: 'payment',
            customer_email: email,
            line_items: [
                {
                    quantity: 1,
                    price_data: {
                        currency: (currency || 'usd').toLowerCase(),
                        unit_amount: Math.round(numericAmount * 100),
                        product_data: {
                            name: `Artwork: ${artworkTitle}`,
                            description: artistName
                                ? `Original artwork by ${artistName}`
                                : 'Original artwork purchase',
                            metadata: {
                                artworkId: artworkId || '',
                                artworkTitle,
                            },
                        },
                    },
                },
            ],
            billing_address_collection: 'auto',
            allow_promotion_codes: true,
            client_reference_id: context.auth.uid,
            success_url: successUrl,
            cancel_url: cancelUrl,
            metadata: {
                checkoutType: 'artwork',
                userId: context.auth.uid,
                email,
                name: data.name || '',
                artworkId: artworkId || '',
                artworkTitle,
                artistName: artistName || '',
            },
        });

        await db.collection('checkoutSessions').doc(session.id).set({
            userId: context.auth.uid,
            email,
            name: data.name || '',
            checkoutType: 'artwork',
            artworkId: artworkId || '',
            artworkTitle,
            artistName: artistName || '',
            amount: numericAmount,
            currency: (currency || 'usd').toLowerCase(),
            provider: 'stripe',
            stripeSessionId: session.id,
            stripeCustomerId: typeof session.customer === 'string' ? session.customer : '',
            checkoutUrl: session.url || null,
            status: 'created',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (typeof session.customer === 'string' && session.customer) {
            await db.collection('users').doc(context.auth.uid).set(
                {
                    stripeCustomerId: session.customer,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true },
            );
        }

        return {
            sessionId: session.id,
            checkoutUrl: session.url || null,
            customerId: typeof session.customer === 'string' ? session.customer : '',
            message: 'Artwork Stripe Checkout session created. Complete payment to place your order.',
        };
    } catch (error) {
        console.error('Error creating artwork Stripe Checkout session:', error);
        throw new functions.https.HttpsError('internal', 'Failed to create artwork checkout session.');
    }
});

exports.handleStripeWebhook = functions.https.onRequest(async (request, response) => {
    if (request.method !== 'POST') {
        response.status(405).send('Method Not Allowed');
        return;
    }

    const signature = request.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!signature || !webhookSecret) {
        response.status(500).send('Stripe webhook secret is not configured.');
        return;
    }

    let event;
    try {
        const stripe = getStripeClient();
        event = stripe.webhooks.constructEvent(request.rawBody, signature, webhookSecret);

        switch (event.type) {
            case 'checkout.session.completed': {
                const session = event.data.object;
                if (session?.metadata?.checkoutType === 'artwork') {
                    await createArtworkOrderRecord({
                        session,
                        eventCreated: event.created,
                    });
                } else {
                    await createSubscriptionRecord({
                        stripe,
                        session,
                        eventCreated: event.created,
                    });
                }
                break;
            }
            case 'checkout.session.expired': {
                const session = event.data.object;
                await db.collection('checkoutSessions').doc(session.id).set(
                    {
                        status: 'expired',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true },
                );
                break;
            }
            case 'customer.subscription.deleted': {
                const subscription = event.data.object;
                await markSubscriptionInactive(subscription.id, subscription.status);
                break;
            }
            case 'customer.subscription.updated': {
                const subscription = event.data.object;
                if (subscription.status === 'canceled') {
                    await markSubscriptionInactive(subscription.id, subscription.status);
                    break;
                }

                await syncStripeSubscriptionStatus(subscription);
                break;
            }
            default:
                break;
        }

        response.json({ received: true });
    } catch (error) {
        console.error('Stripe webhook error:', error);
        response.status(400).send(`Webhook Error: ${error.message}`);
    }
});

exports.handlePrintProviderWebhook = functions.https.onRequest(async (request, response) => {
    if (request.method !== 'POST') {
        response.status(405).send('Method Not Allowed');
        return;
    }

    if (!verifyPodWebhookSignature(request)) {
        response.status(401).send('Invalid webhook signature.');
        return;
    }

    try {
        const body = request.body || {};
        const normalized = body.result || body;
        const providerOrderId =
            normalized.providerOrderId ||
            normalized.externalOrderId ||
            normalized.id ||
            null;
        const orderId =
            normalized.orderId ||
            normalized.external_id ||
            normalized.externalOrderId ||
            null;
        const providerStatus = normalized.status || body.status || 'submitted';
        const trackingNumber =
            normalized.trackingNumber ||
            normalized.tracking_number ||
            normalized.shipments?.[0]?.tracking_number ||
            null;
        const trackingUrl =
            normalized.trackingUrl ||
            normalized.tracking_url ||
            normalized.shipments?.[0]?.tracking_url ||
            null;
        const provider = body.provider || getPrintProviderName();

        let orderQuery = null;
        if (orderId) {
            orderQuery = await db.collection('printOrders').doc(orderId).get();
        }

        let orderRef = null;
        if (orderQuery && orderQuery.exists) {
            orderRef = orderQuery.ref;
        } else if (providerOrderId) {
            const snap = await db
                .collection('printOrders')
                .where('providerOrderId', '==', providerOrderId)
                .limit(1)
                .get();

            if (!snap.empty) {
                orderRef = snap.docs[0].ref;
            }
        }

        if (!orderRef) {
            response.status(404).send('Order not found.');
            return;
        }

        const status = mapProviderStatusToAppStatus(providerStatus);
        await orderRef.set({
            provider,
            providerOrderId,
            providerStatus,
            status,
            trackingNumber,
            trackingUrl,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await addPrintOrderEvent(orderRef, 'provider_status_updated', {
            provider,
            providerOrderId,
            providerStatus,
            status,
            trackingNumber,
            trackingUrl,
        });

        await db.collection('printProviderQueue').doc(orderRef.id).set({
            status: providerStatus,
            provider,
            providerOrderId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        response.json({ received: true, orderId: orderRef.id, status, providerStatus });
    } catch (error) {
        console.error('Print provider webhook error:', error);
        response.status(500).send('Failed to process print provider webhook.');
    }
});

// Cloud Function: When a message is created in a collector conversation,
// increment the recipient's unread count and update conversation metadata.
exports.onCollectorConversationMessage = functions.firestore
    .document('collectorConversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const { conversationId } = context.params;
        const message = snap.data();

        if (!message || !message.senderUid) {
            console.error('Invalid message data:', message);
            return;
        }

        try {
            // Get the conversation to determine recipient.
            const conversationRef = db.collection('collectorConversations').doc(conversationId);
            const conversationSnap = await conversationRef.get();
            if (!conversationSnap.exists) {
                console.error('Conversation not found:', conversationId);
                return;
            }

            const conversationData = conversationSnap.data();
            const { buyerUid, artistUid } = conversationData;
            const senderUid = message.senderUid;

            // Determine the receiver (participant other than the sender).
            const receiverUid = senderUid === buyerUid ? artistUid : buyerUid;

            if (!receiverUid) {
                console.error('Could not determine receiver for message in conversation:', conversationId);
                return;
            }

            // Update conversation metadata:
            // - Mark sender as read (lastReadAtBy[senderUid] = now, unreadCountBy[senderUid] = 0)
            // - Increment receiver's unread count
            // - Update latest message fields
            const now = admin.firestore.Timestamp.now();
            await conversationRef.update({
                latestMessage: message.text || '',
                latestSenderUid: senderUid,
                lastMessageAt: now,
                updatedAt: now,
                [`lastReadAtBy.${senderUid}`]: now,
                [`unreadCountBy.${senderUid}`]: 0,
                [`unreadCountBy.${receiverUid}`]: admin.firestore.FieldValue.increment(1),
            });

            console.log(
                `Updated conversation metadata after message from ${senderUid} in ${conversationId}`
            );
        } catch (error) {
            console.error('Error processing message creation:', error);
        }
    });

// Cloud Function: When a conversation status is updated, validate it and
// ensure the status change message increments unread counts appropriately.
exports.onCollectorConversationStatusUpdate = functions.firestore
    .document('collectorConversations/{conversationId}')
    .onUpdate(async (change, context) => {
        const { conversationId } = context.params;
        const before = change.before.data();
        const after = change.after.data();

        if (!before || !after) {
            return;
        }

        const beforeStatus = before.status;
        const afterStatus = after.status;

        // Only process if status actually changed.
        if (beforeStatus === afterStatus) {
            return;
        }

        const validStatuses = ['open', 'reviewing', 'quoted', 'accepted', 'closed'];
        if (!validStatuses.includes(afterStatus)) {
            console.error(`Invalid status transition: ${beforeStatus} -> ${afterStatus}`);
            // Could trigger an alert or revert here if necessary.
            return;
        }

        try {
            // Optionally log the status transition for audit purposes.
            console.log(
                `Status updated in conversation ${conversationId}: ${beforeStatus} -> ${afterStatus}`
            );

            // If a status change message was created by the client (checked via the messages subcollection),
            // the onCollectorConversationMessage function will handle the unread increments.
            // This function serves as a validation layer and audit point.
        } catch (error) {
            console.error('Error processing status update:', error);
        }
    });
