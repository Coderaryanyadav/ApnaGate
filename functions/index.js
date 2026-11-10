// ============================================
// 🔔 CLOUD FUNCTIONS - NOTIFICATION SYSTEM
// ============================================
// 
// ⚠️ STATUS: NOT DEPLOYED (Requires Firebase Blaze Plan)
// 
// These functions are ready but commented as inactive.
// The app works perfectly WITHOUT these functions.
// 
// WHEN TO ACTIVATE:
// 1. Upgrade Firebase to Blaze plan
// 2. Run: firebase deploy --only functions
// 3. No code changes needed in the app
//
// ============================================

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ============================================
// 🚀 FUNCTION 1: Notify Resident on New Visitor
// ============================================
// Triggers when a guard adds a visitor request
// Sends push notification to the resident
//
exports.sendVisitorNotification = functions.firestore
    .document("visitorRequests/{requestId}")
    .onCreate(async (snap, context) => {
        const request = snap.data();
        const residentId = request.residentId;

        if (!residentId) return;

        // Get Resident's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(residentId).get();
        if (!userDoc.exists) return;

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) return;

        const payload = {
            token: fcmToken,
            data: {
                type: "visitor_request",
                requestId: context.params.requestId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            notification: {
                title: "Visitor Arriving! 🏃",
                body: `${request.visitorName} is here for ${request.purpose}. Approve entry?`,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    priority: "max",
                    visibility: "public",
                },
            },
        };

        return admin.messaging().send(payload);
    });

// ============================================
// 📢 FUNCTION 2: Notify All Residents on New Notice
// ============================================
// Triggers when admin posts a notice
// Broadcasts to all residents via topic
//
exports.sendNoticeNotification = functions.firestore
    .document("notices/{noticeId}")
    .onCreate(async (snap, context) => {
        const notice = snap.data();

        const payload = {
            topic: "residents",
            data: {
                type: "notice",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            notification: {
                title: `📢 New Notice: ${notice.title}`,
                body: notice.description,
            },
        };

        return admin.messaging().send(payload);
    });

// ============================================
// � FUNCTION 3: SOS Alert Broadcast
// ============================================
// Triggers when an SOS is created
// Notifies all Guards & Admins immediately
//
exports.sendSOSNotification = functions.firestore
    .document("sosAlerts/{alertId}")
    .onCreate(async (snap, context) => {
        const alert = snap.data();

        // Strategy: Send to 'security_alert' topic 
        // (Ensure Guards/Admins subscribe to this topic in the app)
        // OR Loop through users (Better for specific targeting if topics unreliable)

        const payload = {
            topic: "security_alerts",
            data: {
                type: "sos_alert",
                alertId: context.params.alertId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            notification: {
                title: "🚨 SOS EMERGENCY ALERT 🚨",
                body: `Emergency at Flat ${alert.flatNumber}. CHECK IMMEDIATELY.`,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "sos_channel",
                    priority: "max",
                    visibility: "public",
                    sound: "siren", // Optional: Custom sound
                },
            },
        };

        return admin.messaging().send(payload);
    });

// ============================================
// ✅ FUNCTION 4: Notify Guard/Admin on Approval
// ============================================
// Triggers when resident approves/rejects visitor
// Notifies Guardians
//
exports.sendVisitorApprovalNotification = functions.firestore
    .document("visitorRequests/{requestId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Only trigger if status changed to 'approved' or 'rejected'
        if (oldData.status === newData.status) return null;
        if (newData.status !== 'approved' && newData.status !== 'rejected') return null;

        const status = newData.status.toUpperCase();
        const emoji = status === 'APPROVED' ? '✅' : '🚫';

        const payload = {
            topic: "guards", // Notify all guards
            notification: {
                title: `Visitor ${status} ${emoji}`,
                body: `${newData.visitorName} for ${newData.wing}-${newData.flatNumber} has been ${status}.`,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    priority: "high",
                },
            },
        };

        return admin.messaging().send(payload);
    });

// ============================================

// ============================================
// �📝 HOW IT WORKS (When Deployed)
// ============================================
//
// 1. Guard adds visitor → sendVisitorNotification triggers
//    → Resident gets instant push notification
//    → Resident sees approval dialog in app
//
// 2. Admin posts notice → sendNoticeNotification triggers
//    → All residents get push notification
//    → Residents see new notice in Notice Board
//
// 3. SOS Triggered → sendSOSNotification triggers
//    → Guards & Admins get LOUD alarm notification
//
// ============================================
// 🔒 SECURITY NOTES
// ============================================
//
// - Functions run with admin privileges
// - No HTTP endpoints exposed (Firestore triggers only)
// - Rate limited by Firebase (max 1000 calls/min)
// - Tokens validated by Firebase Messaging
//
// ============================================
// 💰 COST ESTIMATE (Blaze Plan)
// ============================================
//
// Free Tier: 2M invocations/month
// Beyond Free: $0.40 per 1M invocations
//
// Expected usage (100 residents):
// - ~500 visitor notifications/month
// - ~20 notice broadcasts/month
// - Total: ~520 invocations/month = FREE
//
// ============================================
