# ===============================================================================
# PROGRAM:   auto_full_setup.py
# PROJECT:   Tryton Docker Manager
# VERSION:   1.1.35
# DATE:      27/05/2026
# LICENSE:   MIT License
# DESCRIPTION: Enlace TryDockCmd con proteus version 7 y 8
# ==============================================================================
import warnings
import os
import re

# 1. Silencio total de Warnings de Python (Deprecation, Import, etc.)
warnings.filterwarnings("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"

import logging

# 1.5 No capturar warnings en el log para evitar que StreamHandler los saque por stdout
logging.captureWarnings(False)

# 2. Configurar loggers ruidosos para ignorar todo lo que no sea un ERROR crítico
# Se añade py.warnings (donde van los avisos capturados) y defusedxml
NOISY_LOGGERS = ["trytond", "requests", "urllib3", "zeep", "braintree", "xmlschema", "amqp", "passlib", "py.warnings", "defusedxml", "proteus", "urllib3.connectionpool"]
for logger_name in NOISY_LOGGERS:
    l = logging.getLogger(logger_name)
    l.setLevel(logging.ERROR)
    l.propagate = False  # Evita que los mensajes INFO de estas librerías lleguen al log principal

from datetime import date
import time
import sys
import configparser
import subprocess
import trytond
from decimal import Decimal
import proteus
# Añadimos p_config como alias para que coincida con la subrutina
from proteus import config as p_config, Model, Wizard 
import trytond.modules
from trytond.config import config as trytond_config
from trytond.pool import Pool

# -------------------------------------------------
# CONFIGURACIÓN DE LOGGING (Tu original mejorada)
# -------------------------------------------------
# Ruta fija por compatibilidad con scripts .bat (docker cp desde /tmp)
# Permite override opcional con SETUP_LOG_PATH.
log_path = os.environ.get("SETUP_LOG_PATH", "/tmp/trytond_proteus.txt")
os.makedirs(os.path.dirname(log_path), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_path),
        logging.StreamHandler(sys.stdout)
    ]
)

