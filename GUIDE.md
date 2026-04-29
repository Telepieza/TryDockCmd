# TryDockCmd Guide

Operational guide for deploying and managing Tryton ERP on Docker (Windows).

## 1. Prerequisites

- Docker Desktop installed and running.
- PowerShell 5.1+ available.
- Write permissions in project folders:
  `log`, `tmp`, `backup`, `sql`.

## 2. Required Configuration

### 2.1 `.env`

Minimum values:

```bash
DB_PASSWORD=your_db_password
PASSWORD=your_tryton_admin_password
VERSION=7.8        # Indicate Tryton version. View Tryton versions url: https://downloads.tryton.org/
EMAIL=admin@example.com
LANGUAGE=es-ES
TRYTON_LANGUAGE=es
```

### 2.2 `config/trytond.conf`

```ini
[database]
uri = postgresql://postgres:your_db_password@tryton-postgres-1:5432/

[company]
name = My Company
currency = EUR
journal_name = Diario General
journal_code = GEN            
vat_rates = 21,10,4 
```

## 3. Startup Flow

1. Run `tcd.bat`.
2. Pre-flight checks validate files, environment, compose metadata, and docker state.
3. If no stack is detected, use option `0` to install.

## 4. Main Menu

| Option | Script | Description |
|---|---|---|
| 0 | `install.bat` | Full install/bootstrap |
| 1 | `status.bat` | Status and checks |
| 2 | `startup.bat` | Start services |
| 3 | `startdown.bat` | Stop services |
| 4 | `logger.bat` | View logs |
| 5 | `errors.bat` | Error-focused audit |
| 6 | `backup.bat` | Backup |
| 7 | `restore.bat` | Restore |
| 8 | `install_tryton.bat` | Production DB module flow |
| 9 | `install_demo.bat` | Demo DB/module flow |
| 10 | `client.bat` | Connectivity checks + browser launch |

## 5. Python/Proteus Setup Engine

`python/auto_full_setup.py` is executed inside the Tryton container and supports:

- `FULL`: Runs the complete sequence (module sync, geodata import, language activation, company/account setup, fiscal years and sequences).
- `GEO`: Imports/updates countries and postal codes for the selected ISO code (`es`, `fr`, `de`), without running accounting setup.
- `LANG`: Activates translatable languages and executes translation/module upgrade flow, without creating fiscal/accounting structures.
- `ACC`: Executes company/accounting setup (company context, chart linkage, fiscal years, periods, invoice/account sequences), without geodata import.
- `TAX`: Executes company/taxes setup

Main tasks:

- Module sync and wizard cleanup.
- Company and currency setup.
- Language activation.
- Account mapping by localization.
- Fiscal years, periods, and sequences.
- cCuntries, subdivisions and postal codes.

## 6. Troubleshooting

### Docker not available

- Ensure Docker Desktop is fully started.
- Re-run option `2` or restart through menu.

### Port conflict (8000 / 5432)

- Check with:
  `netstat -ano | findstr :8000`
  `netstat -ano | findstr :5432`

### Language/setup mismatch

- Confirm `LANGUAGE` and `TRYTON_LANGUAGE` in `.env`.
- Ensure `lang/es-ES.txt` and `lang/en-US.txt` exist.

### Restore/auth issues

- Verify current `.env` password matches the one used when the volume was initialized.
- If not, reset/update DB credentials according to your docker data policy.

## 7. Operational Recommendations

- Run backups before large module updates.
- Keep docs and script behavior aligned in the same PR.
- Prefer small, testable changes in Batch and Python logic.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.25 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)
