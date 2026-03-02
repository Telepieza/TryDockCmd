# Contributing to TryDockCmd 🤝

Thank you for considering contributing to **TryDockCmd**! Your help makes this tool more robust for the entire Tryton community.

### 🛠️ How Can I Contribute?

#### 1. Reporting Bugs 🐛

* **Crucial:** Attach the relevant log file from the `/log` folder. Our **Smart-Audit** system provides the exact trace needed to identify the failure.
* **Context:** Describe your environment (Windows version, Docker Desktop backend, and `.env` configuration—**always masking passwords!**).

#### 2. Suggesting Enhancements ✨

* Open an issue with the tag `enhancement`.
* Ideas like **Cloud Backup Sync**, automated **SSL (Nginx/Traefik)**, or custom UI themes are highly welcome.

#### 3. Pull Requests (PRs) 🚀

1. **Fork** the repository.
2. Create a **Feature Branch** (`git checkout -b feature/AmazingFeature`).
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4. **Push** to the branch (`git push origin feature/AmazingFeature`).
5. Open a **Pull Request**.

---

### 📏 Coding Standards (The "TryDock" Way)

To maintain the project's integrity, please follow these core principles:

* **Native Compatibility:** Scripts must maintain 100% compatibility with **Windows CMD (Batch)**.
* **I18n Compliance:** If you add a feature, you **must** update both `en-US.txt` and `es-ES.txt` in the `/lang` folder.
* **Security Guard:** Never hardcode paths or credentials. Always use established variables and the `startcontrol.bat` guard.
* **Modular Architecture:** New features should be independent `.bat` files in the `/scripts` folder, called via `tcd.bat`. Keep scripts lean.
* **PowerShell Bridge:** For complex data parsing (JSON, YAML, Network), use a `.ps1` script as a bridge. **Avoid third-party binaries.**
* **Adaptive Layout:** Ensure any new table or log output respects the **Elastic Pipe** logic (dynamic spacing based on language).

---

### ❓ Questions?

Feel free to open a discussion or contact the maintainer at **[Telepieza - Mariano Vallespín]**.

**Let's build the best Tryton management tool together!**

---

* **Author:** [Telepieza - Mariano Vallespín]
* **Collaborator:** Gemini (Google AI)
* **Engine:** Docker & Docker Compose
* **Status:** v1.0.0 Stable | 2026

---

##### Optimized & Documented with the help of Gemini (Google AI)

