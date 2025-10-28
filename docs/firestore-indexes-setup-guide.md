# Firestore Indexes Setup Guide

## Overview
This guide walks you through creating the required Firestore composite indexes for the event categories feature.

## Prerequisites
- Firebase project: `vibe-a0d7b`
- Firebase CLI installed (optional, for automated deployment)
- Access to Firebase Console with appropriate permissions

---

## Method 1: Firebase CLI (Recommended - Automated)

### Step 1: Install Firebase CLI
If you don't have Firebase CLI installed:

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Initialize Firebase (if not already done)
```bash
cd /Users/denol/specifyTry/vibe_app
firebase init firestore
```

When prompted:
- Select "Use an existing project"
- Choose `vibe-a0d7b`
- Accept default Firestore rules file
- Accept default indexes file

### Step 4: Deploy Indexes
The `firestore.indexes.json` file has been created. Deploy it:

```bash
cd /Users/denol/specifyTry/vibe_app
firebase deploy --only firestore:indexes
```

Expected output:
```
=== Deploying to 'vibe-a0d7b'...

i  firestore: reading indexes from firestore.indexes.json...
✔  firestore: deployed indexes in firestore.indexes.json successfully

✔  Deploy complete!
```

### Step 5: Wait for Index Build
- Indexes will start building automatically
- Build time: 5-15 minutes (depends on existing data)
- You can monitor progress in Firebase Console

### Step 6: Verify Deployment
```bash
firebase firestore:indexes
```

This will list all indexes and their status.

---

## Method 2: Firebase Console (Manual)

### Index 1: Category + Geohash + Status + Time

