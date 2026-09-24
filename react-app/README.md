# SJC Canteen React App

## Firebase setup

The app expects the `VITE_FIREBASE_*` values in `.env`. Food inventory is intentionally text-only, so the app uses Auth and Firestore without Firebase Storage.

After selecting the Firebase project, deploy the rules from this directory:

```bash
npx firebase login
npx firebase use <your-firebase-project-id>
npx firebase deploy --only firestore:rules
```

## Admin access

1. In Firebase Console, open **Authentication > Users** and create the administrator email/password account.
2. Copy that account's UID.
3. In **Firestore Database > users**, create a document whose document ID is that UID with fields such as:

```text
uid: <admin-uid>
email: <admin-email>
name: System Administrator
role: admin
```

4. Open `/admin-login` in the app and sign in with that account.

The admin portal can list and remove user accounts. Account deletion uses a trusted Firebase Admin SDK Cloud Function when deployed. Owner applications require admin approval before access.

## Local AI assistant

The assistant uses a local Ollama model through the Vite development proxy. Install Ollama, run `ollama pull gemma3:1b`, and keep Ollama running while using the app locally.