# -------------------------------------------------
# DICCIONARIOS DE MENSAJES (Tus originales intactos)
# -------------------------------------------------
RAW_LANG = os.environ.get('APP_LANGUAGE', 'es-ES').lower()
APP_LANG = RAW_LANG.split('-')[0] if '-' in RAW_LANG else RAW_LANG
MESSAGES = {
    'es': {
        'start': "--- CONEXIÓN EXITOSA ---",
        'wait': "Intento {}/10: Esperando a Postgres. {}",
        'scan': "--- ESCANEANDO MÓDULOS Y ASISTENTES ---",
        'comp_phase': "--- GESTIÓN DE EMPRESA ({}) ---",
        'comp_found': "Empresa detectada: {}",
        'comp_create': "Creando empresa '{}'...",
        'lang_phase': "--- CONFIGURACIÓN DE IDIOMAS Y TRADUCCIONES ---",
        'lang_act': "Activando idioma: {}",
        'lang_error': "Error en fase: {}",
        'fisc_year': "Ejercicio {} creado.",
        'acc_link': "Cuentas vinculadas para {}.",
        'success': "=== SETUP COMPLETADO EXITOSAMENTE ===",
        'conf_file': "Datos obtenidos del archivo: {}",
        'conf_warn': "Sin entorno ni .conf. Usando valores de emergencia.",
        'conf_active': "CONFIGURACIÓN ACTIVA -> Empresa: {} | Moneda: {}",
        'ctx_upd': "Contexto actualizado para {}. Moneda: {}",
        'admin_es': "Perfil Admin set en Español.",
        'error': "ERROR EN EL SETUP: {}",
        'seq_move': "Asientos",
        'seq_sale': "Ventas",
        'seq_sale_cn': "Abonos Venta",
        'seq_purch': "Compras",
        'seq_purch_cn': "Abonos Compra",
        'seq_pay': "Recibo Pago",
        'seq_rec': "Recibo Cobro",
        'seq_coop': "Recibo Cooperativa",
        'acc_template_not_found': "Plantilla de cuentas '{}' no encontrada para '{}'.",
        'acc_templates_available': "Plantillas de cuentas raíz disponibles: {}",
        'acc_error': "Error en el plan contable {}: {}",
        'conf_phase': "--- FASE DE CONFIGURACIÓN ---",
        'end_phase': "--- FASE {} FINALIZADA ---",
        'geo_techn': "Info técnica (Geodata) {}",
        'geo_start': "Motor Geodata: Importando Países y Códigos Postales para {}",
        'geo_step1': "Paso 1/2: Importando Países (Scripts oficiales)...",
        'geo_step2': "Paso 2/2: Importando Códigos Postales ({}). Proceso lento (Esperar) ...",
        'geo_skip1': "Los países ya están importados. Saltamos al siguiente proceso 1/2.",
        'geo_skip2': "Ya existen códigos postales para {}. Se omite el paso 2/2.",
        'geo_error': "Error durante la ejecución: {}",
        'geo_error1': "Error en script oficial (Código {})",
        'currency_not_found': "Moneda no encontrada: {}",
        'company_not_created': "El asistente no creó la empresa: {}",
        'admin_lang_skip': "Actualización de idioma admin omitida o fallida: {}",
        'invoice_seq_missing': "No hay secuencias de factura para el ejercicio.",
        'unsupported_action': "Acción no soportada: {}",
        'journal_created': "Diario contable {} creado.",
        'vat_skipped_no_module': "Localización omitida: módulos de contabilidad específicos no detectados.",
        'vat_skipped_no_account': "No se pudo crear IVA: no hay cuentas contables disponibles.",
        'vat_skipped_bad_type': "No se pudo crear {}: tipo de impuesto no compatible.",
        'vat_skipped_bad_rate': "No se pudo crear {}: campo de porcentaje no compatible.",
        'vat_created': "IVA creado para {}: {}.",
        'admin_lang_set': "Perfil Admin configurado a {}.",
        'vat_already_present': "IVA España ya existente, no recreado: {}.",
        'ar_pos_created': "Punto de Venta Argentino (Manual) configurado.",
        'ar_rate_set': "Cotización inicial ARS configurada.",
        'ar_voucher_seq': "Secuencias de recibos argentinos creadas para {}.",
        'geo_present': "Fase GEO: Códigos postales ya presentes para {}.",
        'comp_exists': "Empresa {} ya existe.",
        'comp_creating': "Creando empresa: {}",
        'acc_seq_not_found': "Fase ACC: No se encontró tipo de secuencia para asientos ({}).",
        'acc_mod_status': "Fase ACC: El módulo '{}' está en estado '{}'. No se pueden crear cuentas para '{}'.",
        'acc_tpl_found': "Localizada plantilla '{}' para '{}'.",
        'mod_not_found': "Verificación de módulo: '{}' no encontrado.",
        'mod_act_try': "Verificación de módulo: '{}' está en estado '{}'. Intentando activarlo.",
        'mod_act_succ': "Verificación de módulo: '{}' activado exitosamente.",
        'mod_act_fail': "Verificación de módulo: Falló la activación de '{}'. Estado actual: '{}'.",
        'mod_act_err': "Verificación de módulo: Error al activar '{}': {}.",
        'tryton_ver': "Versión de Tryton detectada: {}",
        'anchor_mods': "Módulos ancla de localización seleccionados (Major Ver: {}): {}",
        'diag_py': "Diagnóstico: sys.executable = {}",
        'tax_detect_code': "Fase TAX: Cuenta detectada por código '{}': {}.",
        'tax_detect_name': "Fase TAX: Cuenta detectada por nombre '{}': {}.",
        'tax_detect_ver': "Detección de impuestos - Major Ver: {}, Requisito: {}."
    },
    'en': {
        'start': "--- CONNECTION SUCCESSFUL ---",
        'wait': "Attempt {}/10: Waiting for Postgres. {}",
        'scan': "--- SCANNING MODULES AND WIZARDS ---",
        'comp_phase': "--- COMPANY MANAGEMENT ({}) ---",
        'comp_found': "Company detected: {}",
        'comp_create': "Creating company '{}'...",
        'lang_phase': "--- LANGUAGES AND TRANSLATIONS CONFIGURATION ---",
        'lang_act': "Activating language: {}",
        'lang_error': "Phase error: {}",
        'fisc_year': "Fiscal year {} created.",
        'acc_link': "Accounts linked for {}.",
        'success': "=== SETUP COMPLETED SUCCESSFULLY ===",
        'conf_file': "Data obtained from file: {}",
        'conf_warn': "No environment or .conf found. Using emergency values.",
        'conf_active': "ACTIVE CONFIGURATION -> Company: {} | Currency: {}",
        'ctx_upd': "Context updated for {}. Currency: {}",
        'admin_es': "Admin profile set to Spanish.",
        'error': "SETUP ERROR: {}",
        'seq_move': "Account Moves",
        'seq_sale': "Sales",
        'seq_sale_cn': "Sales Credit Notes",
        'seq_purch': "Purchases",
        'seq_purch_cn': "Purchase Credit Notes",
        'seq_pay': "Payment Receipt",
        'seq_rec': "Cash Receipt",
        'seq_coop': "Cooperative Receipt",
        'acc_template_not_found': "Account template '{}' not found for '{}'.",
        'acc_templates_available': "Available root account templates: {}",
        'read_error': "Configuration reading error: {}",
        'acc_error': "Error in accounting plan {}: {}",
        'conf_phase': "--- CONFIGURATION PHASE ---",
        'end_phase': "--- PHASE {} COMPLETED ---",
        'geo_techn': "Technical information (Geodata) {}",
        'geo_start': "Geodata Engine: Importing Countries & Postal Codes for {}",
        'geo_step1': "Step 1/2: Importing Countries (Official scripts)...",
        'geo_step2': "Step 2/2: Importing Postal Codes ({}). Slow process (Wait) ...",
        'geo_skip1': "Countries already seem to be loaded. Skipping Step 1/2.",
        'geo_skip2': "Postal codes already exist for {}. Skipping Step 2/2.",
        'geo_error': "Error during execution {}",
        'geo_error1': "Error in official script (Code {})",
        'currency_not_found': "Currency not found: {}",
        'company_not_created': "Company wizard did not create company: {}",
        'admin_lang_skip': "Admin language update skipped or failed: {}",
        'invoice_seq_missing': "No invoice sequence links available for fiscal year.",
        'unsupported_action': "Unsupported action: {}",
        'journal_created': "Accounting journal {} created.",
        'vat_skipped_no_module': "Localization skipped: specific accounting modules not detected.",
        'vat_skipped_no_account': "Could not create VAT: no accounting accounts available.",
        'vat_skipped_bad_type': "Could not create {}: incompatible tax type.",
        'vat_skipped_bad_rate': "Could not create {}: incompatible percentage field.",
        'vat_created': "VAT created for {}: {}.",
        'admin_lang_set': "Admin profile set to {}.",
        'vat_already_present': "Spanish VAT already exists, not recreated: {}.",
        'ar_pos_created': "Argentine POS (Manual) configured.",
        'ar_rate_set': "Initial ARS rate configured.",
        'ar_voucher_seq': "Argentine voucher sequences created for {}.",
        'geo_present': "GEO Phase: Postal codes already present for {}.",
        'comp_exists': "Company {} already exists.",
        'comp_creating': "Creating company: {}",
        'acc_seq_not_found': "ACC Phase: Sequence type for moves not found ({}).",
        'acc_mod_status': "ACC Phase: Module '{}' is in state '{}'. Accounts cannot be created for '{}'.",
        'acc_tpl_found': "Located template '{}' for '{}'.",
        'mod_not_found': "Module verification: '{}' not found.",
        'mod_act_try': "Module verification: '{}' is in state '{}'. Attempting to activate.",
        'mod_act_succ': "Module verification: '{}' successfully activated.",
        'mod_act_fail': "Module verification: Failed to activate '{}'. Current state: '{}'.",
        'mod_act_err': "Module verification: Error activating '{}': {}.",
        'tryton_ver': "Tryton version detected: {}",
        'anchor_mods': "Localization anchor modules selected (Major Ver: {}): {}",
        'diag_py': "Diagnostic: sys.executable = {}",
        'tax_detect_code': "TAX Phase: Account detected by code '{}': {}.",
        'tax_detect_name': "TAX Phase: Account detected by name '{}': {}.",
        'tax_detect_ver': "Tax detection - Major Ver: {}, Requirement: {}."
    },
    'fr': {
        'start': "--- CONNEXION RÉUSSIE ---",
        'wait': "Tentative {}/10: Attente de Postgres. {}",
        'scan': "--- ANALYSE DES MODULES ET ASSISTANTS ---",
        'comp_phase': "--- GESTION DE L'ENTREPRISE ({}) ---",
        'comp_found': "Entreprise détectée: {}",
        'comp_create': "Création de l'entreprise '{}'...",
        'lang_phase': "--- CONFIGURATION DES LANGUES ET TRADUCTIONS ---",
        'lang_act': "Activation de la langue: {}",
        'lang_error': "Erreur de phase: {}",
        'fisc_year': "Exercice comptable {} créé.",
        'acc_link': "Comptes liés pour {}.",
        'success': "=== CONFIGURATION TERMINÉE AVEC SUCCÈS ===",
        'conf_file': "Données obtenues du fichier: {}",
        'conf_warn': "Pas d'environnement ni de .conf. Utilisation de valeurs d'urgence.",
        'conf_active': "CONFIGURATION ACTIVE -> Entreprise: {} | Devise: {}",
        'ctx_upd': "Contexte mis à jour pour {}. Devise: {}",
        'admin_es': "Profil Admin configuré en Espagnol.",
        'error': "ERREUR DE CONFIGURATION: {}",
        'seq_move': "Écritures comptables",
        'seq_sale': "Ventes",
        'seq_sale_cn': "Avoirs Vente",
        'seq_purch': "Achats",
        'seq_purch_cn': "Avoirs Achat",
        'seq_pay': "Reçu de paiement",
        'seq_rec': "Reçu d'encaissement",
        'seq_coop': "Reçu de coopérative",
        'acc_template_not_found': "Modèle de compte '{}' introuvable pour '{}'.",
        'acc_templates_available': "Modèles de comptes racine disponibles: {}",
        'read_error': "Erreur de lecture de la configuration: {}",
        'acc_error': "Erreur dans le plan comptable {}: {}",
        'conf_phase': "--- PHASE DE CONFIGURATION ---",
        'end_phase': "--- PHASE {} TERMINÉE ---",
        'geo_techn': "Informations techniques (géodonnées) {}",
        'geo_start': "Moteur Geodata: Importation des Pays et Codes Postaux pour {}",
        'geo_step1': "Étape 1/2: Importation des Pays (Scripts officiels)...",
        'geo_step2': "Étape 2/2: Importation des Codes Postaux ({}).Processus lent (Patienter) ...",
        'geo_skip1': "Les pays semblent déjà être chargés. Saut de l'étape 1/2.",
        'geo_skip2': "Les codes postaux existent déjà pour {}. Saut de l'étape 2/2.",
        'geo_error': "Erreur lors de l'exécution {}",
        'geo_error1': "Erreur dans le script officiel (Code {})",
        'currency_not_found': "Devise introuvable : {}",
        'company_not_created': "L'assistant n'a pas créé l'entreprise : {}",
        'admin_lang_skip': "Mise à jour de la langue admin ignorée ou échouée : {}",
        'invoice_seq_missing': "Aucun lien de séquence de facture disponible pour l'exercice.",
        'unsupported_action': "Action non prise en charge : {}",
        'journal_created': "Journal comptable {} créé.",
        'vat_skipped_no_module': "Localisation ignorée : modules comptables spécifiques non détectés.",
        'vat_skipped_no_account': "Impossible de créer la TVA : aucun compte comptable disponible.",
        'vat_skipped_bad_type': "Impossible de créer {} : type de taxe incompatible.",
        'vat_skipped_bad_rate': "Impossible de créer {} : champ de pourcentage incompatible.",
        'vat_created': "TVA créée pour {} : {}.",
        'admin_lang_set': "Profil Admin configuré à {}.",
        'vat_already_present': "TVA Espagne déjà existante, non recréée : {}.",
        'ar_pos_created': "Terminal POS argentin (manuel) configuré.",
        'ar_rate_set': "Taux de change initial ARS configuré.",
        'ar_voucher_seq': "Séquences de reçus argentins créées {}.",
        'geo_present': "Phase GEO : Codes postaux déjà présents pour {}.",
        'comp_exists': "L'entreprise {} existe déjà.",
        'comp_creating': "Création de l'entreprise : {}",
        'acc_seq_not_found': "Phase ACC : Type de séquence pour les écritures non trouvé ({}).",
        'acc_mod_status': "Phase ACC : Le module '{}' est dans l'état '{}'. Les comptes ne peuvent pas être créés pour '{}'.",
        'acc_tpl_found': "Modèle '{}' localisé pour '{}'.",
        'mod_not_found': "Vérification du module : '{}' non trouvé.",
        'mod_act_try': "Vérification du module : '{}' est dans l'état '{}'. Tentative d'activation.",
        'mod_act_succ': "Vérification du module : '{}' activé avec succès.",
        'mod_act_fail': "Vérification du module : Échec de l'activation de '{}'. État actuel : '{}'.",
        'mod_act_err': "Vérification du module : Erreur lors de l'activation de '{}' : {}.",
        'tryton_ver': "Version de Tryton détectée : {}",
        'anchor_mods': "Modules d'ancrage de localisation sélectionnés (Major Ver : {}) : {}",
        'diag_py': "Diagnostic : sys.executable = {}",
        'tax_detect_code': "Phase TAX : Compte détecté par code '{}' : {}.",
        'tax_detect_name': "Phase TAX : Compte détecté par nom '{}' : {}.",
        'tax_detect_ver': "Détection des taxes - Major Ver : {}, Requis : {}."
    },
    'de': {
        'start': "--- VERBINDUNG ERFOLGREICH ---",
        'wait': "Versuch {}/10: Warten auf Postgres. {}",
        'scan': "--- SCANNEN VON MODULEN UND ASSISTENTEN ---",
        'comp_phase': "--- UNTERNEHMENSVERWALTUNG ({}) ---",
        'comp_found': "Unternehmen erkannt: {}",
        'comp_create': "Unternehmen '{}' wird erstellt...",
        'lang_phase': "--- SPRACH- UND ÜBERSETZUNGSKONFIGURATION ---",
        'lang_act': "Sprache aktivieren: {}",
        'lang_error': "Phasenfehler: {}",
        'fisc_year': "Geschäftsjahr {} erstellt.",
        'acc_link': "Konten verknüpft für {}.",
        'success': "=== SETUP ERFOLGREICH ABGESCHLOSSEN ===",
        'conf_file': "Daten aus Datei erhalten: {}",
        'conf_warn': "Keine Umgebung oder .conf gefunden. Notfallwerte werden verwendet.",
        'conf_active': "AKTIVE KONFIGURATION -> Unternehmen: {} | Währung: {}",
        'ctx_upd': "Kontext aktualisiert für {}. Währung: {}",
        'admin_es': "Admin-Profil auf Spanisch gesetzt.",
        'error': "SETUP-FEHLER: {}",
        'seq_move': "Buchungssätze",
        'seq_sale': "Verkäufe",
        'seq_sale_cn': "Gutschriften Verkauf",
        'seq_purch': "Einkäufe",
        'seq_purch_cn': "Gutschriften Einkauf",
        'seq_pay': "Zahlungsbeleg",
        'seq_rec': "Einnahmebeleg",
        'seq_coop': "Genossenschaftsbeleg",
        'acc_template_not_found': "Kontenvorlage '{}' für '{}' nicht gefunden.",
        'acc_templates_available': "Verfügbare Root-Kontenvorlagen: {}",
        'read_error': "Fehler beim Lesen der Konfiguration: {}",
        'acc_error': "Fehler im Kontenplan {}: {}",
        'conf_phase': "--- KONFIGURATIONSPHASE ---",
        'end_phase': "--- PHASE {} ABGESCHLOSSEN ---",
        'geo_techn': "Technische Informationen (Geodaten) {}",
        'geo_start': "Geodata-Engine: Importieren von Ländern und Postleitzahlen für {}",
        'geo_step1': "Schritt 1/2: Länder importieren (Offizielle Skripte)...",
        'geo_step2': "Schritt 2/2: Postleitzahlen importieren ({}).Es dauert etwas (Bitte warten)...",
        'geo_skip1': "Länder scheinen bereits geladen zu sein. Schritt 1/2 wird übersprungen.",
        'geo_skip2': "Postleitzahlen existieren bereits für {}. Schritt 2/2 wird übersprungen.",
        'geo_error': "Fehler bei der Ausführung {}",
        'geo_error1': "Fehler im offiziellen Skript (Code {})",
        'currency_not_found': "Währung nicht gefunden: {}",
        'company_not_created': "Der Assistent hat das Unternehmen nicht erstellt: {}",
        'admin_lang_skip': "Admin-Sprachaktualisierung übersprungen oder fehlgeschlagen: {}",
        'invoice_seq_missing': "Keine Rechnungssequenz-Verknüpfungen für das Geschäftsjahr verfügbar.",
        'unsupported_action': "Nicht unterstützte Aktion: {}",
        'journal_created': "Buchungsjournal {} erstellt.",
        'vat_skipped_no_module': "Lokalisierung übersprungen: spezifische Buchhaltungsmodule nicht erkannt.",
        'vat_skipped_no_account': "MwSt. konnte nicht erstellt werden: keine Buchhaltungskonten verfügbar.",
        'vat_skipped_bad_type': "{} konnte nicht erstellt werden: inkompatibler Steuertyp.",
        'vat_skipped_bad_rate': "{} konnte nicht erstellt werden: inkompatibles Prozentfeld.",
        'vat_created': "MwSt. erstellt für {}: {}.",
        'admin_lang_set': "Admin-Profil auf {} gesetzt.",
        'vat_already_present': "Spanische MwSt. bereits vorhanden, nicht neu erstellt: {}.",
        'ar_pos_created': "Argentinisches Kassensystem (manuell) konfiguriert.",
        'ar_rate_set': "Die anfängliche ARS-Rate wurde konfiguriert.",
        'ar_voucher_seq': "Argentinische Gutscheinsequenzen erstellt für {}.",
        'geo_present': "GEO-Phase: Postleitzahlen bereits vorhanden für {}.",
        'comp_exists': "Unternehmen {} existiert bereits.",
        'comp_creating': "Unternehmen wird erstellt: {}",
        'acc_seq_not_found': "ACC-Phase: Sequenztyp für Buchungen nicht gefunden ({}).",
        'acc_mod_status': "ACC-Phase: Modul '{}' ist im Status '{}'. Konten können für '{}' nicht erstellt werden.",
        'acc_tpl_found': "Vorlage '{}' für '{}' lokalisiert.",
        'mod_not_found': "Modul-Verifizierung: '{}' nicht gefunden.",
        'mod_act_try': "Modul-Verifizierung: '{}' ist im Status '{}'. Versuch der Aktivierung.",
        'mod_act_succ': "Modul-Verifizierung: '{}' erfolgreich aktiviert.",
        'mod_act_fail': "Modul-Verifizierung: Aktivierung von '{}' fehlgeschlagen. Aktueller Status: '{}'.",
        'mod_act_err': "Modul-Verifizierung: Fehler beim Aktivieren von '{}': {}.",
        'tryton_ver': "Tryton-Version erkannt: {}",
        'anchor_mods': "Lokalisierungs-Ankermodule ausgewählt (Major Ver: {}): {}",
        'diag_py': "Diagnose: sys.executable = {}",
        'tax_detect_code': "TAX-Phase: Konto anhand des Codes '{}' erkannt: {}.",
        'tax_detect_name': "TAX-Phase: Konto anhand des Namens '{}' erkannt: {}.",
        'tax_detect_ver': "Steuererkennung - Major Ver: {}, Anforderung: {}."
    }
}

