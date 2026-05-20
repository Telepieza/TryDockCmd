# External Module and Dependency Installation Guide (v1.1.30)

This guide details the operation of the Tryton extension system using the **TryDockCmd** manager, focusing on the installation of system packages, Python dependencies, and community or partner modules.

## 1. System Philosophy

As of version 1.1.30, TryDockCmd uses a hybrid engine for managing modules not included in the official Docker image. The system is divided into two layers:
1. **Interface (`install_modules.bat`)**: Interactive menu for selecting what to install.
2. **Engine (`install_external.bat`)**: Intelligent logic that resolves dependencies, searches remote or local repositories, and injects the code into the container.

## 2. The Installation Menu (TCD Option 8)

The **Package and Module Installation** menu offers the following critical sections:

### 2.1 Preparation (Options 1 and 2)
- **Backup (Option 1)**: It is **mandatory** to perform a backup before proceeding. Module injection modifies the container's file structure and the database.
- **Git and Mercurial (Option 2)**: Installs `git` and `hg` (Mercurial) inside the container. This is a prerequisite for the engine to download code in real-time from remote repositories (GitHub for NANTIC, Heptapod for COMMUNITY).

### 2.2 Python Dependencies (Options 3 to 6)
Dependency installation varies depending on the module's origin:

1. **SignXML**: Absolutely required for **NANTIC** and **COMMUNITY** modules (necessary for XAdES signing of Facturae and Verifactu).
2. **XMLSIG / pyOpenSSL / Jinja2**: These dependencies are specific and required only by **NANTIC** workflows for managing advanced communications with the AEAT (Spanish Tax Agency) and dynamic document generation.

### 2.3 Business Flows (Options 7 to 9)
Allows automated installation of:
- **Facturae**: Spanish electronic invoicing.
- **Verifactu**: Compliance with the new anti-fraud regulations (AEAT).
- **SII**: Immediate Information Supply.

> **Note**: The system automatically detects whether to install the version for Tryton 7.0, 7.2, 7.4, 7.6, 7.8, or 8.0 based on your `.env` configuration. It is recommended that the installation be performed with 7.0, as it is the most stable LTS version.

## 3. The Injection Engine (`install_external`)

When you select a module (Facturae, Verifactu, or SII), the engine performs the following steps:

### 3.1 Dependency Resolution
The script not only installs the requested module but also recursively analyzes the `tryton.cfg` file and searches for all necessary dependencies for each module (`account_es_aeat`, `certificate_manager`, etc.).

### 3.2 Accounting Anchor Logic (PREFIX Validation)
To avoid critical conflicts in Spanish accounting, the engine analyzes the `setup.py` file of the already installed `account_es` module in the container:

- **If `PREFIX.*'nantic'` is detected**: The system identifies that the accounting base is from NaN-tic and will install packages from its official GitHub: `https://github.com/NaN-tic/trytond-{module_name}.git`.
- **If the prefix is NOT detected**: The system assumes a **COMMUNITY** installation and will attempt to download from Heptapod. If it fails, it will search in the local **TRYDOCKCMD** path (`modules/es/{version}/`).

> **Important**: If the system detects that the accounting base is not from NANTIC, it will automatically block NANTIC as a provider to prevent mixing incompatible accounting models.

### 3.3 Multi-Provider Strategy and Version Resolution
The engine follows a strict search sequence to ensure stability and compatibility. For each module and its dependencies, the following process is performed:

1.  **Existence Verification**:
    *   First, it checks if the module is already **activated in the Tryton database**.
    *   If not activated, it checks if it physically exists in the container (`!TRYTON_BASE_MODULE!/module_name`) or if it is importable as a Python package (`python3 -c "import trytond.modules.module_name"`).
    *   If the module already exists or is activated, it is marked as `NATIVE` or `already installed` and its download is skipped.

2.  **Provider Search (Priority Order)**:
    *   **COMMUNITY (Heptapod)**:
        *   **Base URL**: `https://foss.heptapod.net/tryton-community/modules/`
        *   **Version Logic**:
            1.  Attempts to clone the **branch** that matches the Tryton LTS version (e.g., `7.0`).
            2.  If the specific branch does not exist or is incompatible (checked against the `tryton.cfg` of the cloned module), it attempts with the `default` branch.
            3.  If `default` is also incompatible, it searches for the highest **tag** compatible with the LTS version (e.g., `7.0.x`).
            4.  **Restriction**: The module version cannot be higher than the Tryton version installed on the system.
        *   **Installation**: Uses `hg clone` to download the repository to a temporary folder on the host. Then, it injects the files directly into the Tryton volume inside the container. If the module has a `setup.py`, it executes it to register the `entry-points`.
        *   **Audit**: Records the module name, provider (`COMMUNITY`), branch/tag used, and commit **Hash (ID)** in `log/modules_git_audit.log`.

    *   **TRYDOCKCMD (Local)**:
        *   **Path**: Searches in the local `modules/` folder on the host (`!DIR_MODULES!\!TRYTON_LANGUAGE!\!TRYTON_BRANCH!\!module_name!`).
        *   **Installation**: If the module is found locally, it injects it directly into the Tryton volume inside the container.
        *   **Audit**: Records the module name, provider (`TRYDOCKCMD`), branch (`!TRYTON_BRANCH!`), and `LOCAL_CP` as hash in `log/modules_git_audit.log`.

    *   **NANTIC (GitHub)**:
        *   **Base URL**: `https://github.com/NaN-tic/`
        *   **Name Mapping**: The system uses an internal mapping to translate the module name (e.g., `account_es_verifactu`) to the GitHub repository name (e.g., `trytond-aeat_verifactu`) and the Python package name (`nantic-aeat-verifactu`).
        *   **Version Logic**:
            1.  Attempts the branch that matches the full Tryton version (e.g., `7.0.49`).
            2.  If it does not exist, it attempts the LTS version branch (e.g., `7.0`).
            3.  If still not found, it searches in the `main`, `master`, or `default` branches.
        *   **Installation**:
            *   **Standard Modules**: Uses `pip install git+<URL>@<branch>#egg=<pip_package_name>` to install the module directly from GitHub inside the container.
            *   **"Pure" Modules**: For certain NaN-tic modules that have old or problematic `setup.py` files (e.g., `account_common`, `account_es_facturae`), the engine uses a **Pure Injection** technique. This involves cloning the repository with `git clone` to a temporary folder on the host, injecting the files directly into the Tryton volume, and then executing `python3 setup.py install` inside the container to register the `entry-points`. This ensures that all files (XML, locales, etc.) are copied correctly.
        *   **Audit**: Records the module name, provider (`NANTIC` or `NANTIC_PURE`), branch used, and commit hash in `log/modules_git_audit.log`.

