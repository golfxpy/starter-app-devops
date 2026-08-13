# Runtime secrets

Do not commit secret values to this directory.

Generate local secret files with one of these commands:

```powershell
.\ops\init-secrets.ps1
```

```sh
sh ops/init-secrets.sh
```

The generated files are ignored by Git:

- `postgres_password.txt`
- `backup_encryption_passphrase.txt`

Production deployments should populate the same files from the platform's
secret manager immediately before `docker compose up`.
