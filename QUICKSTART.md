# Quick Start - TryDockCmd

## 1. Configure

Edit `.env`:

```bash
DB_PASSWORD=your_db_password
PASSWORD=your_tryton_admin_password
EMAIL=admin@example.com
LANGUAGE=es-ES
TRYTON_LANGUAGE=es
```

Edit `config/trytond.conf`:

```ini
[database]
uri = postgresql://postgres:your_db_password@tryton-postgres-1:5432/

[company]
name = My Company
currency = EUR
```

## 2. Launch

Run:

```cmd
tcd.bat
```

## 3. Install

- On the first execution, option `0` is automatically run.
- The system prepares docker services and runs setup automation.

## 4. Access

- Use option `10` (client launch/check).
- Open `http://localhost:8000`.
- Login with `admin` and the password from `.env`.

## 5. Daily Operations

- OpTion `0`: Tryton ERP installation.
- Option `1`: status checks.
- Option `2`: start services.
- Option `3`: stop services.
- Option `5`: error audit.
- Option `6`: backup.
- Option `7`: restore.

## 6. Notes

- Production and demo environments are managed separately (`tryton`, `tryton_demo`).
- Setup engine actions are available internally as `FULL`, `GEO`, `LANG`, `ACC`.

---

- **Author:** [Telepieza - Mariano Vallespín]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.0.0 Stable

---

##### Optimized & Documented with the help of Gemini (Google AI)
