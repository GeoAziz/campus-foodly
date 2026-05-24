# Security Policy

## Table of Contents
- [Security Overview](#security-overview)
- [Authentication & Authorization](#authentication--authorization)
- [Data Protection](#data-protection)
- [API Security](#api-security)
- [Secrets Management](#secrets-management)
- [Incident Response](#incident-response)
- [Compliance](#compliance)
- [Security Checklist](#security-checklist)

## Security Overview

Campus Foodly implements defense-in-depth security with multiple layers:

```
User Input Validation (Client)
        ↓
Authentication (Firebase Auth)
        ↓
Rate Limiting & App Check (Firebase)
        ↓
Firestore Security Rules (Server)
        ↓
Data Encryption (Transit & Rest)
        ↓
Audit Logging & Crash Reporting
```

## Authentication & Authorization

### User Authentication

**Method**: Firebase Authentication
- Email/password with secure hashing
- Phone authentication support
- Third-party OAuth (Google, Apple)
- Multi-factor authentication (MFA) available

**Security**: 
- Passwords hashed with bcrypt
- Automatic token refresh every 60 minutes
- Sessions invalidated on logout
- Suspicious activity detection

### Role-Based Access Control (RBAC)

Three roles defined:
1. **User**: Regular customer
2. **Restaurant Owner**: Restaurant management
3. **Delivery**: Order fulfillment
4. **Admin**: System administration

**Implementation**:
```dart
// Firestore Rules
function isAdmin() {
  return request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid))
      .data.role == 'admin';
}
```

### Token Security
- Tokens stored in secure device storage
- Short expiration (60 minutes)
- Refresh token rotation on use
- No tokens in URLs or logs

## Data Protection

### In-Transit Encryption
- **TLS 1.2+** for all network communication
- Certificate pinning on critical endpoints
- HSTS headers enforced
- No HTTP fallback allowed

### At-Rest Encryption
- Firebase: All data encrypted with AES-256
- Hive (local): Encryption enabled for sensitive data
- Database field-level encryption for payments

### Data Retention
- Soft-delete pattern used (status = 'deleted')
- 90-day retention for audit logs
- 1-year retention for transaction records
- Automatic cleanup of old tokens (24-hour window)

### PII Protection
Sensitive fields encrypted:
- `users.email`
- `users.phoneNumber`
- `payments.cardToken`
- `deliveryAddresses.address`

## API Security

### Firebase App Check
Protects backend resources from abuse.

**Android**: SafetyNet/Play Integrity
**iOS**: App Attest
**Web**: reCAPTCHA v3

**Status**: Required in production

```dart
// Initialize in main.dart
await AppCheckService().initialize();

// All Firestore calls include App Check token
```

### Rate Limiting

**Server-side (Firestore Rules)**:
- Max 10 orders per user per 24 hours
- Max 5 payment attempts per user per 24 hours
- Max 100 items per order
- Max order value: $10,000

**Error Response**:
```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 3600
}
```

### Request Validation

```dart
// Firestore Rule Example
function isValidOrderCreate() {
  return request.resource.data.keys().hasAll([
    'userId', 'restaurantId', 'items', 'totalPrice', 'idempotencyKey'
  ]) &&
  request.resource.data.items.size() > 0 &&
  request.resource.data.items.size() <= 100 &&
  request.resource.data.totalPrice > 0 &&
  request.resource.data.totalPrice <= 10000;
}
```

### Duplicate Operation Prevention

**Idempotency Keys**:
- Required for: Orders, Payments, Refunds
- UUID v4 format
- 24-hour window to prevent duplicates
- Prevents accidental double-submissions

## Secrets Management

### Critical Credentials (NEVER COMMIT)

Protected in `.gitignore`:
```
.env
.env.*
serviceAccountKey.json
GoogleService-Info.plist
google-services.json
```

### Local Development

```bash
# Create .env.development from template
cp .env.example .env.development

# Add your credentials
CLOUDINARY_API_KEY=your_key_here
CLOUDINARY_API_SECRET=your_secret_here
```

### Rotation Schedule

- **API Keys**: Every 90 days
- **Service Accounts**: Every 180 days
- **Database Passwords**: Every 30 days
- **Payment Tokens**: On every transaction

### Secret Storage

| Secret | Storage | Access |
|--------|---------|--------|
| API Keys | Firebase Console | Build-time injection |
| Database Credentials | `.env.development` | Local only, not committed |
| Service Account | Firebase Console | Admin only |
| Payment Gateway | Stripe Console | Backend webhook handler |

## Incident Response

### Security Incident Procedure

1. **Detection**:
   - Firebase Crashlytics alert
   - Manual security scanning
   - Third-party vulnerability report

2. **Assessment** (within 1 hour):
   - Determine severity (Critical/High/Medium/Low)
   - Identify affected users/data
   - Estimate impact

3. **Containment** (within 4 hours):
   - Disable compromised features
   - Revoke exposed tokens
   - Notify affected users

4. **Eradication** (within 24 hours):
   - Deploy security patch
   - Rotate all credentials
   - Update security rules

5. **Recovery**:
   - Restore service
   - Monitor for re-exploitation
   - Post-incident analysis

### Security Issue Reporting

**Do not open public issues for security vulnerabilities!**

Instead:
1. Email: security@campusfoodly.dev
2. Include: Vulnerability description, steps to reproduce, impact
3. Expect: Response within 24 hours

## Compliance

### GDPR Compliance
- **User Data**: Encrypted and isolated per user
- **Right to Access**: API available for user data export
- **Right to Delete**: Soft-delete with 30-day purge
- **Consent**: Obtained and logged at signup

### Payment Security (PCI DSS)
- No direct card processing (uses Stripe)
- No card data stored locally
- Payment tokens secured with PCI DSS Level 1
- Audit trail for all transactions

### Privacy Policy
See `PRIVACY.md` for detailed privacy practices.

## Security Checklist

### Before Release
- [ ] All secrets removed from code
- [ ] Firestore rules tested and validated
- [ ] Rate limiting configured
- [ ] App Check enabled and tested
- [ ] SSL/TLS configured
- [ ] API keys rotated
- [ ] Security headers set
- [ ] Dependency vulnerabilities scanned
- [ ] OWASP Top 10 review completed
- [ ] Penetration testing done

### Pre-Production
- [ ] Firebase Crashlytics verified
- [ ] Monitoring alerts configured
- [ ] Incident response plan documented
- [ ] Backup strategy tested
- [ ] Disaster recovery plan created
- [ ] Logging retention policy set
- [ ] Data retention policy automated
- [ ] Audit logs enabled

### Ongoing
- [ ] Weekly dependency updates checked
- [ ] Monthly security review of rules
- [ ] Quarterly penetration testing
- [ ] Annual security audit
- [ ] All developer access logged
- [ ] Unusual activity monitored

## Security Best Practices for Developers

### Do ✓
- Use encrypted storage for sensitive data
- Validate all user input
- Log security events
- Rotate credentials regularly
- Use strong error messages (don't leak info)
- Test offline scenarios
- Sanitize all data before display

### Don't ✗
- Commit secrets or keys
- Log sensitive user data
- Use hardcoded credentials
- Trust client-side validation alone
- Expose error stack traces
- Store unencrypted passwords
- Use weak random number generation

## Vulnerability Disclosure

### Supported Versions
- Current version: Full support
- Previous 2 versions: Security patches only
- Older versions: No support

### Disclosure Timeline
1. Vendor notified (day 0)
2. 30-day grace period for patch
3. Public disclosure (day 30 or when patched)
4. Security advisory published

---

**Last Updated**: 2024
**Version**: 1.0
**Status**: Active

For security questions: security@campusfoodly.dev
