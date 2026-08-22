# FLAME — Mobile App

Flutter client for **FLAME**, a short-form educational video platform that
connects learners, creators and professional communities through videos,
events, workshops and community features.

This repository contains the mobile application. The backend is a separate
service developed by the team.

**My role:** Frontend Developer — I built the mobile application and connected
it to the team's REST API.

> Demo video and screenshots: https://jana-portfolio-mauve.vercel.app/#flame

---

## Features

- Authentication — sign up, log in and session handling with secure token storage
- Short-form video feed with in-app playback
- Events and workshops — browse, filter by category and book
- Communities — browse, join and view recommendations
- User profiles and account management

---

## Tech stack

| Area | Technology |
|---|---|
| Framework | Flutter (Dart, SDK ^3.9.2) |
| Networking | Dio |
| Auth storage | flutter_secure_storage |
| Video playback | media_kit |
| Media & assets | image_picker, google_fonts |
| Backend services | Firebase, team REST API |

---

## Project structure

```
lib/
├── Pages/        screen-level widgets
├── auth/         authentication flows and token handling
├── components/   reusable UI widgets
├── models/       data models
├── services/     API clients and business logic
├── theme/        colours, typography and app theming
└── main.dart     entry point
```

---

## Getting started

**Prerequisites:** Flutter SDK 3.9.2 or newer, and Android Studio or Xcode.

```bash
git clone https://github.com/janaammrr/front-end.git
cd front-end
flutter pub get
flutter run
```

The app expects a running backend. Set the API base URL in `lib/services/`
before launching.

---

## What I worked on

- Built the mobile UI from the team's Figma designs
- Implemented authentication screens and user flows
- Built the main short-form video feed
- Integrated the REST API using Dio, including error and loading states
- Built the events and workshops interfaces
- Built profile and account screens
- Collaborated with the team using Git and GitHub

---

## Author

**Jana Amr** — Software Engineer
[Portfolio](https://jana-portfolio-mauve.vercel.app) ·
[LinkedIn](https://www.linkedin.com/in/jana-amr-1380752a6/)
