# Changelog

All notable changes to this project will be documented in this file.

## [DATE] — Weekly menu auth token fix

**Bug:** Frontend wasn't sending auth token to backend

**Root cause:** API service didn't include Authorization header

**Fix:** Added _getHeaders() helper to include Bearer token in all API requests

**Files changed:**
- lib/services/api_service.dart