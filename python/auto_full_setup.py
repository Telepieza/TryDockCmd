import os
import logging
from datetime import date
import time
import sys
import configparser
import proteus
from proteus import config as proteus_config, Model, Wizard
from trytond.config import config as trytond_config
from trytond.pool import Pool

# -------------------------------------------------
# CONFIGURACIÓN DE LOGGING
# -------------------------------------------------
log_path = "/tmp/trytond_proteus.txt"
os.makedirs(os.path.dirname(log_path), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_path),
        logging.StreamHandler(sys.stdout)
    ]
)

RAW_LANG = os.environ.get('APP_LANGUAGE', 'es-ES').lower()
APP_LANG = RAW_LANG.split('-')[0] if '-' in RAW_LANG else RAW_LANG
MESSAGES = {
    'es': {
        'start': "--- CONEXIÓN EXITOSA ---",
        'wait': "Intento {}/10: Esperando a Postgres...",
        'scan': "--- ESCANEANDO MÓDULOS Y ASISTENTES ---",
        'comp_phase': "--- GESTIÓN DE EMPRESA ({}) ---",
        'comp_found': "Empresa detectada: {}",
        'comp_create': "Creando empresa '{}'...",
        'lang_phase': "--- CONFIGURACIÓN DE IDIOMAS Y TRADUCCIONES ---",
        'lang_act': "Activando idioma: {}",
        'fisc_year': "Ejercicio {} creado.",
        'acc_link': "Cuentas vinculadas para {}.",
        'success': "=== SETUP COMPLETADO EXITOSAMENTE ===",
		'conf_file': "Datos obtenidos del archivo: {}",
        'conf_warn': "Sin entorno ni .conf. Usando valores de emergencia.",
        'conf_active': "CONFIGURACIÓN ACTIVA -> Empresa: {} | Moneda: {}",
        'ctx_upd': "Contexto actualizado para {}. Moneda: {}",
        'admin_es': "Perfil Admin set en Español.",
        'error': "ERROR EN EL SETUP: {}",
        'read_error': "Error en lectura de configuración: {}",
        'acc_error': "Error en el plan contable {}: {}"
    },
    'en': {
        'start': "--- CONNECTION SUCCESSFUL ---",
        'wait': "Attempt {}/10: Waiting for Postgres...",
        'scan': "--- SCANNING MODULES AND WIZARDS ---",
        'comp_phase': "--- COMPANY MANAGEMENT ({}) ---",
        'comp_found': "Company detected: {}",
        'comp_create': "Creating company '{}'...",
        'lang_phase': "--- LANGUAGES AND TRANSLATIONS CONFIGURATION ---",
        'lang_act': "Activating language: {}",
        'fisc_year': "Fiscal year {} created.",
        'acc_link': "Accounts linked for {}.",
        'success': "=== SETUP COMPLETED SUCCESSFULLY ===",
		'conf_file': "Data obtained from file: {}",
        'conf_warn': "No environment or .conf found. Using emergency values.",
        'conf_active': "ACTIVE CONFIGURATION -> Company: {} | Currency: {}",
        'ctx_upd': "Context updated for {}. Currency: {}",
        'admin_es': "Admin profile set to Spanish.",
        'error': "SETUP ERROR: {}",
        'read_error': "Configuration reading error: {}",
        'acc_error': "Error in accounting plan {}: {}"
    },
    'fr': {
        'start': "--- CONNEXION RÉUSSIE ---",
        'wait': "Tentative {}/10: Attente de Postgres...",
        'scan': "--- ANALYSE DES MODULES ET ASSISTANTS ---",
        'comp_phase': "--- GESTION DE L'ENTREPRISE ({}) ---",
        'comp_found': "Entreprise détectée: {}",
        'comp_create': "Création de l'entreprise '{}'...",
        'lang_phase': "--- CONFIGURATION DES LANGUES ET TRADUCTIONS ---",
        'lang_act': "Activation de la langue: {}",
        'fisc_year': "Exercice comptable {} créé.",
        'acc_link': "Comptes liés pour {}.",
        'success': "=== CONFIGURATION TERMINÉE AVEC SUCCÈS ===",
		'conf_file': "Données obtenues du fichier: {}",
        'conf_warn': "Pas d'environnement ni de .conf. Utilisation de valeurs d'urgence.",
        'conf_active': "CONFIGURATION ACTIVE -> Entreprise: {} | Devise: {}",
        'ctx_upd': "Contexte mis à jour pour {}. Devise: {}",
        'admin_es': "Profil Admin configuré en Espagnol.",
        'error': "ERREUR DE CONFIGURATION: {}",
        'read_error': "Erreur de lecture de la configuration: {}",
        'acc_error': "Erreur dans le plan comptable {}: {}"
    },
    'de': {
        'start': "--- VERBINDUNG ERFOLGREICH ---",
        'wait': "Versuch {}/10: Warten auf Postgres...",
        'scan': "--- SCANNEN VON MODULEN UND ASSISTENTEN ---",
        'comp_phase': "--- UNTERNEHMENSVERWALTUNG ({}) ---",
        'comp_found': "Unternehmen erkannt: {}",
        'comp_create': "Unternehmen '{}' wird erstellt...",
        'lang_phase': "--- SPRACH- UND ÜBERSETZUNGSKONFIGURATION ---",
        'lang_act': "Sprache aktivieren: {}",
        'fisc_year': "Geschäftsjahr {} erstellt.",
        'acc_link': "Konten verknüpft für {}.",
        'success': "=== SETUP ERFOLGREICH ABGESCHLOSSEN ===",
		'conf_file': "Daten aus Datei erhalten: {}",
        'conf_warn': "Keine Umgebung oder .conf gefunden. Notfallwerte werden verwendet.",
        'conf_active': "AKTIVE KONFIGURATION -> Unternehmen: {} | Währung: {}",
        'ctx_upd': "Kontext aktualisiert für {}. Währung: {}",
        'admin_es': "Admin-Profil auf Spanisch gesetzt.",
        'error': "SETUP-FEHLER: {}",
        'read_error': "Fehler beim Lesen der Konfiguration: {}",
        'acc_error': "Fehler im Kontenplan {}: {}"
    }
}

