# my_first_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase setup

The Android app uses Firebase Authentication and Cloud Firestore.

1. In Firebase Console, enable **Phone** and **Google** sign-in providers.
   Add the Android app's debug and release SHA fingerprints to the Firebase
   project. The Android package name is `com.mxpertzab.app`.
2. Create the Cloud Firestore database and publish the rules in
   [`firestore.rules`](./firestore.rules).
3. Create a Firestore document at `dashboard/home` using the fields and values
   in [`firestore/dashboard_home_seed.json`](./firestore/dashboard_home_seed.json).
   The dashboard reads this document live; dashboard content is not bundled as
   local fallback data.
4. Sign-up first verifies the `+244` phone number, links it with the supplied
   email/password Firebase Auth account, and then writes the profile to
   `users/{uid}`. Passwords are never written to Firestore.

The checked-in Firebase options currently configure Android only. Add the
platform-specific Firebase configuration before running on iOS or web.
