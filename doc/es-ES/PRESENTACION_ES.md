# 🚀 TryDockCmd: El Framework Definitivo para Tryton ERP (2026) - v1.1.0

## 1. FILOSOFÍA Y VISIÓN DEL PROYECTO
TryDockCmd no es solo un instalador; es una solución de ingeniería diseñada para democratizar el acceso a Tryton ERP, el sistema más sólido y ético del mercado.

* **Legado Histórico:** Nacido en 2008 como un fork de TinyERP (Odoo), Tryton mantiene la integridad técnica frente al modelo comercial. Software libre (LGPLv3).
* **Soberanía del Software:** 100% Software Libre bajo licencia GPL. Sin versiones "Enterprise" ni funciones bloqueadas.
* **Misión:** Reducir la barrera de entrada técnica de días a menos de 30 minutos mediante automatización atómica.
* **Compatibilidad Multi-Versión:** Soporte nativo para **Tryton 7.0 y 8.0**, preparado para la futura v9.0.

---

## 2. EL STACK TECNOLÓGICO (LA ARMADURA)
La fiabilidad y rapidez del despliegue se basan en una infraestructura inmutable y profesional:

| Tecnología | Rol en el Proyecto | Ventaja Clave |
| :--- | :--- | :--- |
| **Docker & Compose** | Inmutabilidad | Doble imagen (App + DB) aislada y segura. |
| **PostgreSQL** | Motor de Datos | Integridad referencial y concurrencia profesional. |
| **WSL2 (Windows 10+)** | Entorno de Ejecución | Potencia de Kernel Linux con la sencillez de Windows. |
| **PowerShell / CMD** | Orquestación | Scripts .bat y .ps1 que actúan como el "pegamento" del sistema. |

---

## 3. EL CEREBRO: PYTHON + PROTEUS + IA
El corazón del despliegue es el motor `auto_full_setup.py`, que actúa como un "usuario virtual" experto.

* **Proteus como Notario:** No inyectamos SQL directamente. Proteus valida cada regla de negocio de Tryton, asegurando que la base de datos sea legal y coherente.
* **Seguridad de Contexto:** Resolución del error "Cold Start" mediante la sincronización `User.get_preferences(True, {})`.
* **IA-Ready:** Arquitectura preparada para que agentes de Inteligencia Artificial operen la contabilidad vía API JSON-RPC.

---

## 4. INGENIERÍA DE DETALLE (LAS FASES)

### 📈 FASE ACC (Accounting)
Generación automática de la estructura vital de la empresa:
1.  **Entidad:** Creación de Empresa y Tercero (Party) con bypass de errores de contexto.
2.  **Temporalidad:** 5 ejercicios fiscales (2026-2030) y 60 períodos contables.
3.  **Localización Inteligente (ES, FR, DE):** 
    * **Tryton < 8.0:** Gestión de módulos de localización independientes (`account_es`, `account_de_skr03`).
    * **Tryton 8.0+:** Reconocimiento de la integración de planes contables en el módulo base `account`. Detección mediante "módulos ancla" (`account_statement_sepa`, `party_siret`).

### ⚖️ FASE TAX (Fiscalidad)
* Configuración automática de 64 tipos de IVA (21%, 10%, 4%) para la localización española.
* Vinculación automática de impuestos con diarios y secuencias.

### 🌍 FASE GEO (Geografía)
* Importación masiva de países, subdivisiones y códigos postales (GeoNames) para España, Francia y Alemania.

---

## 5. GESTIÓN OPERATIVA: EL MENÚ TCD.BAT
Hemos encapsulado la complejidad en una interfaz sencilla de comandos:

* **Opción 0:** Instalación "Full" (0 a 100 en 30 minutos).
* **Opción 8/9:** Gestión de base de datos de Producción y Demo.
* **Opción 6/7:** Sistema de Backup y Restore integrado.
* **Auditoría:** Visor de logs y errores en tiempo real para un control total.

---

## 6. CONCLUSIÓN
TryDockCmd convierte un "arte oscuro" en un proceso científico, repetible e impecable. Es la herramienta definitiva para consultores, desarrolladores y empresas que buscan la potencia de un ERP de clase mundial con la agilidad de la era Docker.

---

- **Autor:** [https://www.telepieza.com]
- **Colaborador:** Gemini (Google AI)
- **Plataforma:** Windows (CMD/Batch)
- **Motor:** Docker & Docker Compose
- **Licencia:** MIT  
- **Versión del proyecto** v1.1.0 estable

---

##### Optimizado y documentado con la ayuda de Gemini (Google AI)
