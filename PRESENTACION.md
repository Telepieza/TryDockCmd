# 🚀 TryDockCmd: The Ultimate Framework for Tryton ERP (2026)

## 1. PROJECT PHILOSOPHY AND VISION
TryDockCmd is not just an installer; it is an engineering solution designed to democratize access to Tryton ERP, the most robust and ethical system on the market.

* **Historical Legacy:** Born in 2008 as a fork of TinyERP (Odoo), Tryton maintains technical integrity over commercial models.
* **Software Sovereignty:** 100% Free Software under the GPL license. No "Enterprise" versions or locked features.
* **Mission:** To reduce the technical entry barrier from days to less than 30 minutes through atomic automation.

---

## 2. THE TECHNOLOGY STACK (THE ARMOR)
The reliability and speed of the deployment are based on a professional, immutable infrastructure:

| Technology | Role in Project | Key Advantage |
| :--- | :--- | :--- |
| **Docker & Compose** | Immutability | Isolated and secure dual-image (App + DB) setup. |
| **PostgreSQL** | Database Engine | Professional referential integrity and concurrency. |
| **WSL2 (Windows 10+)** | Execution Environment | Native Linux Kernel power with Windows simplicity. |
| **PowerShell / CMD** | Orchestration | .bat and .ps1 scripts acting as the system "glue". |

---

## 3. THE BRAIN: PYTHON + PROTEUS + AI
The core of the deployment is the `auto_full_setup.py` engine, acting as an expert "virtual user."

* **Proteus as a Digital Notary:** We do not inject raw SQL. Proteus validates every Tryton business rule, ensuring the database is legal and consistent from second one.
* **Context Security:** Resolved the "Cold Start" error using `User.get_preferences(True, {})` synchronization.
* **AI-Ready:** Architecture prepared for AI agents to operate accounting automatically via JSON-RPC API.

---

## 4. DETAILED ENGINEERING (THE PHASES)

### 📈 ACC PHASE (Accounting)
Atomic generation of the company’s vital structure:
1. **Entity:** Creation of Company and Party with context-error bypass.
2. **Temporality:** 5 fiscal years (2026-2030) and 60 accounting periods.
3. **Spanish Localization:** Injection of 776 accounts from the National Chart of Accounts (account_es).
    * *Note: FR and DE localizations are on the roadmap for future versions.*

### ⚖️ TAX PHASE (Taxation)
* Automatic configuration of 64 tax types (VAT 21%, 10%, 4%) for Spanish localization.
* Automatic linking of taxes with journals and sequences.

### 🌍 GEO PHASE (Geography)
* Bulk import of countries, subdivisions, and postal codes (GeoNames) for Spain, France, and Germany.

---

## 5. OPERATIONAL MANAGEMENT: TCD.BAT MENU
Complexity encapsulated in a simple interactive command interface:

* **Option 0:** Full Installation (0 to 100 in 30 minutes).
* **Option 8/9:** Dual Production and Demo database management.
* **Option 6/7:** Integrated Backup and Restore system.
* **Audit:** Real-time log and error viewer for total control.

---

## 6. CONCLUSION
TryDockCmd turns a "dark art" into a scientific, repeatable, and flawless process. It is the definitive tool for consultants, developers, and companies seeking world-class ERP power with the agility of the Docker era.