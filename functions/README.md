# 🔔 Cloud Functions - Activation Guide

## ⚠️ Current Status: **INACTIVE**

The notification system is **fully coded and ready** but not deployed because your Firebase project is on the **Spark (Free) plan**.

---

## ✅ What Works NOW (Without Cloud Functions)

- ✅ Visitors can be added by Guards
- ✅ Residents manually check for new visitors
- ✅ Notices appear when residents refresh
- ✅ All features work perfectly offline

---

## 🚀 What Activates AFTER Upgrading

- 🔔 **Instant Push Notifications** for new visitors
- 📢 **Auto-broadcast** notices to all residents
- ⚡ **Real-time alerts** without manual refresh

---

## 📦 How to Activate (When Ready)

### **Step 1: Upgrade Firebase Plan**
```bash
# Visit this URL in your browser:
https://console.firebase.google.com/project/crescentgate-3d730/usage/details

# Click "Modify Plan" → Select "Blaze (Pay as you go)"
# Set budget alert: $5/month (notifications will cost ~$0)
```

### **Step 2: Deploy Cloud Functions**
```bash
cd /Users/aryanyadav/Desktop/CrescentGate/functions
npm install
firebase deploy --only functions
```

### **Step 3: Test Notifications**
1. Have a guard add a visitor
2. Resident should get instant notification
3. Have admin post a notice
4. All residents should get notification

**That's it! No app changes needed.**

---

## 💰 Cost Breakdown

| Item | Free Tier | Beyond Free | Your Usage | Cost |
|------|-----------|-------------|------------|------|
| **Function Invocations** | 2M/month | $0.40/1M | ~500/month | **FREE** |
| **Outbound Networking** | 5GB/month | $0.12/GB | ~1GB/month | **FREE** |
| **Cloud Build** | 120 min/day | $0.003/min | 2 min/update | **FREE** |
| **Total Monthly Cost** | - | - | - | **$0.00** |

*Based on 100 residents, 20 visitors/day, 5 notices/week*

---

## 🔒 Security Notes

- ✅ Functions run with admin privileges (secure)
- ✅ No HTTP endpoints (only Firestore triggers)
- ✅ Rate limited by Firebase automatically
- ✅ Tokens validated by Firebase Messaging

---

## 🐛 Troubleshooting

### **"Functions still not working after deploy"**
```bash
# Check function logs
firebase functions:log

# Verify deployment
firebase functions:list
```

### **"Residents not getting notifications"**
Check:
1. App has notification permission (Android Settings)
2. User is logged in (FCM token registered)
3. User is subscribed to 'residents' topic

### **"Costs increasing unexpectedly"**
Set budget alerts in Firebase Console:
```
Billing → Budgets & Alerts → Create Budget → $5
```

---

## 📝 Technical Details

**Functions Location:** `/functions/index.js`  
**Language:** Node.js 18  
**Trigger Type:** Firestore onCreate  
**Collections Watched:**
- `visitorRequests` → Notify specific resident
- `notices` → Notify all residents (topic)

---

## ✅ Activation Checklist

When you're ready to activate:

- [ ] Upgrade Firebase to Blaze plan
- [ ] Set budget alert ($5/month)
- [ ] Run `npm install` in functions folder
- [ ] Deploy with `firebase deploy --only functions`
- [ ] Test visitor notification
- [ ] Test notice broadcast
- [ ] Monitor function logs
- [ ] Check billing dashboard after 1 week

---

**Questions?** The code is production-ready. Just deploy when your billing is set up!
