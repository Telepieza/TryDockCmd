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
log_path = "/python/auto_full_setup.log"
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
# FUNCIONES DE APOYO Y CONFIGURACIÓN DINÁMICA
# -------------------------------------------------

def get_company_config(conf_path='/config/trytond.conf'):
    """Lee el nombre y moneda desde el archivo de configuración."""
    config = configparser.ConfigParser()
    data = {'name': 'Telepieza', 'currency': 'EUR'}
    try:
        if os.path.exists(conf_path):
            config.read(conf_path)
            if 'empresa' in config:
                data['name'] = config['empresa'].get('name', data['name'])
                data['currency'] = config['empresa'].get('currency', data['currency'])
                logging.info(f"Configuración cargada de {conf_path}: {data['name']} ({data['currency']})")
        else:
            logging.warning(f"Archivo {conf_path} no encontrado. Usando fallbacks.")
    except Exception as e:
        logging.error(f"Error leyendo configuración: {e}")
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
            logging.info("--- CONEXIÓN EXITOSA ---")
            return True
        except Exception:
            logging.warning(f"Intento {attempt}/10: Esperando a Postgres...")
            time.sleep(5)
    return False

def sync_and_clean_modules():
    Module = Model.get('ir.module')
    ConfigWizardItem = Model.get('ir.module.config_wizard.item')
    logging.info("--- ESCANEANDO MÓDULOS Y ASISTENTES ---")
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
    Company = Model.get('company.company')
    Party = Model.get('party.party')
    Currency = Model.get('currency.currency')
    User = Model.get('res.user')
    
    logging.info(f"--- FASE: GESTIÓN DE EMPRESA ({company_name}) ---")
    existing = Company.find([('party.name', '=', company_name)])
    
    if existing:
        company = existing[0]
        logging.info(f"Empresa detectada: {company.party.name}")
    else:
        logging.info(f"Creando empresa '{company_name}'...")
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
    logging.info(f"Contexto actualizado para {company_name}. Moneda: {currency_code}")
    return company

def activate_languages(dependencies):
    Lang = Model.get('ir.lang')
    Module = Model.get('ir.module')
    logging.info("--- CONFIGURACIÓN DE IDIOMAS Y TRADUCCIONES ---")
    for code, module_name in dependencies.items():
        if Module.find([('name', '=', module_name), ('state', '=', 'activated')]):
            lang_found = Lang.find([('code', '=', code)])
            if lang_found:
                lang = lang_found[0]
                if not lang.translatable:
                    logging.info(f"Activando idioma: {code}")
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
        logging.info("Perfil Admin set en Español.")
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
    logging.info(f"Ejercicio {year} creado. ✅")
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
                logging.info(f"Cuentas vinculadas para {code}. ✅")
        except Exception as e:
            logging.error(f"Error plan {code}: {e}")

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
        logging.info("=== SETUP COMPLETADO EXITOSAMENTE ===")
    except Exception:
        logging.exception("ERROR EN EL SETUP")
        sys.exit(1)

if __name__ == "__main__":
    run_setup()