current_lang = APP_LANG if APP_LANG else 'en'
msg = MESSAGES.get(APP_LANG, MESSAGES['en'])
logging.info(f"Log Language: {current_lang}")

# -------------------------------------------------
# FUNCIONES DE APOYO Y CONFIGURACIÓN DINÁMICA
# -------------------------------------------------

def get_company_config(conf_path='/config/trytond.conf'):
    logging.info(msg['conf_phase'])
    config = configparser.ConfigParser()
    env_name = os.environ.get('COMPANY_NAME')
    env_currency = os.environ.get('COMPANY_CURRENCY')
    data = {'name': env_name or '', 'currency': env_currency or ''}
    if not data['name'] or not data['currency']:
        try:
            if os.path.exists(conf_path):
                config.read(conf_path)
                if 'company' in config:
                    if not data['name']:
                        data['name'] = config['company'].get('name', 'Telepieza')
                    if not data['currency']:
                        data['currency'] = config['company'].get('currency', 'EUR')
                    logging.info(msg['conf_file'].format(conf_path))
            else:
                if not data['name']: data['name'] = 'Telepieza'
                if not data['currency']: data['currency'] = 'EUR'
                logging.warning(msg['conf_warn'])
        except Exception as e:
            logging.error(msg['read_error'].format(e))
    logging.info(msg['conf_active'].format(data['name'], data['currency']))       
    return data

def connect_and_init():
    config_file = '/config/trytond.conf'
    trytond_config.update_etc(config_file)
    db_name = os.environ.get('DB_NAME', 'tryton')
    for attempt in range(1, 11):
        try:
            proteus_config.set_trytond(db_name, config_file=config_file)
            pool = Pool(db_name)
            pool.init()
            logging.info(msg['start'])
            return True
        except Exception:
            logging.warning(msg['wait'].format(attempt))
            time.sleep(5)
    return False

def sync_and_clean_modules():
    logging.info(msg['scan'])
    Module = Model.get('ir.module')
    ConfigWizardItem = Model.get('ir.module.config_wizard.item')
    try:
        Wizard('ir.module.activate_upgrade').execute('upgrade')
    except:
        pass
    items = ConfigWizardItem.find([('state', '!=', 'done')])
    for item in items:
        item.state = 'done'
        item.save()
    return [m.name for m in Module.find([('state', '=', 'activated')])]

def setup_or_get_company(company_name, currency_code):
    logging.info(msg['comp_phase'].format(company_name))
    Company = Model.get('company.company')
    Party = Model.get('party.party')
    Currency = Model.get('currency.currency')
    User = Model.get('res.user')
    
    existing = Company.find([('party.name', '=', company_name)])
    
    if existing:
        company = existing[0]
        logging.info(msg['comp_found'].format(company.party.name))
    else:
        logging.info(msg['comp_create'].format(company_name))
        currency = Currency.find([('code', '=', currency_code)])[0]
        company_config = Wizard('company.company.config')
        company_config.execute('company')
        new_party = Party(name=company_name)
        new_party.save()
        company_config.form.party = new_party
        company_config.form.currency = currency
        company_config.execute('add')
        company = Company.find([('party.name', '=', company_name)])[0]

    import proteus
    cfg = proteus.config.get_config()
    old_user = cfg.user
    cfg.user = 0 
    new_context = User.get_preferences(True, {'company': company.id})
    cfg.context.update(new_context)
    cfg.user = old_user
    logging.info(msg['ctx_upd'].format(company_name, currency_code))
    return company

