## ADDED Requirements

### Requirement: Path-based URL routing
The Flutter Web app SHALL use path-based URLs (no `#` fragment) so that links shared externally (e.g., in WhatsApp messages) resolve correctly.

#### Scenario: Root URL resolves correctly
- **WHEN** a user navigates to `colibrimd.com.ar/`
- **THEN** the landing page SHALL render without any `#` in the URL

#### Scenario: Deep link resolves correctly
- **WHEN** a user navigates directly to `colibrimd.com.ar/reportar-error`
- **THEN** the Flutter app SHALL initialize and route to the `ReportarErrorPage` without a 404

#### Scenario: Unknown path falls back to app
- **WHEN** a user navigates to any unregistered path
- **THEN** Firebase Hosting SHALL serve `index.html` (SPA fallback), and GoRouter SHALL handle the 404 within the app

### Requirement: Firebase Hosting SPA rewrite
Firebase Hosting SHALL be configured with a catch-all rewrite rule so that all paths are served by the Flutter Web `index.html`.

#### Scenario: Rewrite rule present
- **WHEN** `firebase.json` is deployed
- **THEN** it SHALL contain a rewrite entry `{ "source": "/**", "destination": "/index.html" }` under the hosting configuration