# Obtenemos el idioma del entorno (ej: 'es-ES' -> 'es')
requested_lang = os.getenv('APP_LANGUAGE', 'en')[:2].lower()
msg = MESSAGES.get(requested_lang, MESSAGES['en'])

# -------------------------------------------------
# NUEVA FUNCIÓN: IMPORTACIÓN DE GEODATA (Inyectada)
# -------------------------------------------------
def run_geodata_import(database, config_file, iso_code):
    logging.info(msg['geo_start'].format(iso_code))
    logging.info(msg['diag_py'].format(sys.executable))
    base_mod = os.environ.get('TRYTON_BASE_MODULE', os.path.dirname(trytond.modules.__file__))
    scripts_path = f"{base_mod}/country/scripts"
    iso_up = iso_code.upper()
    try:
        # 1. COMPROBACIÓN DE PAÍSES
        Country = Model.get('country.country')
        countries_exist = False
        try:
            if len(Country.find([], limit=201)) >= 200:
                countries_exist = True
        except Exception:
            pass 
        if countries_exist:
            logging.info(msg['geo_skip1'])
        else:
            logging.debug(msg['geo_step1'])
            result = subprocess.run(
                [sys.executable, "-W", "ignore", f"{scripts_path}/import_countries.py", "-d", database, "-c", config_file],
                capture_output=True, text=True, check=True
            )
            if result.stderr:
                logging.debug(result.stderr.strip())

        # Refresco del Pool obligatorio para asegurar que PostalCode esté registrado
        p_config.get_config().pool.init()

        # 2. COMPROBACIÓN DE CÓDIGOS POSTALES (Carga perezosa)
        zips_exist = False
        try:
            Zip = Model.get('country.postal_code')
            found = Zip.find([('country.code', '=', iso_up)], limit=1)
            if found:
                zips_exist = True
                logging.info(msg['geo_present'].format(iso_up))
        except (KeyError, Exception):
            zips_exist = False

        if zips_exist:
            logging.info(msg['geo_skip2'].format(iso_up))
        else:
            logging.debug(msg['geo_step2'].format(iso_up))
            # Ejecutamos con salida en vivo para facilitar diagnóstico de cargas grandes.
            # Usamos '-W ignore' directamente en el intérprete para asegurar el silencio de avisos de 'requests'
            
            # Priorizar el script parcheado en /tmp si existe, si no usar el oficial
            local_patched = "/tmp/import_postal_codes.py"
            run_path = local_patched if os.path.exists(local_patched) else f"{scripts_path}/import_postal_codes.py"
            
            subprocess.run(
                [sys.executable, "-W", "ignore", run_path, "-d", database, "-c", config_file, iso_up],
                stdout=sys.stdout,
                stderr=subprocess.DEVNULL, # Silenciamos warnings de librerías en el subproceso
                env=os.environ.copy(),
                text=True,
                check=True
            )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(msg['geo_error1'].format(e.returncode)) from e
    except Exception as e:
        logging.debug(msg['geo_techn'].format(str(e)))
        raise
                        
