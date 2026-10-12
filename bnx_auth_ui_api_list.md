# APIs Used in bnx-auth-ui

All endpoints are prefixed with `API_BASE` (e.g., `https://api.bnxmail.com/api/`).
All API responses follow this standard wrapper structure:

```json
{
  "success": true, 
  "message": "Success message or error message",
  "data": { ... }
}
```

---

## 1. Authentication & Login

### `POST /auth/login`

**Purpose**: Authenticate user credentials or initiate 2FA flow.

- **Body**: `{ "email": "user@bnxmail.com", "password": "mypassword" }`
  *(Note: Live backend OpenAPI schema requires both `email` and `password`. If identifier is supplied without domain, format it as `user@bnxmail.com`)*
- **Response (Direct Login)**:

  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "accessToken": "ey...",
      "refreshToken": "ey...",
      "email": "user@bnxmail.com",
      "username": "user"
    }
  }
  ```

- **Response (If 2FA Enabled)**:

  ```json
  {
    "success": true,
    "data": {
      "tempToken": "ey...",
      "is2FaEnabled": true,
      "email": "user@bnxmail.com"
    }
  }
  ```

### `POST /auth/login/2fa`

**Purpose**: Step 2 of 2FA login verification (verifying password or token when multi-step 2FA is challenged).

- **Body**: `{ "tempToken": "ey...", "password": "mypassword" }`
- **Response**: `{ "success": true, "data": { "accessToken": "ey..." } }`

### `POST /auth/login/2fa/send-otp`

**Purpose**: Send 2FA OTP to the user's phone/email.

- **Body**: `{ "tempToken": "ey..." }`
- **Response**: `{ "success": true, "message": "OTP Sent successfully" }`

### `POST /auth/login/2fa/verify-otp`

**Purpose**: Verify the 2FA OTP and get final access token.

- **Body**: `{ "tempToken": "ey...", "otp": "123456" }`
- **Response**: `{ "success": true, "data": { "accessToken": "ey..." } }`

---

## 2. Registration & Onboarding

### `POST /auth/register`

**Purpose**: Create a new user account.

- **Body (Personal/Child)**: `{ "username": "john123", "password": "...", "mode": "PERSONAL", "firstName": "John", "lastName": "Doe", "dob": "2000-01-01", "parentEmail": "parent@example.com" (if CHILD) }`
- **Body (Business)**: `{ "username": "acmecorp", "password": "...", "mode": "BUSINESS", "ownerFirstName": "...", "ownerLastName": "...", "businessName": "Acme Corp", "registrationNumber": "123", "domain": "bnxmail.com" }`
- **Response**: `{ "success": true, "data": { "tempToken": "ey..." } }`

### `POST /emails/create`

**Purpose**: Provisions the actual email mailbox after user registration.

- **Headers**: `Authorization: Bearer {tempToken}`
- **Body**: `{ "emailName": "john123", "password": "...", "isPrimary": true }`
- **Response**: `{ "success": true, "data": { "email": "john123@bnxmail.com" } }`

### `POST /business/onboard`

**Purpose**: Submit extra business details.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: `{ "businessAddress": "123 St", "businessPhone": "...", "industry": "Tech", "companySize": "1-10", "acceptTerms": true, "logo": "data:image/png;base64,..." }`
- **Response**: `{ "success": true, "message": "Business onboarded successfully" }`

---

## 3. Child Account Approvals

### `POST /auth/child/send-parent-otp`

**Purpose**: Send verification code to parent email.

- **Body**: `{ "parentEmail": "parent@example.com" }`
- **Response**: `{ "success": true, "message": "OTP sent to parent" }`

### `POST /auth/child/verify-parent-otp`

**Purpose**: Verify the code sent to parent.

- **Body**: `{ "parentEmail": "parent@example.com", "otp": "123456" }`
- **Response**: `{ "success": true, "message": "Parent verified successfully" }`

---

## 4. Password Recovery (Forgot Password)

### `GET /auth/forgot-password/options?identifier=user@bnxmail.com`

**Purpose**: Get available recovery methods (email/phone) for the user.

- **Response**: `{ "success": true, "data": { "options": ["email", "phone"] } }`

### `POST /auth/forgot-password/send-otp`

**Purpose**: Send reset OTP via chosen method.

- **Body**: `{ "identifier": "user@bnxmail.com", "method": "email" }`
- **Response**: `{ "success": true, "message": "OTP sent" }`

### `POST /auth/forgot-password/verify-otp`

**Purpose**: Verify the reset OTP.

- **Body**: `{ "identifier": "user@bnxmail.com", "otp": "123456" }`
- **Response**: `{ "success": true, "data": { "resetToken": "ey..." } }`

### `POST /auth/reset-password`

**Purpose**: Set the new password.

- **Body**: `{ "identifier": "user@bnxmail.com", "otp": "123456", "newPassword": "newSecurePassword123!" }`
- **Response**: `{ "success": true, "message": "Password changed successfully" }`

### `POST /auth/change-password`

**Purpose**: Change password while logged in.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: `{ "oldPassword": "...", "newPassword": "..." }`
- **Response**: `{ "success": true, "message": "Password updated" }`

---

## 5. Account & Profile Management

### `GET /users/me`

**Purpose**: Fetch current user details.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": { "id": 1, "username": "...", "email": "...", "firstName": "...", "lastName": "...", "accountType": "PERSONAL" } }`

### `GET /emails/list`

**Purpose**: Fetch all mailboxes linked to the user.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": [ { "emailId": "user@bnxmail.com", "isPrimary": true } ] }`

### `GET /users/recovery`

**Purpose**: Fetch configured recovery options.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": { "recoveryEmail": "...", "phoneNumber": "..." } }`

### `PATCH /users/recovery`

**Purpose**: Update recovery options.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: `{ "recoveryEmail": "new@gmail.com", "phoneNumber": "+1234567890" }`
- **Response**: `{ "success": true, "message": "Recovery options updated" }`

---

## 6. Security & Sessions

### `GET /auth/sessions` & `GET /auth/sessions/external`

**Purpose**: Fetch active login sessions.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": [ { "id": "uuid", "deviceInfo": "Mac OS X", "ipAddress": "192.168.1.1", "lastActive": "..." } ] }`

### `DELETE /auth/sessions/{sessionId}` & `DELETE /auth/sessions/external/{sessionId}`

**Purpose**: Terminate a specific session.

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "message": "Session terminated" }`

---

## 7. Two-Factor Authentication (2FA)

### `GET /users/2fa/accounts`

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": [...] }`

### `POST /users/2fa/setup`

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "data": { "secret": "...", "qrCode": "base64..." } }`

### `POST /users/2fa/verify`

- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: `{ "code": "123456" }`
- **Response**: `{ "success": true, "message": "2FA successfully enabled" }`

### `POST /users/2fa/disable`

- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**: `{ "success": true, "message": "2FA disabled" }`

---

## 8. Miscellaneous

### `GET /auth/username-suggestions`

- **Response**: `{ "success": true, "data": ["user1", "user_2"] }`

### `POST /verification/initiate/{emailId}`

- **Response**: `{ "success": true, "data": { "refId": "uuid" } }`

### `GET /verification/status/{refId}`

- **Response**: `{ "success": true, "data": { "status": "approved" } }`