def activate_languages(dependencies):
    logging.info(msg['lang_phase'])
    Lang = Model.get('ir.lang')
    Module = Model.get('ir.module')
    for code, module_name in dependencies.items():
        if Module.find([('name', '=', module_name), ('state', '=', 'activated')]):
            lang_found = Lang.find([('code', '=', code)])
            if lang_found:
                lang = lang_found[0]
                if not lang.translatable:
                    logging.info(msg['lang_act'].format(code))
                    lang.translatable = True
                    lang.save()
                active_mods = Module.find([('state', '=', 'activated')])
                for mod in active_mods:
                    mod.click('upgrade')
                Wizard('ir.module.activate_upgrade').execute('upgrade')
    
    try:
        admin = Model.get('res.user')(1)
        admin.language = Lang.find([('code', '=', 'es')])[0]
        admin.save()
        logging.info(msg['admin_es'])
    except:
        pass

def get_sequence_type_id(module, name, fallback_id):
    ModelData = Model.get('ir.model.data')
    try:
        data = ModelData.find([('module', '=', module), ('name', '=', name)])
        if data: return data[0].db_id
    except: pass
    return fallback_id

def create_fiscalyear(year, company):
    FiscalYear = Model.get('account.fiscalyear')
    SequenceStrict = Model.get('ir.sequence.strict')
    SequenceType = Model.get('ir.sequence.type') 
    existing = FiscalYear.find([('name', '=', str(year)), ('company', '=', company.id)])
    if existing: return existing[0]
    fy = FiscalYear(name=str(year), company=company)
    fy.start_date = date(year, 1, 1)
    fy.end_date = date(year, 12, 31)
    st_move = SequenceType(get_sequence_type_id('account', 'sequence_type_account_move', 11))
    move_seq = SequenceStrict(name=f"Asientos {year}", sequence_type=st_move, company=company, padding=6)
    move_seq.save()
    fy.move_sequence = move_seq
    st_inv = SequenceType(get_sequence_type_id('account_invoice', 'sequence_type_account_invoice', 13))
    def _make_seq(n):
        s = SequenceStrict(name=f"{n} {year}", sequence_type=st_inv, company=company, padding=6)
        s.save()
        return s
    inv_seq_link = fy.invoice_sequences[0]
    inv_seq_link.company = company
    inv_seq_link.out_invoice_sequence = _make_seq("INV")
    inv_seq_link.out_credit_note_sequence = _make_seq("CRN")
    inv_seq_link.in_invoice_sequence = _make_seq("SUP_INV")
    inv_seq_link.in_credit_note_sequence = _make_seq("SUP_CRN")
    fy.save()
    wiz = Wizard('account.fiscalyear.create_periods')
    wiz.execute('start')
    wiz.form.fiscalyear = fy
    wiz.execute('create_periods')
    logging.info(msg['fisc_year'].format(year))
    return fy

def setup_accounts(company, dependencies):
    AccountTemplate = Model.get('account.account.template')
    Account = Model.get('account.account')
    Module = Model.get('ir.module')
    Party = Model.get('party.party')
    
    mapping = {
        'es': {'name': '%Pymes%', 'receivable': '4300', 'payable': '4000'},
        'fr': {'name': '%Plan comptable général%', 'receivable': '411', 'payable': '401'},
        'de': {'name': '%SKR03%', 'receivable': '10000', 'payable': '70000'}
    }

    for code, mod_name in dependencies.items():
        if not Module.find([('name', '=', mod_name), ('state', '=', 'activated')]):
            continue
        
        conf = mapping[code]
        try:
            templates = AccountTemplate.find([('parent', '=', None), ('name', 'ilike', conf['name'])])
            if not templates: continue

            create_chart = Wizard('account.create_chart')
            create_chart.execute('account')
            create_chart.form.account_template = templates[0]
            create_chart.form.company = company
            try: create_chart.execute('create_account')
            except: pass

            rec = Account.find([('code', '=', conf['receivable']), ('company', '=', company.id)])
            pay = Account.find([('code', '=', conf['payable']), ('company', '=', company.id)])

            if rec and pay:
                parties = Party.find([])
                for p in parties:
                    try:
                        p.account_receivable = rec[0]
                        p.account_payable = pay[0]
                        p.save()
                    except: pass
                logging.info(msg['acc_link'].format(code))
        except Exception as e:
            logging.error(msg['acc_error'].format(code, e))

# -------------------------------------------------
# EJECUCIÓN PRINCIPAL
# -------------------------------------------------

def run_setup():
    if not connect_and_init(): sys.exit(1)

    conf_data = get_company_config()
    sync_and_clean_modules()
    company = setup_or_get_company(conf_data['name'], conf_data['currency'])
    try:
        activate_languages({'es': 'account_es', 'fr': 'account_fr', 'de': 'account_de_skr03'})
        setup_accounts(company, {'fr': 'account_fr', 'de': 'account_de_skr03', 'es': 'account_es'})
        for year in [2026, 2027, 2028]:
            create_fiscalyear(year, company)
        logging.info(msg['success'])
    except Exception as e:
        logging.exception(msg['error'].format(e))
        sys.exit(1)

if __name__ == "__main__":
    run_setup()