const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

// Dummy users data
const users = [
    {
        email: 'admin@crescentgate.com',
        password: 'admin123',
        data: {
            name: 'Admin User',
            phone: '+919876543210',
            flatNumber: null,
            wing: null,
            role: 'admin',
            userType: null,
            ownerId: null,
            familyMembers: null
        }
    },
    {
        email: 'guard1@crescentgate.com',
        password: 'guard123',
        data: {
            name: 'Ramesh Sharma',
            phone: '+919876543211',
            flatNumber: null,
            wing: null,
            role: 'guard',
            userType: null,
            ownerId: null,
            familyMembers: null
        }
    },
    {
        email: 'guard2@crescentgate.com',
        password: 'guard123',
        data: {
            name: 'Suresh Kumar',
            phone: '+919876543212',
            flatNumber: null,
            wing: null,
            role: 'guard',
            userType: null,
            ownerId: null,
            familyMembers: null
        }
    },
    {
        email: 'a101@test.com',
        password: 'test123',
        data: {
            name: 'Rajesh Kumar',
            phone: '+919876543220',
            flatNumber: '101',
            wing: 'A',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Rajesh Kumar', 'Priya Kumar', 'Aarav Kumar']
        }
    },
    {
        email: 'a102@test.com',
        password: 'test123',
        data: {
            name: 'Amit Shah',
            phone: '+919876543221',
            flatNumber: '102',
            wing: 'A',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Amit Shah', 'Neha Shah']
        }
    },
    {
        email: 'a103@test.com',
        password: 'test123',
        data: {
            name: 'Vikram Singh',
            phone: '+919876543222',
            flatNumber: '103',
            wing: 'A',
            role: 'resident',
            userType: 'renter',
            ownerId: null,
            familyMembers: ['Vikram Singh', 'Anjali Singh', 'Rohan Singh']
        }
    },
    {
        email: 'a104@test.com',
        password: 'test123',
        data: {
            name: 'Suresh Patel',
            phone: '+919876543223',
            flatNumber: '104',
            wing: 'A',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Suresh Patel', 'Kavita Patel', 'Diya Patel', 'Arjun Patel']
        }
    },
    {
        email: 'a201@test.com',
        password: 'test123',
        data: {
            name: 'Manoj Verma',
            phone: '+919876543224',
            flatNumber: '201',
            wing: 'A',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Manoj Verma', 'Sita Verma', 'Rahul Verma']
        }
    },
    {
        email: 'b301@test.com',
        password: 'test123',
        data: {
            name: 'Deepak Joshi',
            phone: '+919876543225',
            flatNumber: '301',
            wing: 'B',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Deepak Joshi', 'Meera Joshi']
        }
    },
    {
        email: 'b1201@test.com',
        password: 'test123',
        data: {
            name: 'Ramesh Gupta',
            phone: '+919876543226',
            flatNumber: '1201',
            wing: 'B',
            role: 'resident',
            userType: 'owner',
            ownerId: null,
            familyMembers: ['Ramesh Gupta', 'Sunita Gupta', 'Karan Gupta', 'Simran Gupta', 'Nisha Gupta']
        }
    }
];

async function createUser(email, password, userData) {
    try {
        // Create auth user
        const userRecord = await auth.createUser({
            email: email,
            password: password,
            displayName: userData.name
        });

        console.log(`✅ Created auth user: ${email} (UID: ${userRecord.uid})`);

        // Create Firestore document
        await db.collection('users').doc(userRecord.uid).set({
            ...userData,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ Created Firestore doc for: ${userData.name}`);
        return userRecord.uid;

    } catch (error) {
        if (error.code === 'auth/email-already-exists') {
            console.log(`⚠️  User ${email} already exists, skipping...`);
            // Get existing user and update Firestore
            const existingUser = await auth.getUserByEmail(email);
            await db.collection('users').doc(existingUser.uid).set({
                ...userData,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            console.log(`✅ Updated Firestore doc for: ${userData.name}`);
            return existingUser.uid;
        } else {
            console.error(`❌ Error creating ${email}:`, error.message);
            throw error;
        }
    }
}

async function populateData() {
    console.log('🚀 Starting data population...\n');

    let successCount = 0;
    let errorCount = 0;

    for (const user of users) {
        try {
            await createUser(user.email, user.password, user.data);
            successCount++;
            console.log('');
        } catch (error) {
            errorCount++;
            console.log('');
        }
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✨ Data Population Complete!');
    console.log(`✅ Success: ${successCount}`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('📋 Login Credentials:');
    console.log('Admin: admin@crescentgate.com / admin123');
    console.log('Guard1: guard1@crescentgate.com / guard123');
    console.log('Guard2: guard2@crescentgate.com / guard123');
    console.log('Residents: a101@test.com, a102@test.com, etc. / test123\n');

    process.exit(0);
}

// Run the script
populateData().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});