# -------------------------------------------------
# FUNCIONES ORIGINALES (Tal cual me las pasaste)
# -------------------------------------------------
def get_company_config(conf_path='/config/trytond.conf'):
    logging.info(msg['conf_phase'])
    config = configparser.ConfigParser()
    env_name = os.environ.get('COMPANY_NAME')
    env_currency = os.environ.get('COMPANY_CURRENCY')
    env_journal_name = os.environ.get('COMPANY_JOURNAL_NAME')
    env_journal_code = os.environ.get('COMPANY_JOURNAL_CODE')
    env_vat_rates = os.environ.get('COMPANY_VAT_RATES')
    data = {
        'name': env_name or '',
        'currency': env_currency or '',
        'journal_name': env_journal_name or '',
        'journal_code': env_journal_code or '',
        'vat_rates': env_vat_rates or '',
    }
    if (not data['name'] or not data['currency']
            or not data['journal_name'] or not data['journal_code'] or not data['vat_rates']):
        try:
            if os.path.exists(conf_path):
                config.read(conf_path)
                if 'company' in config:
                    if not data['name']: data['name'] = config['company'].get('name', 'Telepieza')
                    if not data['currency']: data['currency'] = config['company'].get('currency', 'EUR')
                    if not data['journal_name']: data['journal_name'] = config['company'].get('journal_name', 'Diario General')
                    if not data['journal_code']: data['journal_code'] = config['company'].get('journal_code', 'GEN')
                    if not data['vat_rates']: data['vat_rates'] = config['company'].get('vat_rates', '21,10,4')
                    logging.info(msg['conf_file'].format(conf_path))
            else:
                if not data['name']: data['name'] = 'Telepieza'
                if not data['currency']: data['currency'] = 'EUR'
                if not data['journal_name']: data['journal_name'] = 'Diario General'
                if not data['journal_code']: data['journal_code'] = 'GEN'
                if not data['vat_rates']: data['vat_rates'] = '21,10,4'
                logging.warning(msg['conf_warn'])
        except Exception as e:
            logging.error(msg['read_error'].format(e))
    # Normaliza entradas potencialmente sucias desde entorno/.conf (espacios, comillas o comentarios inline).
    data['currency'] = normalize_currency_code(data.get('currency'))
    data['name'] = (data.get('name') or 'Telepieza').strip()
    data['journal_name'] = (data.get('journal_name') or 'Diario General').strip()
    data['journal_code'] = normalize_conf_value(data.get('journal_code') or 'GEN').upper()[:10]
    data['vat_rates'] = parse_vat_rates(data.get('vat_rates'))
    logging.info(msg['conf_active'].format(data['name'], data['currency']))       
    return data

