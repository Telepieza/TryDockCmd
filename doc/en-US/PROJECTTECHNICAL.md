# 📋 TECHNICAL DATA SHEET: TryDockCmd Project (v2026.1)

## 1. GENERAL DESCRIPTION
**TryDockCmd** is a Tryton ERP automation framework designed for Windows/Linux environments. Its goal is the immediate transition from an empty infrastructure to a fully operational professional accounting system (Production/Demo) in less than 30 minutes.

---

## 2. THE TECHNOLOGICAL MANIFESTO
* **Software Sovereignty:** Based on Tryton (Fork of TinyERP, 2008). 100% Free Software (GPL).
* **Integrity:** Absolute priority on accounting consistency vs. the "freemium" commercial model.
* **Automation:** Elimination of manual intervention via the **Proteus** engine.

---

## 3. INFRASTRUCTURE STACK
| Component | Technology | Critical Function |
| :--- | :--- | :--- |
| **Containers** | Docker / Compose | Service isolation (App + DB) and immutability. |
| **Database** | PostgreSQL | Industrial persistence, concurrency, and security. |
| **Orchestrator** | PowerShell / Batch | `tcd.bat` control interface for lifecycle management. |
| **Base System** | Windows 10+ / WSL2 | Native Linux kernel execution in a desktop environment. |

---

## 4. SETUP ENGINE ENGINEERING (`auto_full_setup.py`)
The project core uses **Python + Proteus** to ensure error-free deployment:

* **Context Synchronization:** Utilizing `User.get_preferences(True, {})` to avoid "Cold Start" locks in new databases.
* **Real Idempotency:** Logical verification of existing records to allow safe re-executions.
* **Business Security:** Business rule validation via the Proteus API (Digital Notary).

---

## 5. OPERATIONAL CAPABILITIES (PHASES)
1. **ACC PHASE (Accounting):**
    * Company creation and Currency linking (EUR).
    * Generation of **5 fiscal years** (2026-2030).
    * Generation of **60 accounting periods** and billing sequences.
    * **ES Localization:** Automatic load of 776 accounts from the Spanish Chart of Accounts (`account_es`).
2. **TAX PHASE (Taxation):**
    * Spanish localization injection.
    * Configuration of **64 tax types** (VAT 21%, 10%, 4%).
3. **GEO PHASE (Geography):**
    * Bulk loading of postal codes and subdivisions (ES, FR, DE).

---

## 6. COMMAND INTERFACE (`tcd.bat`)
* **Installation:** Option `0` (Full Bootstrap).
* **Data Management:** Integrated `Backup` and `Restore` tools for testing environments.
* **Diagnostics:** Integrated real-time log and error auditors.

---

## 7. FUTURE VISION: AI & CONNECTIVITY
The project leaves the system **"AI-Ready."** Based on an open API architecture (JSON-RPC), it allows AI agents to connect for balance reading, automatic reconciliation, and document management without human intervention.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.0 estable
  
---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
