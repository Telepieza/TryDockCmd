# 🛡️ Tryton ERP Docker Manager v1.1.35 - RESUMEN

**Misión principal:** Desplegar un entorno profesional de Tryton ERP desde cero hasta que esté plenamente funcional en menos de 30 minutos en Windows.

---

## 🧠 1. El Motor Proteus (Configuración Zero-Touch)
El sistema utiliza un "cerebro" Python Proteus para evitar horas de configuración manual:
1. **Ingeniería Fiscal:** Genera automáticamente ejercicios fiscales (2026-2030), periodos y secuencias.
2. **Localización Inteligente:** Activa automáticamente ES, FR o DE y vincula los planes contables específicos.
3. **Maestría en Geodatos:** Importación nativa de países, subdivisiones y códigos postales (GeoNames).

## 📦 2. Nuevo Motor de Módulos Híbrido (v1.1.30)
Gestiona flujos de negocio complejos no incluidos en las imágenes oficiales:
- **Inyección Nativa:** Inyección de código pura para Facturae, Verifactu y SII.
- **Inteligencia de Dependencias:** Instala automáticamente SignXML, pyOpenSSL y XMLSIG dentro del contenedor.
- **Jerarquía de Proveedores:** Prioriza Comunidad (Heptapod) > Local > NaN-tic (GitHub).
- **Anclaje Contable:** Detecta su "PREFIX" para prevenir conflictos entre modelos de NaN-tic y la Comunidad.

## 📊 3. Menú Principal y Operaciones

| Opción | Descripción |
| :---:  | :--- |
| **0**  | **Bootstrap Completo:** Despliegue automatizado e inicialización de la base de datos. |
| **1-3**| **Ciclo de vida:** Estado, Arranque y Parada controlada. |
| **4-5**| **Observabilidad:** Logs en tiempo real y Auditoría Forense de Errores (24h). |
| **6-7**| **Protección de Datos:** Copia de seguridad (Hot-backup) y Recuperación ante desastres (verificado por MD5). |
| **8**  | **Gestor de MODs:** Instalación de paquetes de sistema, dependencias Python y módulos externos. |
| **9**  | **Laboratorio Demo:** Instala datos oficiales de demo de Tryton para pruebas. |
| **10** | **Cliente:** Comprobación de conectividad + lanzamiento automatizado del navegador. |

## 🔍 4. Auditoría Forense
- **Integridad XML:** Clasifica los archivos como ESTRUCTURA o DATOS para detectar errores de carga.
- **Sincronización de Módulos:** Verifica el estado `activated` de todos los módulos del núcleo y externos.
- **Trazabilidad:** Registra los hashes de commit para todas las inyecciones de código externas.

## 🛠️ 5. Requisitos y Compatibilidad
- **SO:** Windows 10/11 + Docker Desktop (se recomienda WSL2).
- **Motor:** Puente PowerShell 5.1+ para el procesamiento de YAML.
- **Tryton:** Soporte completo para **7.0 (LTS)** y **8.0**.

---

- __Autor:__ [https://www.telepieza.com]
- __Colaborador:__ Gemini (Google AI)
- __Plataforma:__ Windows (CMD/Batch)
- __Motor:__ Docker & Docker Compose
- __Licencia:__ MIT
- __Versión del proyecto:__ v1.1.30 estable

---
Video guia en youtube: https://youtu.be/4i9TWQKoBeQ