def normalize_currency_code(value):
    cleaned = (value or '').strip()
    cleaned = normalize_conf_value(cleaned)
    return (cleaned or 'EUR').upper()

def normalize_conf_value(value):
    cleaned = (value or '').strip()
    if len(cleaned) >= 2 and cleaned[0] == cleaned[-1] and cleaned[0] in ("'", '"'):
        cleaned = cleaned[1:-1].strip()
    for marker in ('#', ';'):
        if marker in cleaned:
            cleaned = cleaned.split(marker, 1)[0].strip()
    return cleaned

def parse_vat_rates(raw_value):
    cleaned = normalize_conf_value(raw_value)
    if not cleaned:
        return ['21', '10', '4']
    parsed = []
    for part in cleaned.split(','):
        token = part.strip().replace('%', '').replace(' ', '')
        if not token:
            continue
        if token.isdigit() and token not in parsed:
            parsed.append(token)
    return parsed or ['21', '10', '4']

def parse_actions(raw_action):
    action_text = (raw_action or 'FULL').strip()
    if not action_text:
        return {'FULL'}
    normalized = action_text.replace('[', '').replace(']', '').replace("'", '').replace('"', '')
    tokens = [part.strip().upper() for part in normalized.replace(';', ',').split(',') if part.strip()]
    if not tokens:
        tokens = [action_text.upper()]
    return set(tokens)

def ensure_currency_available(currency_code, db_name=None, config_file=None):
    Currency = Model.get('currency.currency')
    normalized = normalize_currency_code(currency_code)
    currencies = Currency.find([('code', '=', normalized)])
    if currencies:
        return currencies[0]
    if db_name and config_file:
        base_mod = os.environ.get('TRYTON_BASE_MODULE', os.path.dirname(trytond.modules.__file__))
        import_script = f"{base_mod}/currency/scripts/import_currencies.py"
        if os.path.exists(import_script):
            try:
                result = subprocess.run(
                    [sys.executable, import_script, "-d", db_name, "-c", config_file],
                    capture_output=True, text=True, check=True
                )
                if result.stderr:
                    logging.debug(result.stderr.strip())
                p_config.get_config().pool.init()
                Currency = Model.get('currency.currency')
                currencies = Currency.find([('code', '=', normalized)])
                if currencies:
                    return currencies[0]
            except Exception as e:
                logging.debug(msg['geo_techn'].format(str(e)))
    raise ValueError(msg['currency_not_found'].format(normalized))

def get_company_language(lang_code):
    Lang = Model.get('ir.lang')
    normalized = (lang_code or APP_LANG or 'en').lower()
    short_code = normalized[:2]
    found = Lang.find([('code', '=', short_code)], limit=1)
    if found:
        return found[0]
    found = Lang.find([('code', '=', 'en')], limit=1)
    return found[0] if found else None

def connect_and_init(db_name, config_file):
    major_ver = int(trytond.__version__.split('.')[0])
    minor_ver = int(trytond.__version__.split('.')[1])

    for attempt in range(1, 11):
        try:
            # A partir de la 7.4/7.6 es necesario actualizar el singleton de config
            if major_ver > 7 or (major_ver == 7 and minor_ver >= 4):
                trytond_config.update_etc(config_file)
            p_config.set_trytond(db_name, config_file=config_file)
            pool = Pool(db_name)
            pool.init()
            logging.info(msg['start'])
            return True
        except Exception as e:
            # Opción segura: Pasamos el intento y el error convertido a string
            # Asegúrate de que tu mensaje 'wait' tenga al menos dos {} o {0} {1}
            logging.warning(msg['wait'].format(attempt, str(e)))
            time.sleep(5)
            attempt += 1
    return False

def sync_and_clean_modules():
    logging.info(msg['scan'])
    Module = Model.get('ir.module')
    ConfigWizardItem = Model.get('ir.module.config_wizard.item')
    try: Wizard('ir.module.activate_upgrade').execute('upgrade')
    except: pass
    items = ConfigWizardItem.find([('state', '!=', 'done')])
    for item in items:
        item.state = 'done'
        item.save()
    return [m.name for m in Module.find([('state', '=', 'activated')])]

def setup_or_get_company(company_name, currency_code, db_name, config_file, target_lang):
    # 1. Aseguramos que Proteus tiene el contexto de preferencias cargado
    User = Model.get('res.user')
    p_config.get_config()._context = User.get_preferences(True, {})

    Party = Model.get('party.party')
    Company = Model.get('company.company')
    Currency = Model.get('currency.currency')

    # Intentar buscar si ya existe
    existing_companies = Company.find([('party.name', '=', company_name)])
    if existing_companies:
        logging.info(msg['comp_exists'].format(company_name))
        return existing_companies[0]

    logging.info(msg['comp_creating'].format(company_name))
    
    # 2. Asegurar moneda
    usd_list = Currency.find([('code', '=', currency_code)])
    if not usd_list:
        currency = Currency(name=currency_code, code=currency_code, symbol=currency_code)
        currency.save()
    else:
        currency = usd_list[0]

    # 3. EL WIZARD (Copiando exactamente el flujo de la demo)
    company_config = Wizard('company.company.config')
    company_config.execute('company')
    
    # Crear el Party ANTES de asignarlo
    party = Party(name=company_name)
    # Asignar el idioma por defecto de la empresa (Party)
    party.lang = get_company_language(target_lang)
    party.save() # Si esto falla aquí, usa el bloque 'with cfg.set_context(company=None):' que pusimos antes
    
    company_form = company_config.form
    company_form.party = party
    company_form.currency = currency
    company_config.execute('add')

    # 4. RECARGAR CONTEXTO (Vital para que el resto del script sepa que ya hay empresa)
    config = p_config.get_config()
    prefs = User.get_preferences(True, {})
    config.context.update(prefs)

    new_company, = Company.find([('party.name', '=', company_name)])
    config.context['company'] = new_company.id
    return new_company

def activate_languages(dependencies, target_lang):
    logging.info(msg['lang_phase'])
    Lang = Model.get('ir.lang')
    Module = Model.get('ir.module')
    for code, module_name in dependencies.items():
        if Module.find([('name', '=', module_name), ('state', '=', 'activated')]):
            lang_found = Lang.find([('code', '=', code)])
            if lang_found and not lang_found[0].translatable:
                lang = lang_found[0]
                logging.info(msg['lang_act'].format(code))
                lang.translatable = True
                lang.save()
                # Forzar una actualización de módulos para que las traducciones se apliquen
                # Esto es más robusto que intentar clickear 'upgrade' en cada módulo individualmente
                # ya que el Wizard maneja las dependencias.
                Wizard('ir.module.activate_upgrade').execute('upgrade')
    try:
        admin = Model.get('res.user')(1)
        # Usar el idioma objetivo para el usuario admin
        admin_lang_obj = Lang.find([('code', '=', target_lang)])
        if admin_lang_obj:
            admin.language = admin_lang_obj[0]
            admin.save()
            logging.info(msg['admin_lang_set'].format(target_lang))
    except Exception as e:
        logging.debug(msg['admin_lang_skip'].format(str(e)))

def get_sequence_type_id(module, name, fallback_id):
    ModelData = Model.get('ir.model.data')
    try:
        data = ModelData.find([('module', '=', module), ('name', '=', name)])
        if data: return data[0].db_id
    except: pass
    return fallback_id

