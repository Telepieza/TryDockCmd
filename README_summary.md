# 🛡️ Tryton ERP Docker Manager v1.0.0

> **Turnkey Automation for Tryton ERP on Windows.**
> *By Telepieza - Mariano Vallespín & Gemini AI*

---

## 🚀 1. Quick Start (Turnkey)

1. **Config:** Edit `.env` with your credentials and `LANGUAGE` (es-ES / en-US).
2. **Launch:** Run `tcd.bat` (automatic installation).
* *The manager will auto-pull images, create DBs (Real & Demo), inject dynamic data for v7.8.x+, and activate 41 core modules.*


---

## 📊 2. Main Menu & Operations

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

## 🔍 3. Advanced Forensic Auditing

The system performs a **3-Layer Audit** in < 4 seconds:

1. **Infrastructure:** Validates PostgreSQL Roles (Superuser), UTF8 Encoding, and Extensions.
2. **Logic (XML):** Scans all module files classifying them as **STRUCTURE** or **DATA**.
3. **Consistency:** Verifies if 41 modules (Accounting, MRP, Sales, etc.) are correctly `activated`.

---

## 🌍 4. Smart Features

* **Dynamic I18n:** Adaptive table formatting for English and Spanish (Elastic Pipes).
* **Version-Aware:** Automatically fetches the correct `.dump` via `curl` based on the active Docker tag.
* **Semantic Colors:** Visual alerts (Green=Success, Red=Error, Yellow=Working).
* **Isolation:** Complete separation between `tryton` (Production) and `tryton_demo` (Lab).

---

## 🛠️ 5. Requirements

* **Docker Desktop** (WSL 2 recommended).
* **PowerShell 5.1+** (Internal bridge).
* **Permissions:** Write access for `/log` `/tmp` `/sql`and `/backup`.

---

## 📄 License

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