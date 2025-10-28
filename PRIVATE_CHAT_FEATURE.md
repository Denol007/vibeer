# Private Chat Feature - Firestore Setup

## Required Firestore Indexes

The private chat feature requires the following Firestore indexes:

### 1. Conversations Collection Index

**Index for querying user's conversations sorted by update time:**

- Collection: `conversations`
- Fields:
  - `participantIds` (Array)
  - `updatedAt` (Descending)
- Query scope: Collection

This index is used by `getUserConversations()` to efficiently fetch and sort all conversations for a user.

### Setup Methods

#### Method 1: Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Configure:
   - **Collection ID**: `conversations`
   - **Fields to index**:
     - Field: `participantIds`, Order: `Array`
     - Field: `updatedAt`, Order: `Descending`
   - **Query scope**: Collection
6. Click **Create**

#### Method 2: Click Error Link (Easiest)

1. Run the app and try to open the Chats screen
2. The first time you query conversations, Firestore will show an error with a direct link to create the index
3. Click the link in the error message
4. Firebase Console will open with pre-filled index configuration
5. Click **Create**

#### Method 3: Firebase CLI

Create `firestore.indexes.json` in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participantIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

Then deploy:

```bash
firebase deploy --only firestore:indexes
```

## Firestore Data Structure

### Conversations Collection

```
conversations/{conversationId}
  - id: string (auto-generated: "userId1_userId2" sorted)
  - participantIds: [string] (always 2 users)
  - participantData: {
      userId: {
        name: string,
        photoUrl: string
      }
    }
  - lastMessage: string (nullable)
  - lastMessageSenderId: string (nullable)
  - lastMessageTime: timestamp (nullable)
  - unreadCounts: {
      userId: int
    }
  - createdAt: timestamp
  - updatedAt: timestamp

conversations/{conversationId}/messages/{messageId}
  - id: string (auto-generated)
  - senderId: string
  - senderName: string
  - senderPhotoUrl: string
  - text: string (1-500 characters)
  - timestamp: timestamp
  - isSystemMessage: boolean (always false for private chats)
  - readBy: [string] (user IDs who have read the message)
  - replyToMessageId: string (nullable)
  - replyToText: string (nullable)
  - replyToSenderName: string (nullable)
```

## Notes

- Index creation typically takes **2-5 minutes**
- You'll receive an email when the index is ready
- The app will work after the index is built
- Conversation IDs are deterministic (sorted user IDs joined with `_`)
- Messages are stored in subcollections for scalability
- Unread counts are tracked per user in the conversation document

## Security Rules

Make sure to add Firestore security rules for conversations:

```javascript
match /conversations/{conversationId} {
  // Only participants can read the conversation
  allow read: if request.auth != null && 
    request.auth.uid in resource.data.participantIds;
  
  // Only participants can write (create/update)
  allow write: if request.auth != null && 
    request.auth.uid in request.resource.data.participantIds;
  
  match /messages/{messageId} {
    // Only participants can read messages
    allow read: if request.auth != null && 
      request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
    
    // Only participants can create messages
    allow create: if request.auth != null && 
      request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds &&
      request.resource.data.senderId == request.auth.uid;
  }
}
```

## Testing

1. **Create a conversation:**
   - Go to a friend's profile
   - Click "Написать сообщение"
   - Conversation is created/opened

2. **Send messages:**
   - Type a message
   - Click send
   - Message appears in both users' chats

3. **View conversations list:**
   - Go to Chats tab (bottom navigation)
   - See all your conversations
   - Unread counts shown as badges
   - Last message preview visible

4. **Test features:**
   - Reply to messages
   - Real-time updates
   - Unread counts
   - Navigate to user profile from chat