3.  **Dependency Analysis (`tryton.cfg`)**:
    *   Once a module is located (either native, local, or downloaded), the engine extracts its `tryton.cfg` file from the container.
    *   It analyzes the `[depends]` section of this file to identify any additional dependencies.
    *   These new dependencies are added to a queue for processing, ensuring that the entire dependency tree is resolved.

4.  **Compatibility Validation**:
    *   For each located module, its version is extracted from `tryton.cfg`.
    *   The major version (e.g., `7.0`) is compared with the installed Tryton version. If they do not match, a warning or error is issued.
    *   Installation of modules with higher patch versions (e.g., `7.0.50` over `7.0.49`) is allowed as they are compatible updates.

### 3.4 Module Activation in Tryton
Once all modules and their dependencies have been located and injected into the container, the system proceeds to activate them in the Tryton database:

1.  **Initial Activation**:
    *   The command `trytond-admin -c /etc/trytond.conf -d !DB_NAME! -l !TRYTON_LANGUAGE! -u !EXTERNAL_MODULE! --activate-dependencies --email !EMAIL! -vv` is executed.
    *   This command activates the main module (`!EXTERNAL_MODULE!`) and all its dependencies in the database, using the configured language (`!TRYTON_LANGUAGE!`) and logging detailed activity (`-vv`).

2.  **Module List Update**:
    *   `trytond-admin -c /etc/trytond.conf -d !DB_NAME! --update-modules-list` is executed.
    *   This command updates the `ir_module` table in the database with the list of available modules in the container's file system. It is crucial for Tryton to recognize newly injected modules.

3.  **Global Update and Translations**:
    *   Finally, `trytond-admin -c /etc/trytond.conf -d !DB_NAME! -l !TRYTON_LANGUAGE! --all --email !EMAIL! -vv` is executed.
    *   The `--all` parameter forces a complete database rebuild and reloading of all XML data.
    *   The `-l !TRYTON_LANGUAGE!` parameter ensures that all translations of the installed modules are correctly applied for the configured language, refreshing menus and interfaces.

### 3.5 Container Restart
To ensure that all changes take effect, caches are cleared, and the system stabilizes with the new modules, the engine performs a complete restart of Tryton services:

1.  **Service Shutdown**: Tryton (`trytond`) and cron (`trytond-cron`) containers are safely stopped.
2.  **Service Startup**: The containers are restarted, allowing Tryton to load the newly installed and activated modules in a clean state.

### 3.6 "Pure" Modules
To avoid common `pip` compatibility errors (such as the old `use_2to3`), the engine uses a **Pure Injection** technique:
- Clones the repository to a temporary folder.
- Injects the files directly into the Tryton volume.
- Executes `setup.py` inside the container to register the entry-points.

## 4. Compatibility with Tryton 8.0

In version 8, Tryton has integrated many localization modules into the core (`account`). The v1.1.30 guide addresses this:
- **Anchor Modules**: The engine detects whether the Spanish localization is from NANTIC or the community to avoid "PREFIX" conflicts.

## 5. Audit and Logs

Each time an external module is installed, the system generates logs for technical support:
- **Dependency Tree**: Displayed on screen during installation.
- **Audit Log**: `log/modules_git_audit.log`. Contains the module name, provider, downloaded branch, and commit **Hash (ID)** to ensure traceability.
- **XML Report**: At the end, XML files are audited to ensure there are no loading errors.

## 6. Troubleshooting

- **Branch Error**: If the module does not exist for your Tryton version (e.g., 8.0), the system will automatically search for the highest available tag or the `default` branch.
- **Localization Conflict**: If you try to install NANTIC modules on a database with community localization, the system will block it to protect the integrity of your accounting accounts.

---

- **Author:** [https://www.telepieza.com]
- **Collaborator:** Gemini (Google AI)
- **Platform:** Windows (CMD/Batch)
- **Engine:** Docker & Docker Compose
- **License:** MIT  
- **Project Status:** v1.1.30 Stable
  
---

##### Optimized & Documented with the help of Gemini (Google AI)