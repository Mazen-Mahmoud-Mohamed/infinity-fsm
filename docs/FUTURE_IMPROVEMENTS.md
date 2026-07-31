# Future Improvements

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  

Post-MVP enhancements organized by module and priority. Items already schema-ready are marked.

---

## Immediate Post-MVP (Weeks 21–28)

| Feature | Module | Priority | Effort |
|---------|--------|----------|--------|
| **Work Orders full UI** | Work Orders | Critical | 4 weeks |
| Work order → overtime linking UI | Overtime + Work Orders | Critical | 1 week |
| **Vehicles full UI** | Vehicles | High | 2 weeks |
| Vehicle filter on reports | Reports | High | 3 days |
| Push notifications (FCM/APNs) | Notifications | High | 1 week |
| PDF report export | Reports | High | 1 week |
| Excel (XLSX) export | Reports | High | 1 week |
| Biometric login | Auth | Medium | 3 days |
| Multi-language (Arabic + English) | Platform | High | 2 weeks |
| Dark mode | Platform | Medium | 1 week |

---

## Business Modules (Months 6–12)

| Module | Description | Priority | Dependencies |
|--------|-------------|----------|--------------|
| **Attendance** | Clock in/out, integrate with overtime calculation | High | Organization |
| **Customers** | Customer CRUD, link to work orders | High | Work Orders |
| **Assets** | Equipment tracking, assign to technicians | Medium | Organization |
| **Inventory** | Parts and materials tracking | Medium | Work Orders |
| **Scheduling** | Shift and job scheduling | Medium | Work Orders, Attendance |
| **Maintenance** | Preventive maintenance schedules | Low | Assets |
| **Payroll Integration** | Export approved hours to payroll systems | High | Overtime, Reports |
| **Analytics** | Advanced BI dashboards, trend analysis | Medium | All modules |

---

## Platform Enhancements

### Search & Discovery

| Feature | Priority | Phase |
|---------|----------|-------|
| Elasticsearch / Atlas Search migration | Medium | When > 100K records |
| Saved searches | Low | Analytics phase |
| Search suggestions / autocomplete | Medium | Post-MVP |

### Notifications

| Feature | Priority | Phase |
|---------|----------|-------|
| Email notifications (SendGrid/SES) | High | Phase 6 |
| SMS notifications (Twilio) | Medium | Phase 6 |
| Notification preferences per user | Medium | Phase 6 |
| Digest emails (daily summary) | Low | Analytics phase |

### Security & Compliance

| Feature | Priority |
|---------|----------|
| Two-factor authentication (TOTP) | High |
| SSO / SAML integration | Medium |
| IP whitelisting for admin | Low |
| GDPR data export/deletion tools | Medium |
| Audit log hash chain (tamper-evident) | Medium |
| Penetration testing (annual) | High |

### Infrastructure

| Feature | Priority |
|---------|----------|
| Kubernetes deployment | Medium |
| Multi-region deployment | Low |
| Feature flags (LaunchDarkly) | Medium |
| Async report generation (job queue) | Medium |
| Redis caching layer | High |
| CDN for static assets | Low |
| Web admin dashboard (React/Next.js) | High |

---

## Overtime Module Enhancements

| Feature | Description | Priority |
|---------|-------------|----------|
| Overtime edit/override | Admin corrects times with audit trail | Medium |
| Bulk approve/reject | Supervisor batch actions | Medium |
| Overtime budget caps | Alert when limits exceeded | Medium |
| Custom policies per department | Override working hours | Medium |
| Holiday auto-exclusion | From settings holiday calendar | High (MVP settings exist) |
| Travel reimbursement workflow | Full approval + payment tracking | Medium |
| AI photo verification | Detect valid work site photos | Low |
| Geofencing auto-start/end | Location-based triggers | Low |
| Live GPS tracking during RUNNING | Real-time map for supervisors | Low |

---

## Items Removed from Future (Now in Architecture)

The following were previously "future" but are now part of the v2.0 architecture:

- ✅ Full RBAC (was simple roles)
- ✅ Organization hierarchy (was departments only)
- ✅ Extended GPS metadata
- ✅ Device metadata capture
- ✅ Travel overtime extensions
- ✅ Overtime state machine (6 states)
- ✅ Dashboard KPIs
- ✅ Global search
- ✅ Expanded reporting dimensions
- ✅ Cloudinary folder convention
- ✅ Company configuration module
- ✅ Testing architecture from day one
- ✅ Work Orders schema
- ✅ Vehicles schema
- ✅ Notification template framework

---

## Long-Term Vision (Year 2+)

| Vision | Description |
|--------|-------------|
| **Multi-company SaaS** | Self-service registration, billing, tenant admin |
| **Marketplace** | Third-party module plugins via module interface |
| **AI Assistant** | Natural language queries over field data |
| **IoT Integration** | Sensor data from field equipment |
| **Route Optimization** | Optimal technician routing |
| **Customer Portal** | Customers view work order status |
| **White-label** | Custom branding per company |
| **API Marketplace** | Public API for third-party integrations |
