# Taskfy - Technical Documentation

## Overview

Taskfy is a robust task management application designed to provide users with efficient, reliable, and available access to their tasks.

This document serves as the technical documentation covering the system's architecture, structure, and operational guarantees, meeting the project's non-functional requirements.

---

## Architecture & Technologies

Taskfy uses a modern tech stack to ensure high performance, reactivity, and scalability:

- **Frontend:** Flutter (Dart). Ensures consistent behavior across different platforms with a single codebase.
- **State Management:** Riverpod. It provides safe and predictable state management, allowing real-time reactive UI updates without boilerplate.
- **Backend as a Service (BaaS):** Supabase. Used for Authentication and Real-time Database (PostgreSQL).

## Project Structure

The project follows a modular, feature-based architecture within the `lib/` directory:

- `models/`: Contains standard Data Models (e.g., Task, User).
- `screens/`: Contains the UI layers and routing endpoints (e.g., `TaskListScreen`, `LoginScreen`).
- `services/`: Encapsulates external APIs, database operations, and configurations (e.g., `supabase_config.dart`).
- `providers/`: Riverpod state classes and business logic separated from the UI.
- `widgets/`: Reusable UI components.

---

## Non-Functional Requirements (NFR) Implementations

### [NF016] Compatibility
The application is configured to function correctly on devices that use recent versions of the Android operating system.
- Android's `minSdk` is set to `24` in `android/app/build.gradle.kts`. This ensures compatibility with Android 7.0 and above, which handles recent device hardware and software features efficiently securely.

### [NF005] Availability
The application guarantees high availability directly through its architecture:
- **Cloud Backend (Supabase):** The backend infrastructure is hosted on Supabase, which provides high availability (99.9% uptime SLA) and continuous operation for database queries and user authentication.
- **State Persistence:** Local caching strategies ensure the user can at least view their assigned/pending tasks seamlessly without excessive load times, keeping data always at their fingertips.

### [NF007] Maintenance Time
When there is system maintenance or update, the downtime must be reduced to the minimum possible:
- **Zero-Downtime Architecture:** Using Supabase, database schema migrations and backend updates are applied on-the-fly without requiring the entire system to be brought down.
- **Client-Side Updates:** Because the app is decoupled from the backend REST/Realtime APIs, server expansions or maintenance operations do not disconnect active UI components, ensuring seamless continuity.
- Thus, maintenance interruptions are nearly imperceptible to the end-users.

### [NF006] Documentation
This `README.md` and inline code documentation fulfill the requirement of maintaining a technical document that describes the architecture, functioning, and structure of the system, facilitating future maintenance, onboarding of new developers, and overall understanding of the project.
