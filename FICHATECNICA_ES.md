# 📋 FICHA TÉCNICA: Proyecto TryDockCmd (v2026.1)

## 1. DESCRIPCIÓN GENERAL
**TryDockCmd** es un framework de automatización para **Tryton ERP** diseñado para entornos Windows/Linux. Su objetivo es la transición inmediata de una infraestructura vacía a un sistema contable profesional plenamente operativo (Producción/Demo) en menos de 30 minutos.

---

## 2. EL MANIFIESTO TECNOLÓGICO
* **Soberanía del Software:** Basado en Tryton (Fork de TinyERP, 2008). 100% Software Libre (GPL).
* **Integridad:** Prioridad absoluta en la consistencia contable frente al modelo comercial *freemium*.
* **Automatización:** Eliminación de la intervención manual mediante el motor **Proteus**.

---

## 3. STACK DE INFRAESTRUCTURA
| Componente | Tecnología | Función Crítica |
| :--- | :--- | :--- |
| **Contenedores** | Docker / Compose | Aislamiento de servicios (App + DB) e inmutabilidad. |
| **Base de Datos** | PostgreSQL | Persistencia industrial, concurrencia y seguridad. |
| **Orquestador** | PowerShell / Batch | Interfaz de control `tcd.bat` para gestión del ciclo de vida. |
| **Sistema Base** | Windows 10+ / WSL2 | Ejecución de kernel Linux nativo en entorno de escritorio. |

---

## 4. INGENIERÍA DEL MOTOR DE SETUP (`auto_full_setup.py`)
El núcleo del proyecto utiliza **Python + Proteus** para garantizar un despliegue sin errores:

* **Sincronización de Contexto:** Uso de `User.get_preferences(True, {})` para evitar el bloqueo de "Cold Start" en bases de datos nuevas.
* **Idempotencia Real:** Verificación lógica de registros existentes para permitir re-ejecuciones seguras.
* **Seguridad de Negocio:** Validación de reglas contables mediante la API de Proteus (Notario Digital).

---

## 5. CAPACIDADES OPERATIVAS (LAS FASES)
1.  **FASE ACC (Accounting):**
    * Creación de Empresa y vinculación de Moneda (EUR).
    * Generación de **5 ejercicios fiscales** (2026-2030).
    * Generación de **60 períodos contables** y secuencias de facturación.
    * **Localización ES:** Carga automática de 776 cuentas del Plan Contable Nacional (`account_es`).
2.  **FASE TAX (Fiscalidad):**
    * Inyección de localización española.
    * Configuración de **64 tipos de impuestos** (IVA 21%, 10%, 4%).
3.  **FASE GEO (Geografía):**
    * Carga masiva de códigos postales y subdivisiones (ES, FR, DE).

---

## 6. INTERFAZ DE COMANDOS (`tcd.bat`)
* **Instalación:** Opción `0` (Bootstrap completo).
* **Gestión de Datos:** Herramientas de `Backup` y `Restore` para entornos de pruebas.
* **Diagnóstico:** Auditores de logs y errores en tiempo real integrados.

---

## 7. VISIÓN DE FUTURO: IA Y CONECTIVIDAD
El proyecto deja el sistema **"IA-Ready"**. Al estar basado en una arquitectura de API abierta (JSON-RPC), permite la conexión de agentes de Inteligencia Artificial para la lectura de balances, conciliación automática y gestión documental sin intervención humana.