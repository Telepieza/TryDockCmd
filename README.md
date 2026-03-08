# 🛡️ Tryton ERP Docker Manager 🚀

An intuitive, menu-driven automation framework to deploy, manage, and protect your **Tryton ERP** environment on Windows with Docker.
This suite transforms complex Docker orchestration into a reliable, audited, and resilient infrastructure.
This project simplifies ERP maintenance, making it easy, secure, and users, professional for administrators and developers.

The true "magic" lies in the integration of Proteus (Python API), which acts as the system's brain. Once the infrastructure is live, the TryDockCmd takes control to:

- **Automated Post-Installation:** It completes all configuration Wizards (Company, Currency, Users) without human intervention.
- **Instant Fiscal Engineering:** Automatically creates fiscal years (2026-2028), invoicing sequences, and monthly accounting periods.
- **Dynamic Localization:** Activates and synchronizes languages ​​(es, fr, de), countries, subdivisions, postal codes, and links specific accounting charts according to the selected legislation.
- **Dual-Environment Ready:** Delivers a clean production database tryton and a tryton_demo instance with real data in record time.

---

## 📋 1. Prerequisites: Installing Docker

Before launching the manager, ensure your environment meets these standards:

   1. **Download Docker Desktop:** [Official Download for Windows](https://www.docker.com/products/docker-desktop/)
   2. **Installation:** Follow the installer prompts. We recommend using the **WSL 2 backend** for superior performance.
   3. **Scripting:** PowerShell 5.1+: Required for advanced YAML parsing and smart port detection via the read-compose.ps1 bridge.
   4. **Verification:** Open your terminal and type `docker --version`. If it returns a version number, you are ready!.
   
   Note: Terminal Permissions: The manager requires write access to the project directory to generate /log /tmp /sql and /backup folders.

---
## 🎨 2. Visual Interface & Semantic Colors

   The manager uses ANSI escape sequences to provide a color-coded experience in the Windows console. This helps identify the state of the system at a glance.

| Color | Variable | Category | Usage |
| :---: | :--- | :--- | :--- |
| ⚪ | `Grey` | **DEBUG** | Internal tracing and technical details. |
| 🔴 | `Red` | **ERROR** | Critical script failures (Batch level). |
| 🔴 | `Red` | **ALERT** | Critical ERP/Database exceptions (Docker/Python level). |
| 🟢 | `Green` | **SUCCESS** | Successfully completed operations. |
| 🟡 | `Yellow` | **WARN** | Active processes or waiting for engine. |
| 🟡 | `Yellow` | **INSTALL** | Operations completed at the installation. |
| ⚪ | `White` | **CHECK** | Check Docker, images, and containers. |
| 🔵 | `Cyan` | **INFO** | General status and project information. |
| 🟣 | `Magenta` | **CANCEL** | Operations aborted by the user. |


---
## 🌍 3. Multi-language Support (i18n)

This project (TryDockCmd) features a robust Internationalization Engine that allows switching between English and Spanish seamlessly.

- Sanitization: The engine automatically cleans white spaces and handles special characters in translation files to prevent script execution errors.
- Dynamic Substitution: Translation keys (e.g., PROYECTO, DESTINO, CONEXION, COUNT, FILE, VERSION, NAME, LINES) are replaced in real-time with actual system values.
- External Files: Language data is stored in en-US.txt and es-ES.txt for easy editing.

---
## ⚙️ 4. Configuration (`.env`)

  Before launching the menu, you must configure your credentials. Locate the `.env` file in the project root.
The existing values are for testing purposes; replace them with your own secure data.

**Key values to update in your `.env`:**
```bash
# Database Credentials
DB_PASSWORD=YourPassword       # <-- Change to a secure DB password
DB_USER=admin                  # <-- Change to a tryton User
# Tryton Initial Admin Configuration
PASSWORD=YourPassword          # <-- This will be your 'admin' login password
EMAIL=yourUser@yourDomain.com  # <-- Your admin email address
#TRYDOCKCMD MANAGER Initial language /lang es-ES y en-US
LANGUAGE=es-ES                # <-- Change to language aplication (GESTOR DE TRYTON -DOCKER-
# It can be "es,fr,de,blank". If it's blank, it doesn't automatically manage any language upon installation.
TRYTON_LANGUAGE=es            # <-- Change to language Tryton and modules (es,fr,de)
```

📄 4.1. ERP Configuration (conf/trytond.conf)
The Proteus Engine relies on this file to automatically configure your business identity. Ensure your conf/trytond.conf follows this structure so the automated setup can "hot-read" your company profile:

```bash
[database]
# Connection URI for the Docker bridge
uri = postgresql://postgres:YourPassword@tryton-postgres-1:5432/ # <-- Change YourPassword to match the value of the DB_PASSWORD
path = /var/lib/trytond/db

[company]
# Business Identity (Read by auto_full_setup.py)
name = My company name       # <-- Change your company name
currency = EUR               # <-- Change the currency the company uses

[web]
# Network binding for the container
listen = 0.0.0.0:8000

[logging]
level = INFO

```
---

## 🏗️ 5. Infrastructure Overview (compose.yml)

The system orchestrates three specialized services defined in the compose.yml file to ensure stability:

- server: The core Tryton engine. It includes a "wait-for-database" script to ensure a 100% stable startup and automatically initializes the admin user on the first run.
- cron: A dedicated container for background tasks, ensuring the main user interface remains fast and responsive.
- postgres: The database engine. It uses persistent Docker volumes, so your business data stays safe even if containers are stopped or removed.

## 🚀 5.1. Data Injection Engine (Hot-Loading)

Unlike traditional methods, this system utilizes a Hot-Loading Injection architecture. This allows the business logic to be configured without spinning up additional infrastructure or modifying the official compose.yml file.

### 🛠️ Automated Setup Process

The installer (tcd.bat) manages the configuration through the auto_full_setup.py engine:

- Injection: The script is copied on-the-fly into the active server service.
- Native Execution: It runs using the official Tryton/Proteus environment and libraries.
- Modularity: It supports different execution modes depending on the needs:
- FULL: Complete configuration (Company, Accounting, Geodata, Country, postal codes, Fiscal Years, Lenguage).

### 💡 Technical Advantage

  By eliminating the need for temporary containers (--rm), the system reduces RAM consumption during installation, prevents network conflicts between containers, and guarantees a 100% stable connection to the database by utilizing the existing official server tunnel.

---

## 🚀 6. Launching the Manager (The Pre-Flight Sequence)

When you execute tcd.bat, the system performs an 8-Step Surgical Initialization visible in your logs:

- I18n Engine: Sanitizes and loads language files (/lang).
- Environment Sync: Injects .env credentials into the session.
- Variable Validation: Checks the existence of compose.yml.
- YAML Intelligence: Bridge with PowerShell to extract ports and versions.
- Hardware Pulse: Detects if Docker Desktop is "Ready" or "Starting".
- Audit Trace: Identifies existing images/containers to optimize the boot.

---

## 🛠️ 7. First Deployment (Option 0: Install)

 The "Turnkey" Solution: For the first time, if it detects that the images do not exist in Docker, the installation is automatically activated (option 0 Full deployment)

- Automated Pull: Downloads official Tryton and PostgreSQL images for the detected version .
- Dynamic Data Injection: For the Demo environment, it uses `curl` to fetch the specific dump (e.g., `database-7.8.dump`) matching the active version.
- Layered Installation: Installs 41 core modules across 8 functional blocks (Core, Accounting, MRP, etc.).
- Language Activation: Automatically installs and syncs `es`, `fr`, or `de` translations.
- Network Creation: Sets up the internal Docker bridge.
- Schema Initialization tryton:Automatically creates the tryton database and sets up the admin user using the .env credentials.
- Schema initialization tryton-demo: Automatically creates the tryton-demo database with its official data using the demo user and demo password.
- Creation of official data: Company, users, parties, fiscal year, sequences, accounting periods, countries, subdivisions and postal codes.
- Client Launch: Upon success, it triggers the Verified Connectivity Protocol.

The next step is to navigate the menus to check your options:

## 📋 8. Main Menu Options

The operations menu is organized as an execution lifecycle:

- `0` performs initial installation/bootstrap when the environment is not yet prepared.
- `1` to `3` cover daily runtime control (status, start, stop).
- `4` and `5` focus on observability (logs and error audit).
- `6` and `7` provide data protection (backup and restore).
- `8` and `9` are setup paths for production/demo module and database flows.
- `10` validates connectivity and opens the web client when checks pass.

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
| **10** | `client.bat` | Start client webpage                  |

---

## 🧠 8. The Proteus Engine: Zero-Touch Configuration ⚡

The automation engine runs inside the Tryton container and supports targeted execution modes:

- `FULL`: Runs end-to-end setup (module sync, geodata, language flow, company/accounting setup, fiscal years and sequences).
- `GEO`:  Runs only countries/postal-codes import for selected ISO (`es`, `fr`, `de`).
- `LANG`: Runs only language/translation activation and upgrade flow.
- `ACC`:  Runs only company/accounting/fiscal setup (chart linkage, fiscal years, periods, invoice/account sequences).

Implemented setup tasks include:

- Connection/bootstrap retries against Tryton/DB.
- Module synchronization and config wizard cleanup.
- Company resolution/creation from `trytond.conf`/environment.
- Language activation and admin language assignment.
- Chart/account linkage by localization package.
- Fiscal years (2026 to 2030), periods, and invoice sequences.
- Countries from /trytond/modules/country/scripts/import_countries.py. Extract information from the Python library pycountry standards 3166-1
- Subdivisions from /trytond/modules/country/scripts/import_countries.py. Extract information from the Python library pycountry standards 3166-2
- Postal codes from /trytond/modules/country/scripts/import_postal_codes.py. Extract information from the GeoNames download path: http://download.geonames.org/export/zip/
- Operational logging to `/tmp/trytond_proteus.txt` (container path).

🚀 Why this is a Game Changer?

While other ERP installers leave you with an empty shell, __Tryton ERP Docker Manager__ delivers a ready-to-invoice environment.

---

## 🛠️ 9. Running the Manager

Once Docker is installed and your .env is configured:

- **Initialize:** Run `tcd.bat`
- **Access:** Open browser at `http://localhost:8000`.
- **Manage:** Use the main menu for all daily operations.

---

## 🧠 10. Connectivity & Traceability (The Project Quid)

### Verified Connectivity (client.bat)

Accessing Tryton follows a **4-Layer Protocol**:

- **Layer 1:** Inspects Docker container state.
- **Layer 2:** Verifies Port 8000 via `netstat`.
- **Layer 3:** PowerShell probes for a valid HTTP 200/302 response.
- **Layer 4:** Launches browser only if layers 1-3 pass.


The manager includes a **High-Fidelity Audit Suite**:

- **XML Integrity:** Scans all `.xml` files, classifying them as **STRUCTURE** or **DATA**.
- **Module Audit:** Verifies the `activated` status of all 41 modules vs the `.env` requirements.
- **DB Audit:** Validates PostgreSQL Roles (Superuser check), Extensions (`plpgsql`), and UTF8 encoding in **<1 second**.

Advanced Diagnostics:

All events are recorded in /log/tryton_YYYYMMDD.log. The manager correlates system actions with Docker logs, allowing technicians to solve complex "role not found" or "connection refused" issues in seconds.
                 |
### 🛡️ Security & Maintenance

- Modular Guard: startcontrol.bat prevents accidental direct execution of sub-scripts, forcing all operations through the secure tcd.bat.
- Version-Aware: Automatically adapts to **7.8.4, 7.8.5, and beyond** without code changes.
- Privilege Check: Audits PostgreSQL to ensure the `postgres` user has `Create DB` and `Superuser` roles.
- Proactive Auditing: Option 5 (errors.bat) automatically filters thousands of log lines to show you only critical FATAL or EXCEPTION errors.
- Reliable Backups: Option 6 ensures your business data is backed up into a secure file with timestamps.
- Smart Docker Start: startdocker.bat automatically locates Docker Desktop using PowerShell and URI protocols if it's not already running.
- Easy Recovery: If something goes wrong, Option 7 guides you through a full restoration of your data.

### Advanced Diagnostics & Forensic Auditing

The manager includes a **High-Fidelity Audit Suite**:

-XML Integrity: Scans all `.xml` files, classifying them as **STRUCTURE** or **DATA**.
-Module Audit: Verifies the `activated` status of all 41 modules vs the `.env` requirements.
-DB Audit: Validates PostgreSQL Roles (Superuser check), Extensions (`plpgsql`), and UTF8 encoding in **<1 second**.

### ❓ Troubleshooting

- Access Denied: Verify the DIR_HOME variable and ensure you are running the terminal with sufficient permissions.

- Docker Not Found: The script tries to locate the shortcut on your Desktop or the default path. Ensure Docker is correctly installed.
- The menu closes immediately: Verify the DIR_HOME variable in startcontrol.bat and ensure you have write permissions.
- Language Errors: Ensure the .txt language files are in the scripts folder and use UTF-8 encoding.
- Database connection fails: Ensure DB_PASSWORD in .env matches the one used during the first installation.
- Port 8000 blocked: Check if another application is using port 8000.
- For more information, see the Troubleshooting Guide (Common Issues) in GUIDE.md

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue for new features like cloud sync or automated updates.

### 📄 License

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