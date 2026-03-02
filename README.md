# 🛡️ Tryton ERP Docker Manager 🚀



An intuitive, menu-driven automation framework to deploy, manage, and protect your **Tryton ERP** environment on Windows.
This suite transforms complex Docker orchestration into a reliable, audited, and resilient infrastructure.
This project simplifies ERP maintenance, making it easy, secure, and professional for administrators and developers.

---

## 📋 1. Prerequisites: Installing Docker

Before launching the manager, ensure your environment meets these standards:

   1.  **Download Docker Desktop:** [Official Download for Windows](https://www.docker.com/products/docker-desktop/)
   2.  **Installation:** Follow the installer prompts. We recommend using the **WSL 2 backend** for superior performance.
   3.  **Scripting:** PowerShell 5.1+: Required for advanced YAML parsing and smart port detection via the read-compose.ps1 bridge.
   4.  **Verification:** Open your terminal and type `docker --version`. If it returns a version number, you are ready!.
   
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

This project features a robust Internationalization Engine that allows switching between English and Spanish seamlessly.

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
# Puede ser es,fr,de o blanco. Si es blanco no gestiona ningun lenguaje de forma automática al instalar
TRYTON_LANGUAGE=es            # <-- Change to language Tryton and modules (es,fr,de)
```
---

## 🏗️ 5. Infrastructure Overview (compose.yml)

The system orchestrates three specialized services defined in the compose.yml file to ensure stability:

- server: The core Tryton engine. It includes a "wait-for-database" script to ensure a 100% stable startup and automatically initializes the admin user on the first run.
- cron: A dedicated container for background tasks, ensuring the main user interface remains fast and responsive.
- postgres: The database engine. It uses persistent Docker volumes, so your business data stays safe even if containers are stopped or removed.

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
- Client Launch: Upon success, it triggers the Verified Connectivity Protocol.

The next step is to navigate the menus to check your options:

### Main Menu & Operations

### 📋 Main Menu Options

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

## 🛠️ 8. Running the Manager

Once Docker is installed and your .env is configured:

* **Initialize:** Run `tcd.bat`
* **Access:** Open browser at `http://localhost:8000`.
* **Manage:** Use the main menu for all daily operations.

---

## 🧠 9. Connectivity & Traceability (The Project Quid)

### Verified Connectivity (client.bat)

Accessing Tryton follows a **4-Layer Protocol**:

* **Layer 1:** Inspects Docker container state.
* **Layer 2:** Verifies Port 8000 via `netstat`.
* **Layer 3:** PowerShell probes for a valid HTTP 200/302 response.
* **Layer 4:** Launches browser only if layers 1-3 pass.


The manager includes a **High-Fidelity Audit Suite**:

* **XML Integrity:** Scans all `.xml` files, classifying them as **STRUCTURE** or **DATA**.
* **Module Audit:** Verifies the `activated` status of all 41 modules vs the `.env` requirements.
* **DB Audit:** Validates PostgreSQL Roles (Superuser check), Extensions (`plpgsql`), and UTF8 encoding in **<1 second**.

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
- __Author:__ [Telepieza - Mariano Vallespín]
- __Collaborator:__ Gemini (Google AI)
- __Platform:__ Windows (CMD/Batch)
- __Engine:__ Docker & Docker Compose
- __License:__ MIT  
- __Project Status:__ v1.0.0 Stable
---

##### Optimized & Documented with the help of Gemini (Google AI)