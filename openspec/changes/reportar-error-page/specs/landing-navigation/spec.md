## ADDED Requirements

### Requirement: Route registration for error report page
The GoRouter configuration SHALL include a route for `/reportar-error` that renders `ReportarErrorPage` without requiring authentication.

#### Scenario: Route accessible without auth guard
- **WHEN** GoRouter processes the path `/reportar-error`
- **THEN** it SHALL render `ReportarErrorPage` regardless of authentication state

### Requirement: Back navigation to landing
The `ReportarErrorPage` SHALL provide a navigation element (button or app bar action) that returns the user to the landing page (`/`).

#### Scenario: Back to landing from report page
- **WHEN** a user on `/reportar-error` taps the back/home navigation element
- **THEN** the app SHALL navigate to `/` (landing page)

#### Scenario: Back navigation after successful submission
- **WHEN** a user sees the success message after submitting a report
- **THEN** a "Volver al inicio" button SHALL be visible and navigate to `/`
