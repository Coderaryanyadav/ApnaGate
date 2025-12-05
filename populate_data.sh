#!/bin/bash

# Crescent Gate - Sample Data Population Script
# This script creates test users via Firebase Console

echo "🏢 Crescent Gate - Sample Data Setup"
echo "======================================"
echo ""
echo "Building Structure:"
echo "- 2 Wings: A & B"
echo "- 12 Floors per wing"
echo "- 4 Flats per floor"
echo "- Total: 96 flats"
echo ""
echo "Sample Users to Create:"
echo ""
echo "1. ADMIN"
echo "   Email: admin@crescentgate.com"
echo "   Password: admin123"
echo ""
echo "2. GUARDS (2)"
echo "   - guard1@crescentgate.com / guard123"
echo "   - guard2@crescentgate.com / guard123"
echo ""
echo "3. SAMPLE RESIDENTS (Wing A, Floor 1)"
echo "   Flat A-101 (Owner):"
echo "   - Email: owner.a101@test.com"
echo "   - Password: test123"
echo "   - Family: Rajesh Kumar, Priya Kumar, Aarav Kumar"
echo ""
echo "   Flat A-102 (Owner):"
echo "   - Email: owner.a102@test.com"
echo "   - Password: test123"
echo "   - Family: Amit Shah, Neha Shah"
echo ""
echo "   Flat A-103 (Renter):"
echo "   - Email: renter.a103@test.com"
echo "   - Password: test123"
echo "   - Family: Vikram Singh, Anjali Singh, Rohan Singh"
echo ""
echo "   Flat A-104 (Owner):"
echo "   - Email: owner.a104@test.com"
echo "   - Password: test123"
echo "   - Family: Suresh Patel, Kavita Patel, Diya Patel, Arjun Patel"
echo ""
echo "4. SAMPLE RESIDENTS (Wing B, Floor 12 - Top Floor)"
echo "   Flat B-1201 (Owner - Penthouse):"
echo "   - Email: owner.b1201@test.com"
echo "   - Password: test123"
echo "   - Family: Ramesh Gupta, Sunita Gupta, Karan Gupta, Simran Gupta, Nisha Gupta"
echo ""
echo "======================================"
echo ""
echo "📋 MANUAL STEPS:"
echo ""
echo "1. Go to Firebase Console:"
echo "   https://console.firebase.google.com/project/crescentgate-3d730/authentication/users"
echo ""
echo "2. For each user above, click 'Add user' and create with email/password"
echo ""
echo "3. After creating all users, go to Firestore:"
echo "   https://console.firebase.google.com/project/crescentgate-3d730/firestore/data"
echo ""
echo "4. In the 'users' collection, add documents with these UIDs (copy from Auth):"
echo ""
echo "   Admin Document:"
echo "   {
  \"name\": \"Admin User\",
  \"phone\": \"+919876543210\",
  \"flatNumber\": null,
  \"wing\": null,
  \"role\": \"admin\",
  \"userType\": null,
  \"ownerId\": null,
  \"familyMembers\": null,
  \"createdAt\": <timestamp>
}"
echo ""
echo "   Guard1 Document:"
echo "   {
  \"name\": \"Security Guard 1\",
  \"phone\": \"+919876543211\",
  \"flatNumber\": null,
  \"wing\": null,
  \"role\": \"guard\",
  \"userType\": null,
  \"ownerId\": null,
  \"familyMembers\": null,
  \"createdAt\": <timestamp>
}"
echo ""
echo "   Resident A-101 (Owner):"
echo "   {
  \"name\": \"Rajesh Kumar\",
  \"phone\": \"+919876543212\",
  \"flatNumber\": \"101\",
  \"wing\": \"A\",
  \"role\": \"resident\",
  \"userType\": \"owner\",
  \"ownerId\": null,
  \"familyMembers\": [\"Rajesh Kumar\", \"Priya Kumar\", \"Aarav Kumar\"],
  \"createdAt\": <timestamp>
}"
echo ""
echo "   Resident A-103 (Renter):"
echo "   {
  \"name\": \"Vikram Singh\",
  \"phone\": \"+919876543214\",
  \"flatNumber\": \"103\",
  \"wing\": \"A\",
  \"role\": \"resident\",
  \"userType\": \"renter\",
  \"ownerId\": \"<UID_of_owner_if_exists>\",
  \"familyMembers\": [\"Vikram Singh\", \"Anjali Singh\", \"Rohan Singh\"],
  \"createdAt\": <timestamp>
}"
echo ""
echo "======================================"
echo ""
echo "✅ OR USE THE APP!"
echo ""
echo "Once you login as admin, you can use the 'Manage Users' feature"
echo "to create all users directly from the app!"
echo ""
echo "Just run: flutter run"
echo "Login as admin and click 'Manage Users' → 'Add'"
echo ""
