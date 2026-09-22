# React + Vite

## Firebase setup

The app expects the `VITE_FIREBASE_*` values in `.env`. Food inventory is intentionally text-only, so the app uses Auth and Firestore without Firebase Storage.

After selecting the Firebase project, deploy the rules from this directory:

```bash
npx firebase login
npx firebase use <your-firebase-project-id>
npx firebase deploy --only firestore:rules
```

Without this deployment, the student store feed or owner inventory can show `Missing or insufficient permissions`.

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

The admin portal can list and remove Firestore user profiles and purge order records. Removing the profile does not delete the Firebase Authentication account itself; full Auth deletion requires a trusted Firebase Admin SDK Cloud Function. This is intentional because exposing Auth deletion credentials in the React client would be unsafe.

This template provides a minimal setup to get React working in Vite with HMR and some Oxlint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the Oxlint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and Oxlint's TypeScript related rules in your project.
