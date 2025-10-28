# Firestore Composite Indexes for Event Categories

## Overview
Event categories require composite indexes for efficient querying with geospatial and temporal filters.

## Required Indexes

### 1. Category + Geohash + Status + Time
**Collection:** `events`  
**Fields:**
- `category` Ascending
- `geohash` Ascending
- `status` Ascending
- `startTime` Ascending

**Purpose:** Filter events by category within a geographic area, showing only active events ordered by time.

**Example Query:**
```dart
_firestore
  .collection('events')
  .where('category', isEqualTo: 'sports')
  .where('geohash', isGreaterThanOrEqualTo: minHash)
  .where('geohash', isLessThanOrEqualTo: maxHash)
  .where('status', isEqualTo: 'active')
  .orderBy('startTime', descending: false)
```

### 2. Category + Status + Time (Fallback)
**Collection:** `events`  
**Fields:**
- `category` Ascending
- `status` Ascending
- `startTime` Ascending

**Purpose:** Filter events by category globally (no geohash), showing only active events ordered by time.

**Example Query:**
```dart
_firestore
  .collection('events')
  .where('category', isEqualTo: 'food')
  .where('status', isEqualTo: 'active')
  .orderBy('startTime', descending: false)
```

### 3. Status + Geohash + Time (Existing - No Changes Needed)
**Collection:** `events`  
**Fields:**
- `status` Ascending
- `geohash` Ascending
- `startTime` Ascending

**Purpose:** Show all events in geographic area (no category filter).

## Creating Indexes

### Option 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database → Indexes
4. Click "Create Index"
5. Add each field according to the specifications above

### Option 2: Firebase CLI (Recommended)
Create `firestore.indexes.json` in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Then deploy:
```bash
firebase deploy --only firestore:indexes
```

## Testing Indexes

After creating indexes:

1. **Wait for build completion** (5-15 minutes)
   - Check status in Firebase Console → Firestore → Indexes
   - Indexes must show "Enabled" status before use

2. **Test queries:**
   ```dart
   // Test category filter
   final sportsEvents = await FirebaseFirestore.instance
     .collection('events')
     .where('category', isEqualTo: 'sports')
     .where('status', isEqualTo: 'active')
     .orderBy('startTime')
     .limit(10)
     .get();
   
   print('Sports events: ${sportsEvents.docs.length}');
   ```

3. **Monitor errors:**
   - If you see "index required" errors, the index may still be building
   - Check Firebase Console for index status

## Migration Notes

### Existing Events Without Category
Events created before the category feature will not have a `category` field. The `EventModel.fromJson()` method handles this by defaulting to `EventCategory.other`:

```dart
final categoryString = data['category'] as String?;
category: EventCategory.fromString(categoryString ?? 'other'),
```

### Optional: Backfill Categories
If you want to update existing events with proper categories, you can run a migration script:

```dart
Future<void> backfillCategories() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all events without category
  final eventsSnapshot = await firestore
    .collection('events')
    .where('category', isNull: true)
    .get();
  
  print('Found ${eventsSnapshot.docs.length} events to update');
  
  // Update each event
  for (final doc in eventsSnapshot.docs) {
    await doc.reference.update({
      'category': 'other', // Default to 'other'
    });
  }
  
  print('Migration complete');
}
```

## Performance Considerations

1. **Index size:** Each composite index increases storage cost
   - Category index adds ~100 bytes per event
   - Minimal impact for <100k events

2. **Write performance:** Each index is updated on event creation
   - Adds ~10-20ms per write operation
   - Negligible for user experience

3. **Query performance:** Composite indexes enable fast filtered queries
   - Without index: O(n) scan of all events
   - With index: O(log n) + O(results) lookup time

## Troubleshooting

### "Index required" error
**Problem:** Query fails with error about missing index  
**Solution:** 
1. Check Firebase Console → Indexes for status
2. Wait for index to finish building (can take 15+ minutes)
3. If stuck, delete and recreate the index

### Queries still slow
**Problem:** Filtered queries take >500ms  
**Solution:**
1. Verify correct index is being used (check Firebase Console → Usage)
2. Reduce query scope (smaller geohash area, narrower time range)
3. Consider client-side filtering for non-critical filters

### Index build failed
**Problem:** Index shows "Error" status in console  
**Solution:**
1. Check index field names match exactly (case-sensitive)
2. Verify collection name is correct
3. Try deleting and recreating the index

## Related Documentation

- [Firebase Composite Indexes](https://firebase.google.com/docs/firestore/query-data/indexing)
- [GeoFlutterFire Plus Queries](https://pub.dev/packages/geoflutterfire_plus)
- [Event Categories Implementation](../lib/features/events/models/event_category.dart)