def create_fiscalyear(year, company):
    FiscalYear = Model.get('account.fiscalyear')
    SequenceType = Model.get('ir.sequence.type') 
    Period = Model.get('account.period')
    Module = Model.get('ir.module')

    # Detección robusta de versión
    version_parts = re.findall(r'\d+', trytond.__version__)
    major_ver = int(version_parts[0]) if version_parts else 7
    minor_ver = int(version_parts[1]) if len(version_parts) > 1 else 0

    is_v76_plus = (major_ver > 7) or (major_ver == 7 and minor_ver >= 6)
    is_strict = (major_ver > 7) or (major_ver == 7 and minor_ver >= 4)

    # 1. Sincronización de contexto (v7 compatible)
    config = p_config.get_config()
    config.context.update({'company': company.id})

    # 2. Comprobar existencia (Evitar duplicados)
    existing = FiscalYear.find([('name', '=', str(year)), ('company', '=', company.id)])
    if existing:
        fy = existing[0]
        if not Period.find([('fiscalyear', '=', fy.id)], limit=1):
            try: Wizard('account.fiscalyear.create_periods', [fy]).execute('create_periods')
            except: pass
        return fy

    # 3. Localizar Tipos de Secuencia (Resolución Híbrida v7/v8)
    def resolve_st(module, technical, fallbacks):
        # Intento 1: XML ID (Independiente del idioma)
        tid = get_sequence_type_id(module, technical, None)
        if tid: return SequenceType(tid)
        # Intento 2: Nombres conocidos
        for name in fallbacks:
            res = SequenceType.find([('name', '=', name)])
            if res: return res[0]
        return None

    st_move = resolve_st('account', 'sequence_type_account_move', 
                         ["Account Move", "Asiento contable", "Écriture comptable", "Buchungssatz"])
    st_inv = resolve_st('account_invoice', 'sequence_type_account_invoice', 
                        ["Invoice", "Factura", "Facture", "Rechnung"])

    if not st_move:
        logging.error(f"Fase ACC: No se encontró tipo de secuencia para asientos ({year}).")
        return None

    # 4. Lógica de Secuencias (Híbrida v7/v8)
    def make_seq(name_part, s_type, strict=False):
        target_model = 'ir.sequence.strict' if strict else 'ir.sequence'
        try:
            SModel = Model.get(target_model)
        except:
            SModel = Model.get('ir.sequence')
            target_model = 'ir.sequence'

        unique_name = f"{name_part} {year} ({company.party.name})"
        
        # Búsqueda filtrando por el modelo exacto para evitar conflictos
        found = SModel.find([
            ('name', '=', unique_name), 
            ('company', '=', company.id),
        ])
        
        for s_obj in found:
            if s_obj._model == target_model:
                return s_obj

        s = SModel(name=unique_name)
        s.sequence_type = s_type
        s.company = company
        s.padding = 6
        s.save()
        return s

    # En v7.0/7.2 los asientos usan secuencia normal. En v7.4+ usan secuencia estricta.
    move_seq = make_seq(msg['seq_move'], st_move, strict=is_strict)

    # 5. Construcción del Ejercicio Fiscal
    fy = FiscalYear()
    fy.name = str(year)
    fy.start_date = date(year, 1, 1)
    fy.end_date = date(year, 12, 31)
    fy.company = company

    # A. Secuencia de Asientos
    if is_v76_plus:
        _safe_set(fy, 'post_move_sequence', move_seq)
        _safe_set(fy, 'move_sequence', move_seq)
    else:
        if not _safe_set(fy, 'post_move_sequence', move_seq):
            _safe_set(fy, 'move_sequence', move_seq)

    # B. Secuencias de Facturación
    # Si el campo existe (como en v7.0 o por localizaciones en v7.8+), se debe 
    # configurar ANTES del save para evitar errores de integridad.
    if hasattr(fy, 'invoice_sequences') and st_inv:
        is_link = fy.invoice_sequences[0] if fy.invoice_sequences else fy.invoice_sequences.new()
        is_link.company = company
        is_link.out_invoice_sequence = make_seq(msg['seq_sale'], st_inv, strict=True)
        is_link.out_credit_note_sequence = make_seq(msg['seq_sale_cn'], st_inv, strict=True)
        is_link.in_invoice_sequence = make_seq(msg['seq_purch'], st_inv, strict=True)
        is_link.in_credit_note_sequence = make_seq(msg['seq_purch_cn'], st_inv, strict=True)

    # C. Localización Argentina (Vouchers y Cooperativas) - Pre-save
    if Module.find([('name', '=', 'account_voucher_ar'), ('state', '=', 'activated')]):
        st_pay = SequenceType.find([('name', 'ilike', '%voucher.payment%')])
        if st_pay: _safe_set(fy, 'payment_sequence', make_seq(msg['seq_pay'], st_pay[0]))
        st_rec = SequenceType.find([('name', 'ilike', '%voucher.receipt%')])
        if st_rec: _safe_set(fy, 'receipt_sequence', make_seq(msg['seq_rec'], st_rec[0]))

    if Module.find([('name', '=', 'cooperative_ar'), ('state', '=', 'activated')]):
        st_coop = SequenceType.find([('name', 'ilike', '%cooperative.receipt%')])
        if st_coop: _safe_set(fy, 'cooperative_receipt_sequence', make_seq(msg['seq_coop'], st_coop[0]))

    # D. GUARDADO ÚNICO DEFINITIVO
    try:
        fy.save()
        if not is_v76_plus and Module.find([('name', '=', 'account_voucher_ar'), ('state', '=', 'activated')]):
            logging.info(msg['ar_voucher_seq'].format(year))
    except Exception as e:
        logging.error(msg['error'].format(f"Al guardar ejercicio {year}: {e}"))
        return None

    # E. Configuración Global (7.6+ / 8.0)
    if is_v76_plus:
        _ensure_account_config_sequence(move_seq, year)

    # F. Períodos
    try:
        Wizard('account.fiscalyear.create_periods', [fy]).execute('create_periods')
        logging.info(msg['fisc_year'].format(year))
        return fy
    except Exception as e:
        logging.error(msg['error'].format(f"Al guardar {year}: {e}"))
        return None

def _ensure_account_config_sequence(move_seq, year):
    """Asegura que la secuencia de asientos esté configurada globalmente (Tryton 7.4+)"""
    try:
        AccountConfiguration = Model.get('account.configuration')
        acc_configs = AccountConfiguration.find([])
        if acc_configs:
            acc_config = acc_configs[0]
            # Intentar nombres estándar de configuración global (7.4+)
            fields_to_try = ['default_post_move_sequence', 'post_move_sequence']
            for field in fields_to_try:
                if hasattr(acc_config, field) and not getattr(acc_config, field):
                    setattr(acc_config, field, move_seq)
                    acc_config.save()
                    break
    except Exception as e:
        logging.error(msg['error'].format(f"Al configurar secuencia de asientos global para {year}: {e}"))

