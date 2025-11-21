# How to Seed Chats and Messages

There are two ways to seed chats and messages:

## Method 1: Using Command-Line Argument (Recommended)

When starting the API, add the `--seed-chats` flag:

```bash
cd API
dotnet run --seed-chats
```

This will automatically seed chats and messages when the API starts (only if the database already has accounts and properties).

## Method 2: Using the API Endpoint

1. Start the API server:
```bash
cd API
dotnet run
```

2. Login as an admin user to get an authentication token

3. Call the seeding endpoint:
```bash
curl -X POST http://localhost:5284/api/admin/seed-chats \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

Or use the provided script:
```bash
./API/SCRIPTS/seed-chats.sh http://localhost:5284 YOUR_AUTH_TOKEN
```

## What Gets Seeded

- 30-50 chats between users and developers
- 5-15 messages per chat
- 40% of chats assigned to sales members (developers)
- Varied message templates with realistic conversations
- Messages spread over time from chat creation to now

## Notes

- The seeding will clear existing chats and messages first
- Requires existing accounts (users and developers) and properties in the database
- Sales members are selected from developer accounts
- Messages alternate between users and developers

