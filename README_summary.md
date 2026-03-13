# 🛡️ Tryton ERP Docker Manager v1.0.0

TryDockCmd es una capa de operaciones para Tryton ERP en Docker, en el sistema operativo Windows.

## 🚀 1. Quick Start (Turnkey)

1. **Config Tryton:** Edit `.env` with your credentials and `LANGUAGE` (es-ES / en-US).
2. **Config Proteus:** Edit `config/trytond.conf` Company name & Currency
3. **Launch:** Run `tcd.bat` (automatic installation).

* *The manager will auto-pull images, create DBs (Real & Demo), inject dynamic data for v7.8.x+, and activate 41 core modules.*

---

## 🧠 2. The Proteus Engine (Zero-Touch Setup)

The system includes a Python Proteus Brain (auto_full_setup.py) that bypasses hours of manual configuration:

1. **Auto-Identity:** Hot-reads company info from trytond.conf.
2. **Fiscal Engineering:** Automatically generates Fiscal Years (2026-2030), Periods, and Sequences.
3. **Smart Localization:** Auto-activates es, fr, or de and links accounting charts.
4. **Wizard Mastery:** Completes all post-install assistants via API.
5. **Install Tryton countries** Imported from /trytond/modules/country/scripts/import_countries.py. Extract information from the Python library pycountry standards 3166-1
6. **Install Tryton subdivisions** Imported from /trytond/modules/country/scripts/import_countries.py. Extract information from the Python library pycountry standards 3166-2
7. **Install postal codes** Imported from /trytond/modules/country/scripts/import_postal_codes.py. Extract information from the GeoNames download path: http://download.geonames.org/export/zip/

## 📊 3. Main Menu & Operations

| Option | Script        |           Description                                       |
| :---:  | :-------------| :-----------------------------------------------------------|
| **0**  | `install.bat` | Automated deployment and DB initialization. |
| **1**  | `status.bat`  | Verify if Tryton and Postgres are running correctly.        |
| **2**  | `start.bat`   | Power on all ERP containers.                                |
| **3**  | `stop.bat`    | Gracefully shut down the containers.                        |
| **4**  | `logger.bat`  | Interactive log viewer with custom line count.              |
| **5**  | `errors.bat`  | Smart Audit: Scans logs for errors/fails in the last 24h.   |
| **6**  | `backup.bat`  | Hot-backup of your database (No downtime required).         |
| **7**  | `restore.bat` | Disaster recovery from your backup files.                   |
| **8**  | `install_tryton.bat`| (REAL) install modules in trytond in the tryton database |
| **9**  | `install_demo.bat`  | (DEMO) Install database-X.X.dump in (tryton_demo)     |
| **10** | `client.bat` | Verified connectivity & Browser launch.               |

---

## 🔍 4. Advanced Forensic Auditing

The system performs a **3-Layer Audit** in < 4 seconds:

1. **Infrastructure:** Validates PostgreSQL Roles (Superuser), UTF8 Encoding, and Extensions.
2. **Logic (XML):** Scans all module files classifying them as **STRUCTURE** or **DATA**.
3. **Consistency:** Verifies if 41 modules (Accounting, MRP, Sales, etc.) are correctly `activated`.

---

## 🌍 5. Smart Features

- **Dynamic I18n:** Adaptive table formatting for English and Spanish (Elastic Pipes).
- **Version-Aware:** Automatically fetches the correct `.dump` via `curl` based on the active Docker tag.
- **Semantic Colors:** Visual alerts (Green=Success, Red=Error, Yellow=Working).
- **Isolation:** Complete separation between `tryton` (Production) and `tryton_demo` (Lab).

---

## 🛠️ 6. Requirements

- **Docker Desktop** (WSL 2 recommended).
- **PowerShell 5.1+** (Internal bridge).
- **Permissions:** Write access for `/log` `/tmp` `/sql` and `/backup`.
- **Configuration:** Valid [company] section in conf/trytond.conf and file .env
---

## 📄 License

This project is licensed under the MIT License.

Tryton-Docker-Manager - Making Tryton ERP management easy and secure.

---

- **Author:** [Telepieza - Mariano Vallespín]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.0.0 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)