def setup_accounts(company, dependencies):
    AccountTemplate = Model.get('account.account.template')
    Account = Model.get('account.account')
    Module = Model.get('ir.module')
    Party = Model.get('party.party')

    # Diagnóstico: Listar solo las plantillas raíz disponibles para depuración
    try:
        all_templates = AccountTemplate.find([('parent', '=', None)])
        template_names = [t.name for t in all_templates]
        logging.info(msg['acc_templates_available'].format(template_names))
    except Exception as e:
        logging.debug("Error listing templates: %s", str(e))

    # Mapeo multiversión: busca nombres de módulos tradicionales o integrados en el core (V8)
    mapping = {
        'es': {'names': ['%Pymes%', '%Normal%', '%español%', '%Plan de cuentas universal%'], 'receivable': ['4300', 'Cuentas a cobrar'], 'payable': ['4000', 'Cuentas a pagar']},
        'fr': {'names': ['%Plan comptable général%', '%français%', '%Plan comptable universel%'], 'receivable': ['411', 'Comptes clients'], 'payable': ['401', 'Comptes fournisseurs']},
        'de': {'names': ['%SKR03%', '%Deutscher%', '%Universal-Kontenplan%'], 'receivable': ['10000', 'Forderungen'], 'payable': ['70000', 'Verbindlichkeiten']},
        'ar': {'names': ['%Plan Contable Argentino%'], 'receivable': ['11301', 'Deudores por ventas'], 'payable': ['21301', 'Proveedores']}
    }
    for code, mod_name in dependencies.items():
        # Verificar estado del módulo de localización
        mod_list = Module.find([('name', '=', mod_name)])
        if not mod_list or mod_list[0].state != 'activated':
            status = mod_list[0].state if mod_list else "no instalado"
            logging.warning(msg['acc_mod_status'].format(mod_name, status, code))
            continue

        conf = mapping[code]
        templates = []
        try:
            for t_name in conf['names']:
                # Intento 1: Plantilla raíz
                templates = AccountTemplate.find([('parent', '=', None), ('name', 'ilike', t_name)])
                # Intento 2: Búsqueda global (V8)
                if not templates:
                    templates = AccountTemplate.find([('name', 'ilike', t_name)])
                
                if templates:
                    logging.info(msg['acc_tpl_found'].format(templates[0].name, code))
                    break

            if not templates:
                logging.warning(msg['acc_template_not_found'].format(conf['names'][0], code))
                continue
            create_chart = Wizard('account.create_chart')
            create_chart.execute('account')
            create_chart.form.account_template = templates[0]
            create_chart.form.company = company
            try: create_chart.execute('create_account')
            except: pass
            
            # Búsqueda flexible de cuentas por código o nombre (para Plan Universal)
            major_ver = int(trytond.__version__.split('.')[0])
            attr_filter = ('kind', '!=', 'view') if major_ver >= 8 else ('type', '!=', None)
            
            rec = []
            for r_term in conf['receivable']:
                rec = Account.find([('company', '=', company.id), attr_filter, ('code', '=', r_term)]) or Account.find([('company', '=', company.id), attr_filter, ('name', 'ilike', f"%{r_term}%")])
                if rec: break
            pay = []
            for p_term in conf['payable']:
                pay = Account.find([('company', '=', company.id), attr_filter, ('code', '=', p_term)]) or Account.find([('company', '=', company.id), attr_filter, ('name', 'ilike', f"%{p_term}%")])
                if pay: break
                
            if rec and pay:
                for p in Party.find([]):
                    try:
                        p.account_receivable = rec[0]
                        p.account_payable = pay[0]
                        p.save()
                    except: pass
                logging.info(msg['acc_link'].format(code))
        except Exception as e:
            logging.error(msg['acc_error'].format(code,str(e)))

def _safe_set(record, field_name, value):
    try:
        setattr(record, field_name, value)
        return True
    except Exception:
        return False

def _safe_set_first(record, field_name, values):
    for value in values:
        if _safe_set(record, field_name, value):
            return value
    return None

def _safe_set_any_field(record, field_names, values):
    for field_name in field_names:
        applied = _safe_set_first(record, field_name, values)
        if applied is not None:
            return field_name, applied
    return None, None

# Función mejorada para verificar y activar módulos
def is_module_activated(module_name):
    Module = Model.get('ir.module')
    mod_list = Module.find([('name', '=', module_name)])
    if not mod_list:
        logging.debug(msg['mod_not_found'].format(module_name))
        return False
    
    module_record = mod_list[0]
    if module_record.state != 'activated':
        logging.info(msg['mod_act_try'].format(module_name, module_record.state))
        try:
            module_record.click('activate')
            Wizard('ir.module.activate_upgrade').execute('upgrade')
            module_record = Module.find([('name', '=', module_name)])[0] # Volver a obtener el estado
            if module_record.state == 'activated':
                logging.info(msg['mod_act_succ'].format(module_name))
                return True
            else:
                logging.warning(msg['mod_act_fail'].format(module_name, module_record.state))
                return False
        except Exception as e:
            logging.error(msg['mod_act_err'].format(module_name, str(e)))
            return False
    return True

def ensure_general_journal(company, company_conf):
    if not is_module_activated('account'):
        return
    Journal = Model.get('account.journal')
    journal_code = company_conf.get('journal_code') or 'GEN'
    journal_name = company_conf.get('journal_name') or 'Diario General'
    existing = Journal.find([('code', '=', journal_code)], limit=1)
    if existing:
        return
    journal = Journal()
    journal.name = journal_name
    journal.code = journal_code
    _safe_set(journal, 'type', 'general')
    _safe_set(journal, 'company', company)
    journal.save()
    logging.info(msg['journal_created'].format(journal_code))

def _pick_account_for_taxes(company):
    Account = Model.get('account.account')
    major_ver = int(trytond.__version__.split('.')[0])
    # Verificación estricta de campos: Tryton 7 usa 'type', Tryton 8+ usa 'kind'
    attr_filter = ('kind', '!=', 'view') if major_ver >= 8 else ('type', '!=', None)

    # 1. Prioridad: Códigos estándar del PGC que permitan asientos
    # Nota: Usamos 'code', '=', valor para ser más precisos en localizaciones reales
    for code in ['47700000', '47200000', '477', '472']:
        acc = Account.find([('company', '=', company.id), attr_filter, ('code', '=', code)], limit=1)
        if acc: 
            logging.info(msg['tax_detect_code'].format(code, acc[0].name))
            return acc[0]
    
    # 2. Búsqueda por nombre (PGC Pymes/Normal inyectado)
    for name in ['%Hacienda Pública, IVA repercutido%', '%Hacienda Pública, IVA soportado%']:
        acc = Account.find([('company', '=', company.id), attr_filter, ('name', 'ilike', name)], limit=1)
        if acc:
            logging.info(msg['tax_detect_name'].format(name, acc[0].name))
            return acc[0]
    
    # 3. Fallback para Plan Universal: Buscar por nombre "IVA" o "Tax" que acepte apuntes
    for term in ['%IVA%', '%Tax%', '%Impuesto%', '%Taxes%']:
        acc = Account.find([('company', '=', company.id), attr_filter, ('name', 'ilike', term)], limit=1)
        if acc: return acc[0]

    # 3. Último recurso: Cualquier cuenta de pasivo/gasto que no sea vista
    acc = Account.find([('company', '=', company.id), attr_filter], limit=1)
    return acc[0] if acc else None

