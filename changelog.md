# 📜 Changelog - TryDockCmd

All notable changes to this project will be documented in this file. The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

**[Versión en Español disponible aquí](changelog_es.md)**

---

## [1.1.25] - 2026-04-29

### Added
- **Dynamic Module Injection (V8):** Implemented the ability to inject custom modules (e.g., `account_es`, `account_es_sii`) from the `TryDockCmd/modules/` folder into the Tryton 8 container if they do not exist. This allows extending V8 with modules from previous or external versions.
- **Total Injection Validation:** Confirmed that injecting full folders of `account_es` and `account_es_sii` (version 7.8) provides Proteus with all the countable account templates and VAT rates needed for a functional environment in Tryton 8.
- **Cross-Version Stability:** Full compatibility validation between branches 7.8 and 8.0. All system scripts unified under the same version number to ensure deployment integrity.
- **Installation Reports:** Included `ModulesTrytonV8.md`, listing all modules contained in the Tryton version 8 Docker image.
- **Modules:** Removed `account_eu` module in version 8 due to issues with the `--update` command.
- **Proteus Integration:** Included language for the company and admin user during table creation in Tryton.

### Fixed
- **Dual V7/V8 Audit:** Corrected search paths in `_pick_account_for_taxes` to avoid the `KeyError: kind` in the 7.8 branch, ensuring the TAX phase completes successfully in both versions.
- **Proteus V7 Compatibility:** Fixed the `KeyError: 'kind'` when auto-detecting account model architecture. In versions < 8.0, the `type` field is used to filter countable accounts, while in >= 8.0, the use of `kind` is maintained.
- **Compose Interpolation:** Fixed variable syntax in `compose.yml` to prevent parsing errors and set version 7.0 as a safe fallback.
- **Hybrid V8 Strategy:** Refined the tax account searcher to prioritize manually injected PGC (Pymes/Normal) over the Tryton 8 core universal plan.
- **Hybrid V8 Localization:** Optimized Proteus to prioritize the manually injected `account_es` module, allowing the use of Pymes/Normal templates with countable accounts in Tryton 8 environments.
- **V8 Fiscal Resilience:** Fixed domain validation error in tax creation by ensuring Proteus selects accounting accounts that are not of "View" type. Added flexible search by name for receivable/payable accounts in the Universal Plan.
- **V8 Universal Templates:** Integrated exact names detected in core XMLs (`account_chart.xml`) for Spain, France, and Germany, allowing automatic creation of the accounting chart in Tryton 8 without external modules.
- **V8 French Localization:** Adjusted anchor module for France to `party_siret` in Tryton 8.0, ensuring correct detection of the integrated accounting plan.
- **V8 Integrated Localization:** Confirmed integration of accounting plans in the `account` core. Adjusted `auto_full_setup.py` to detect templates using localized generic names.
- **Tryton 8 Compatibility:** Updated `auto_full_setup.py` to use `account_statement_sepa` as the anchor module for Spanish localization, as `account_es` is integrated into the core in version 8.
- **Proteus Integration:** Added existence validation for account chart templates in `auto_full_setup.py` to prevent silent failures during account creation.
- **Chart Mapping:** Fixed `chart_mapping` in `auto_full_setup.py` to ensure proper creation of accounting accounts and tax rates in Tryton 8.
- **Command Standardization:** Solved several global variable issues in TryDockCmd.

### Changed
- **Log Optimization:** Modified `auto_full_setup.py` to list only root account templates instead of all system accounts, improving installation log readability and facilitating localization diagnosis.
- **V8 Localization Filter:** Restricted accounting and fiscal configuration for Spain only when the `account_es` module is present and active. This prevents Tryton 8 from attempting to use core universal templates, which lack countable accounts.
- **Resilience:** `auto_full_setup.py` no longer stops execution on individual action failures, allowing all tasks to be attempted and logged for auditing.
- **Diagnostics:** Added log output of all root account templates available in `setup_accounts` to facilitate localization troubleshooting.
- **Optimization:** Removed white spaces when reading the `trytond.conf` file in each option.

---

## [1.1.0] - 2026-04-28

### Added
- **Module Modularity:** Implementation of `base_modules.bat` to centralize module selection logic (F1-F8).
- **Dynamic Version Detection:** Support for differentiating Python paths between Tryton 7.X (3.11) and 8.X (3.13).
- **Localization Filtering:** Hot-detection system for language modules (ES, FR, DE) through file validation within the container.
- **Installation Reports:** Inclusion of `install_reports.bat` to audit XML integrity and module statuses post-deployment.
- **Proteus Integration:** Accounting Wizard automation and fiscal year creation (2026-2030) via `auto_full_setup.py`.

### Changed
- **Installation Orchestration:** Refactoring of `install.bat` to improve container startup resilience using recursive retries between `status.bat` and `startup.bat`.
- **UI Optimization:** Improved visualization of progress bars and timers in `global_routines.bat`.
- **Performance:** Reduced static wait times through active Docker engine status checks.

### Fixed
- **Command Standardization:** Fixed all internal calls to explicitly include the `.bat` extension, avoiding ambiguities in the Windows CMD processor.
- **Environment Validation:** Improved `startcontrol.bat` to ensure no sub-script runs without the global variable context from `tcd.bat`.

---

## [1.0.0] - 2026-03-23

### Added
- **Initial Release:** Complete management framework for Tryton ERP on Docker.
- **i18n Engine:** Native multi-language support for the manager (es-ES, en-US).
- **YAML Intelligence:** Bridge with PowerShell (`read-compose.ps1`) for dynamic port and version parsing from `compose.yml`.
- **Security Architecture:** Implementation of `startdocker.bat` with automatic Docker Desktop location via URI protocols and shortcuts.
- **Data Management:** Base scripts for Backup and Restore with MD5 integrity validation.
- **Auditing:** Initial error detection engine (`errors.bat`) with critical pattern filtering (FATAL, EXCEPTION).

---

### Labels Guide
*   `Added`: For new features.
*   `Changed`: For changes in existing functionalities.
*   `Deprecated`: For features that will be removed in future versions.
*   `Removed`: For removed features.
*   `Fixed`: For bug fixes.
*   `Security`: In case of vulnerabilities.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.25 Stable

---

##### Optimized & Documented with the help of Gemini (Google AI)
  