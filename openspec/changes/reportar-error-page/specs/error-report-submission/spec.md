## ADDED Requirements

### Requirement: Public error report form
The system SHALL provide a publicly accessible form at `/reportar-error` that allows any user (unauthenticated) to submit a report indicating they received a WhatsApp message from Colibrí that was not intended for them.

#### Scenario: Form renders without authentication
- **WHEN** a user navigates to `/reportar-error` without being logged in
- **THEN** the form SHALL render with fields for phone number, professional name, and free-text description

#### Scenario: Successful submission
- **WHEN** a user fills in at least the phone number field and taps "Enviar reporte"
- **THEN** the system SHALL save a document to Firestore `error_reports` collection and display an inline success message

#### Scenario: Submission without phone number
- **WHEN** a user taps "Enviar reporte" without entering a phone number
- **THEN** the system SHALL display a validation error and NOT submit the form

#### Scenario: Loading state during submission
- **WHEN** the form is being submitted
- **THEN** the submit button SHALL be disabled and show a loading indicator

#### Scenario: Error during submission
- **WHEN** the Firestore write fails
- **THEN** the system SHALL display an error message with a retry option

### Requirement: Admin email notification
The system SHALL send an email to `aguschazaaa@gmail.com` for every submitted error report, containing all form fields.

#### Scenario: Email sent on new report
- **WHEN** a new document is created in Firestore `error_reports`
- **THEN** a Cloud Function SHALL write a document to the `/mail` collection triggering the "Trigger Email" extension to send to `aguschazaaa@gmail.com`

#### Scenario: Email contains report data
- **WHEN** the email is sent
- **THEN** it SHALL include: phone number, professional name, description, submission timestamp, and document ID

### Requirement: Error report Firestore persistence
The system SHALL persist all error reports in Firestore for auditing purposes.

#### Scenario: Document structure
- **WHEN** a report is submitted
- **THEN** the document SHALL contain: `phone` (string), `professionalName` (string, optional), `description` (string, optional), `createdAt` (Timestamp), `status` (string, default `"new"`)

#### Scenario: Public write, restricted read
- **WHEN** an unauthenticated user submits the form
- **THEN** Firestore security rules SHALL allow the write to `error_reports`

#### Scenario: Read restricted to admin
- **WHEN** a non-admin user attempts to read `error_reports`
- **THEN** Firestore security rules SHALL deny the read