def ensure_spanish_vat_taxes(company, company_conf):
    # Detectamos la versión para decidir qué módulo usar como ancla de localización
    major_ver = int(trytond.__version__.split('.')[0])
    # En V8+, account_es es opcional pero necesario para tener cuentas imputables.
    # Si no está inyectado, omitimos para evitar errores de dominio con el Plan Universal.
    proxy_es = 'account_es'
    logging.info(msg['tax_detect_ver'].format(major_ver, proxy_es))

    if not is_module_activated(proxy_es):
        logging.info(msg['vat_skipped_no_module'])
        return
    Tax = Model.get('account.tax')
    base_account = _pick_account_for_taxes(company)
    if not base_account:
        logging.warning(msg['vat_skipped_no_account'])
        return

    vat_rates = company_conf.get('vat_rates') or ['21', '10', '4']
    created = []
    already_present = []
    for amount in vat_rates:
        tax_name = f"IVA {amount}%"
        existing_tax = Tax.find([
            ('company', '=', company.id),
            ('name', '=', tax_name),
        ], limit=1)
        if existing_tax:
            already_present.append(amount)
            continue
        tax = Tax()
        tax.name = tax_name
        _safe_set(tax, 'description', tax_name)
        tax_type = _safe_set_first(tax, 'type', ['percentage', 'percent'])
        if not tax_type:
            logging.warning(msg['vat_skipped_bad_type'].format(tax_name))
            continue
        # En Tryton suele ser fracción (0.21), no 21. Probamos varios campos según versión.
        rate_fraction = Decimal(amount) / Decimal('100')
        rate_field, _ = _safe_set_any_field(
            tax,
            ['rate', 'percentage', 'percent'],
            [rate_fraction, float(rate_fraction), str(rate_fraction), amount]
        )
        if not rate_field:
            logging.warning(msg['vat_skipped_bad_rate'].format(tax_name))
            continue
        _safe_set(tax, 'company', company)
        _safe_set(tax, 'account', base_account)
        _safe_set(tax, 'refund_account', base_account)
        _safe_set(tax, 'invoice_account', base_account)
        _safe_set(tax, 'credit_note_account', base_account)
        tax.save()
        created.append(amount)
    if created:
        logging.info(msg['vat_created'].format(company.rec_name, "/".join(created)))
    if already_present:
        logging.info(msg['vat_already_present'].format("/".join(already_present)))

def ensure_argentina_pos(company):
    """Configura el Punto de Venta necesario para la localización Argentina."""
    if not is_module_activated('account_invoice_ar'):
        return
    Pos = Model.get('account.pos')
    existing = Pos.find([('number', '=', 2)], limit=1)
    if not existing:
        punto = Pos()
        punto.pos_type = 'manual'
        punto.number = 2
        punto.company = company
        punto.save()
        
        # Vincular a la configuración de ventas si existe
        if is_module_activated('sale_pos_ar'):
            SaleConfig = Model.get('sale.configuration')
            sc = SaleConfig.find([])
            if sc:
                sc[0].pos = punto
                sc[0].save()
        logging.info(msg['ar_pos_created'])

def ensure_ars_currency_rate():
    """Establece una tasa de cambio base para el Peso Argentino si no existe."""
    Currency = Model.get('currency.currency')
    ars = Currency.find([('code', '=', 'ARS')])
    if ars and not ars[0].rates:
        rate = ars[0].rates.new()
        rate.date = date.today()
        rate.rate = Decimal('1.0') # O el valor que prefieras por defecto
        ars[0].save()
        logging.info(msg['ar_rate_set'])

# -------------------------------------------------
# EJECUCIÓN PRINCIPAL DINÁMICA
# -------------------------------------------------
def run_setup():
    # Parámetros desde el .bat: DB_NAME CONF_PATH LANG ACTION
    DB_NAME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('DB_NAME', 'tryton')
    CONF_FILE = sys.argv[2] if len(sys.argv) > 2 else '/etc/trytond.conf'
    TARGET_LANG = (sys.argv[3] if len(sys.argv) > 3 else APP_LANG).lower()
    ACTION = (sys.argv[4] if len(sys.argv) > 4 else 'FULL')
    actions = parse_actions(ACTION)

    if not connect_and_init(DB_NAME, CONF_FILE): sys.exit(10)
    
    # Detectar la versión mayor de Tryton para ajustar proxies de localización
    tryton_version = trytond.__version__
    major_ver = int(tryton_version.split('.')[0])
    logging.info(msg['tryton_ver'].format(tryton_version))

    # Mapeo dinámico: Si la versión es nueva, usamos 'anclas'. Si es antigua, los módulos originales.
    chart_mapping = {
        'es': 'account_es', # Forzamos account_es para evitar planes "vacíos" en V8
        'fr': 'account_fr' if major_ver < 8 else 'party_siret',
        'de': 'account_de_skr03' if major_ver < 8 else 'account_statement_mt940',
        'ar': 'account_ar'
    }
    logging.info(msg['anchor_mods'].format(major_ver, chart_mapping))
    
    # 1. PRIMERO: Sincronizar módulos para que 'country' esté disponible en el Pool
    # Esto asegura que Model.get('country.zip') no falle
    try:
        sync_and_clean_modules()
    except Exception as e:
        logging.warning(msg['error'].format(str(e)))
        logging.shutdown()
        sys.exit(15)

    # ACCIÓN: GEODATA (Solo países y postales)
    if 'FULL' in actions or 'GEO' in actions:
        try:
            run_geodata_import(DB_NAME, CONF_FILE, TARGET_LANG)
        except RuntimeError as e:
            logging.error(msg['geo_error'].format(str(e)))
        except Exception as e:
            # Captura cualquier otro error inesperado (fallo de red, disco lleno, etc.)
            logging.error(msg['geo_error'].format(str(e)))
        
    # ACCIÓN: LANG (Traducciones e Idiomas)
    if 'FULL' in actions or 'LANG' in actions:
        try:
            activate_languages(chart_mapping, TARGET_LANG)
        except Exception as e:
             logging.error(msg['lang_error'].format(str(e)))

    # ACCIÓN: ACC (Solo contabilidad y empresa) o FULL
    if 'FULL' in actions or 'ACC' in actions:
        try:
            conf_data = get_company_config(CONF_FILE)
            
            # CRÍTICO: Sincronizar contexto de empresa ANTES del bucle de ejercicios
            company = setup_or_get_company(conf_data['name'], conf_data['currency'], DB_NAME, CONF_FILE, TARGET_LANG)
            config = p_config.get_config()
            config.context['company'] = company.id
            
            setup_accounts(company, chart_mapping)
            if TARGET_LANG == 'ar':
                ensure_ars_currency_rate()
                ensure_argentina_pos(company)
            ensure_general_journal(company, conf_data)

            # CRÍTICO: Refrescar Pool para reconocer campos de localizaciones
            p_config.get_config().pool.init()

            for year in range(2026, 2031):
                create_fiscalyear(year, company)
        except Exception as e:
            logging.exception(msg['error'].format(str(e)))

    # ACCIÓN: TAX (IVA España) o FULL
    if 'FULL' in actions or 'TAX' in actions:
        try:
            conf_data = get_company_config(CONF_FILE)
            company = setup_or_get_company(conf_data['name'], conf_data['currency'], DB_NAME, CONF_FILE, TARGET_LANG)
            config = p_config.get_config()
            config.context['company'] = company.id
            ensure_spanish_vat_taxes(company, conf_data)
        except Exception as e:
            logging.exception(msg['error'].format(str(e)))

    valid_actions = {'FULL', 'GEO', 'LANG', 'ACC', 'TAX'}
    invalid_actions = sorted([item for item in actions if item not in valid_actions])
    if invalid_actions:
        logging.error(msg['unsupported_action'].format(", ".join(invalid_actions)))
        logging.shutdown()
        sys.exit(11)
    logging.info(msg['success'])
    logging.info(msg['end_phase'].format(", ".join(sorted(actions))))
    logging.shutdown()
    sys.exit(0)
if __name__ == "__main__":
    run_setup()
