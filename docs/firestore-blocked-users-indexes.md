# Firestore Indexes for blockedUsers collection

## Required Composite Indexes

### Index 1: Query blocked users by blockerId
- **Collection**: `blockedUsers`
- **Fields**:
  - `blockerId` (Ascending)
  - `blockedAt` (Descending)

### Index 2: Query if user is blocked
- **Collection**: `blockedUsers`
- **Fields**:
  - `blockerId` (Ascending)
  - `blockedUserId` (Ascending)

### Index 3: Query if blocked by another user
- **Collection**: `blockedUsers`
- **Fields**:
  - `blockedUserId` (Ascending)
  - `blockerId` (Ascending)

## How to Create

### Option 1: Firebase Console
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: `blockedUsers`
4. Add the fields as specified above
5. Click "Create"

### Option 2: Run app and click generated link
When you first use a query that needs an index, Firestore will throw an error with a link to auto-create the index. Click that link.

### Option 3: Using Firebase CLI
```bash
# Deploy indexes from firestore.indexes.json
firebase deploy --only firestore:indexes
```

## Document Structure

```json
{
  "blockerId": "user_id_who_blocked",
  "blockedUserId": "user_id_who_is_blocked",
  "blockedAt": "Timestamp"
}
```

## Security Rules

Add these rules to `firestore.rules`:

```
match /blockedUsers/{blockId} {
  // Users can only read their own blocks
  allow read: if request.auth != null && 
                 (resource.data.blockerId == request.auth.uid ||
                  resource.data.blockedUserId == request.auth.uid);
  
  // Users can only create blocks where they are the blocker
  allow create: if request.auth != null && 
                   request.resource.data.blockerId == request.auth.uid &&
                   request.resource.data.blockedUserId != request.auth.uid;
  
  // Users can only delete their own blocks
  allow delete: if request.auth != null && 
                   resource.data.blockerId == request.auth.uid;
}
```
