# HajiCare admin seed

Utility idempotent untuk membuat atau memperbarui administrator pengembangan.
Hak admin diberikan melalui Firebase custom claim, bukan berdasarkan field yang
dapat ditulis client.

## Credentials

Gunakan salah satu:

1. Application Default Credentials: `gcloud auth application-default login`.
2. Service account lokal pada `tools/seed/service-account.json` (file ini
   diabaikan Git dan tidak boleh di-commit).

## Menjalankan di PowerShell

```powershell
cd tools/seed
npm install
$env:HAJICARE_ADMIN_PASSWORD = 'password-kuat-minimal-12-karakter'
node seed_admin.js
```

Environment variable opsional:

- `HAJICARE_ADMIN_EMAIL`
- `HAJICARE_ADMIN_NAME`
- `FIREBASE_PROJECT_ID`