1. Go to [Firebase Console](https://console.firebase.google.com/project/vibe-a0d7b/firestore/indexes)

2. Click **"Create Index"** button

3. Configure the index:
   - **Collection ID**: `events`
   - **Query Scope**: Collection
   
4. Add fields in this exact order:
   
   | Field Path | Query Scope | Order |
   |------------|-------------|-------|
   | category | Collection | Ascending |
   | geohash | Collection | Ascending |
   | status | Collection | Ascending |
   | startTime | Collection | Ascending |

5. Click **"Create"**

6. Wait for status to change from "Building" to "Enabled" (5-15 minutes)

### Index 2: Category + Status + Time

1. Click **"Create Index"** again

2. Configure:
   - **Collection ID**: `events`
   - **Query Scope**: Collection

3. Add fields:
   
   | Field Path | Query Scope | Order |
   |------------|-------------|-------|
   | category | Collection | Ascending |
   | status | Collection | Ascending |
   | startTime | Collection | Ascending |

4. Click **"Create"**

5. Wait for build to complete

### Index 3: Status + Geohash + Time (May Already Exist)

This index may already exist from previous work. Check the existing indexes list first.

If it doesn't exist:

1. Click **"Create Index"**

2. Configure:
   - **Collection ID**: `events`
   - **Query Scope**: Collection

3. Add fields:
   
   | Field Path | Query Scope | Order |
   |------------|-------------|-------|
   | status | Collection | Ascending |
   | geohash | Collection | Ascending |
   | startTime | Collection | Ascending |

4. Click **"Create"**

---

## Verification Steps

### Step 1: Check Index Status

**Firebase Console:**
1. Go to [Firestore Indexes](https://console.firebase.google.com/project/vibe-a0d7b/firestore/indexes)
2. Verify all indexes show "Enabled" status
3. Check that index names match the configurations above

**Firebase CLI:**
```bash
firebase firestore:indexes
```

Look for output similar to:
```
┌─────────────┬──────────────┬───────────┬──────────────────┬───────────┐
│ Index       │ Collection   │ Fields    │ Order            │ Status    │
├─────────────┼──────────────┼───────────┼──────────────────┼───────────┤
│ [AUTO_ID]   │ events       │ category  │ ASCENDING        │ ENABLED   │
│             │              │ geohash   │ ASCENDING        │           │
│             │              │ status    │ ASCENDING        │           │
│             │              │ startTime │ ASCENDING        │           │
└─────────────┴──────────────┴───────────┴──────────────────┴───────────┘
```

### Step 2: Test Queries in Firebase Console

1. Go to [Firestore Data](https://console.firebase.google.com/project/vibe-a0d7b/firestore/data)

2. Open the `events` collection

3. Try a test query:
   - Click "Filter" button
   - Add filter: `category` `==` `sports`
   - Add filter: `status` `==` `active`
   - Click "Apply"

4. If indexes are working, you'll see results without errors

### Step 3: Test in App (Development)

Run this test query in your app (you can add it temporarily to MapScreen or a debug screen):

```dart
Future<void> testCategoryIndexes() async {
  try {
    // Test query 1: Category + Status + Time
    final sportsEvents = await FirebaseFirestore.instance
        .collection('events')
        .where('category', isEqualTo: 'sports')
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: false)
        .limit(10)
        .get();

    print('✅ Sports events query successful: ${sportsEvents.docs.length} results');

    // Test query 2: Category + Geohash (approximate)
    final foodEvents = await FirebaseFirestore.instance
        .collection('events')
        .where('category', isEqualTo: 'food')
        .where('geohash', isGreaterThanOrEqualTo: 'ucfv')
        .where('geohash', isLessThanOrEqualTo: 'ucfw')
        .where('status', isEqualTo: 'active')
        .orderBy('geohash')
        .orderBy('startTime')
        .limit(10)
        .get();

    print('✅ Food events with geohash query successful: ${foodEvents.docs.length} results');

  } catch (e) {
    print('❌ Index test failed: $e');
    if (e.toString().contains('index')) {
      print('⚠️ Indexes may still be building. Wait 5-10 minutes and try again.');
    }
  }
}
```

---

## Troubleshooting

### Issue: "The query requires an index" error

**Symptoms:**
```
[cloud_firestore/failed-precondition] The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```

**Solutions:**
1. Click the link in the error message (easiest way)
2. This will open Firebase Console with pre-filled index configuration
3. Click "Create Index"
4. Wait 5-15 minutes for build to complete

### Issue: Index stuck in "Building" state

**Symptoms:**
- Index shows "Building" status for more than 30 minutes
- No progress indicator

**Solutions:**
1. Check your internet connection
2. Try refreshing the Firebase Console page
3. If still stuck after 1 hour, delete and recreate the index
4. Contact Firebase support if issue persists

### Issue: Wrong index being used

**Symptoms:**
- Queries are slow (>1 second)
- Firebase Console shows different index being used

**Solutions:**
1. Verify index field order matches exactly
2. Check that all fields in the query are included in the index
3. Field order in index must match query order
4. Try adding explicit `.orderBy()` clauses to your query

### Issue: "Permission denied" when deploying

**Symptoms:**
```
Error: HTTP Error: 403, The caller does not have permission
```

**Solutions:**
1. Run `firebase login` again
2. Ensure your account has "Firebase Admin" or "Editor" role
3. Check project permissions in [IAM Console](https://console.cloud.google.com/iam-admin/iam)

---

## Cost Considerations

### Index Storage Costs
- Each composite index adds ~100 bytes per document
- For 1,000 events with 3 indexes: ~300 KB
- For 100,000 events: ~30 MB
- **Cost Impact**: Negligible (fractions of a cent per month)

### Query Costs
- Read operations: $0.06 per 100,000 documents read
- Indexes don't increase read costs
- Indexes actually **reduce** costs by making queries faster (fewer scans)

### Write Costs
- Each document write updates all indexes
- Write costs: $0.18 per 100,000 document writes
- Minimal impact (each event creation updates 3 indexes)

**Estimated Monthly Cost** (for 10,000 events, 1,000 new events/month):
- Index storage: $0.01
- Additional write operations: $0.05
- **Total: ~$0.06/month**

---

## Monitoring Index Performance

### Firebase Console - Usage Tab

1. Go to [Firestore Usage](https://console.firebase.google.com/project/vibe-a0d7b/firestore/usage)
2. Check "Queries" section
3. Look for slow queries (>500ms)
4. Verify indexes are being used

### App Performance Monitoring

Add timing logs to your queries:

```dart
Future<List<EventModel>> getEventsByCategory(EventCategory category) async {
  final startTime = DateTime.now();
  
  final querySnapshot = await FirebaseFirestore.instance
      .collection('events')
      .where('category', isEqualTo: category.toFirestore())
      .where('status', isEqualTo: 'active')
      .orderBy('startTime')
      .get();
  
  final duration = DateTime.now().difference(startTime);
  print('Query completed in ${duration.inMilliseconds}ms');
  
  return querySnapshot.docs
      .map((doc) => EventModel.fromJson(doc.data()))
      .toList();
}
```

**Target Performance:**
- Simple queries: <100ms
- Geohash queries: <200ms
- Complex filters: <500ms

---

## Index Maintenance

### When to Update Indexes

Update indexes when:
- Adding new filterable fields to events
- Changing query patterns
- Adding new complex queries
- Performance degrades

### How to Update

**Option 1: Add to firestore.indexes.json**
1. Edit the file
2. Add new index configuration
3. Run `firebase deploy --only firestore:indexes`

**Option 2: Firebase Console**
1. Create new index manually
2. Export indexes: `firebase firestore:indexes > firestore.indexes.json`
3. Commit updated file to version control

### Deleting Unused Indexes

Indexes consume storage and affect write performance. Delete unused ones:

**Firebase Console:**
1. Go to Indexes page
2. Find unused index
3. Click ⋮ menu → "Delete"

**Firebase CLI:**
```bash
firebase firestore:indexes:delete <INDEX_ID>
```

---

## Next Steps

After indexes are created and enabled:

1. ✅ Verify all indexes show "Enabled" status
2. ✅ Test queries in Firebase Console
3. ✅ Run test queries in app (use the test function above)
4. ✅ Monitor performance for 24-48 hours
5. ✅ Proceed with Phase 2 implementation (category filtering UI)

---

## Quick Reference

**Project ID:** `vibe-a0d7b`

**Firebase Console Links:**
- [Firestore Indexes](https://console.firebase.google.com/project/vibe-a0d7b/firestore/indexes)
- [Firestore Data](https://console.firebase.google.com/project/vibe-a0d7b/firestore/data)
- [Usage Dashboard](https://console.firebase.google.com/project/vibe-a0d7b/firestore/usage)

**CLI Commands:**
```bash
# Deploy indexes
firebase deploy --only firestore:indexes

# List indexes
firebase firestore:indexes

# Delete index
firebase firestore:indexes:delete <INDEX_ID>
```

**Index Configuration File:** `/Users/denol/specifyTry/vibe_app/firestore.indexes.json`

---

## Support

If you encounter issues:
1. Check [Firebase Status](https://status.firebase.google.com/)
2. Review [Firestore Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
3. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/google-cloud-firestore)
4. Contact Firebase Support (paid plans only)
