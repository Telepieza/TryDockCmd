

# 📖 TryDockCmd: Full Guide & Troubleshooting

Follow this guide to master the deployment and maintenance of your **Tryton ERP** environment on Windows.

---

### 1. Prerequisites (Infrastructure Check)

Ensure your system meets these standards:

* **Docker Desktop:** [Official Download](https://www.docker.com/products/docker-desktop/).
* **WSL 2 Backend:** Recommended for 3x faster database I/O.
* **PowerShell 5.1+:** Built-in on Windows 10/11 (Required for YAML parsing).
* **Permissions:** Admin privileges are recommended for the first installation to manage network bridges.
* **Terminal:** CMD or PowerShell with administrator privileges (recommended for the first install).
  
---

### 2. Setup & Configuration

#### Step A: Environment Variables (.env) ####
1. **Clone/Download** [TryDockCmd](https://github.com/Telepieza/TryDockCmd.git) this repository to your preferred folder.
2. **Edit `.env`:** Update your credentials. **TryDockCmd** will use these to build your safe environment.
```bash
    DB_PASSWORD=your_db_secret_pass    # <-- Set a secure password for PostgreSQL
    PASSWORD=your_admin_pass           # <-- Set your Tryton 'admin' login password
    LANGUAGE=es-ES                     # <-- Set your UI preference (es-ES or en-US)
    EMAIL=youremail@yourdomain.com     # <-- Set your email
    TRYTON_LANGUAGE=es                 # <-- Set your Tryton language (es or fr or de)

```
#### Step B: ERP Business Identity (conf/trytond.conf) ####

Crucial for Automation: The Proteus Engine reads this file to set up your company.
```bash
[database]
uri = postgresql://postgres:password@tryton-postgres-1:5432/
[company]
name = My Empresa                    # <-- Company Name (Auto-created)
currency = EUR                       # <-- Base Currency (Auto-linked)
```
---

### 3. Launching the Manager (The 8-Step Trace)

When you execute **`tcd.bat`**, the system performs a **Pre-Flight Sequence**:

* **I18n Init:** Loads and cleans your language file (Elastic Pipe logic).
* **Env Injector:** Synchronizes credentials.
* **YAML Parser:** Connects with PowerShell to read `compose.yml` metadata.
* **Docker Engine Pulse:** Automatically wakes up Docker Desktop if inactive.
* **Image Audit:** Verifies existence of Tryton & Postgres images before starting.

---

### 4. First Deployment & Connectivity

By selecting **Option 0 (Install)**, the manager executes a two-phase surgical strike:

#### Phase 1: Infrastructure
  1. **Orchestrate:** Pull images, create networks, and persistent volumes.
  2. **Initialize tryton:** Build the tryton DB and setup the admin user.
  3. **Initialize tryton-demo:** Build the tryton-demo database with official data and log in as user demo password demo.
  4. **Verify:** Run the **Verified Launch Protocol** (netstat check + HTTP Handshake).
  5. **Access:** Automatically open `http://localhost:8000` only if the service is 100% ready.

#### Phase 2: The Proteus Brain (auto_full_setup.py)
   1. **Auto-Wizard:** Completes all post-install assistants via API.
   2. **Fiscal Setup:** Generates Years (2026-2028), monthly periods, and sequences.
   3. **I18n Sync: Binds** languages to users and translates the entire database.

---

### 🛠️ Common Operations Reference

| Goal | Action |
| --- | --- |
| **Start Services** | Press **2** (Start) |
| **Stop Services** | Press **3** (Stop) |
| **Health Check** | Press **1** (Status) - Audits DB, Roles, and Modules. |
| **View Errors** | Press **5** (Smart Audit) - Filters last 24h of logs. |
| **Safety Backup** | Press **6** (Hot-Backup) - Instant SQL export. |

---

### 🆘 Troubleshooting Guide (Common Issues)

If TryDockCmd is not behaving as expected, check these common scenarios before opening an issue.

#### 1. "Docker is not running" Error

* **Symptom:** Script stops after the banner.
* **Fix:** Wait for the Docker whale icon to turn solid green. The manager's **Auto-Healing** will try to start it for you, but manual wake-up is sometimes needed on slow HDDs.

#### 2. Port 8000 or 5432 is Busy

* **Symptom:** "Address already in use" in logs.
* **Fix:** Run `netstat -ano | findstr :8000`. Kill the PID or change the ports in `.env`.

#### 3. Forensic Audit Failures

* **Symptom:** Option 1 or 8 shows **[NOT ACTIVATED]** for core modules.
* **Fix:** Your `ir.model.data` might be out of sync. Run Option 0 again to trigger a module update (`-u all`).

#### 4. Database Restore / Permission Issues

* **Symptom:** "Role 'postgres' does not exist".
* **Fix:** Ensure `DB_PASSWORD` in `.env` matches the original one used during the first install. If you changed it later, you must reset the volume or update the role manually via psql.

#### 5. Database Restore Fails (Permission/Connection)

   - Symptom: "Role 'postgres' does not exist" or "Connection refused".
   - Solution: * Ensure the DB_PASSWORD in .env matches the one used when the volume was first created.
   - Crucial: If you change the password in .env after the first install, you must delete the volume (docker volume rm ...) for the change to take effect in a new database.

#### 6. Special Characters in Passwords

   - Symptom: Random crashes or "Variable not defined" errors.
   - Solution: Batch scripts can be sensitive to characters like &, |, or ^. Try using alphanumeric passwords or wrap them in double quotes within your logic if the script supports it.

#### 7. log or tmp Files are Empty

   - Symptom: Option 4 and 5 show no data.
   - Solution: Ensure the /log or /tmp folder has write permissions and that your docker-compose.yml is correctly redirecting stdout to the driver.

---

### 🔍 How to provide a good Bug Report

If the **Smart Audit (Option 5)** doesn't solve it, please provide:

1. A screenshot of the terminal.
2. The last 20 lines of the relevant log in `/log`.
3. The output of the **Forensic Audit** (Option 1).

---
- __Author:__ [Telepieza - Mariano Vallespín]
- __Collaborator:__ Gemini (Google AI)
- __Platform:__ Windows (CMD/Batch)
- __Engine:__ Docker & Docker Compose
- __License:__ MIT  
- __Project Status:__ v1.0.0 Stable
---

##### Optimized & Documented with the help of Gemini (Google AI)