# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from contextlib import contextmanager
from io import BytesIO
from tempfile import NamedTemporaryFile

from cryptography.exceptions import UnsupportedAlgorithm
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import pkcs12

from trytond.exceptions import UserError
from trytond.i18n import gettext
from trytond.model import ModelView, fields
from trytond.pool import PoolMeta
from trytond.pyson import Bool, Eval, Id
from trytond.wizard import Button, StateTransition, StateView, Wizard


class Company(metaclass=PoolMeta):
    __name__ = 'company.company'

    es_verifactu_private_key = fields.Binary("Verifactu Private Key")
    es_verifactu_certificate = fields.Binary("Verifactu Certificate")

    @classmethod
    def __setup__(cls):
        super().__setup__()
        cls._buttons.update({
                'load_credential_verifactu': {
                    'readonly': (Bool(Eval('es_verifactu_private_key'))
                            | Bool(Eval('es_verifactu_certificate'))),
                    'invisible': ~Id('account', 'group_account_admin'
                        ).in_(Eval('context', {}).get('groups', [])),
                    'depends': [
                        'es_verifactu_private_key',
                        'es_verifactu_certificate'
                        ],
                    }
                })

    @classmethod
    @ModelView.button_action(
        'account_es_verifactu.act_load_credential_verifactu')
    def load_credential_verifactu(cls, records):
        pass

    @contextmanager
    def es_verifactu_tmp_credentials(self):
        if (not self.es_verifactu_private_key
                or not self.es_verifactu_certificate):
            raise UserError(
                gettext('account_es_verifactu.msg_es_verifactu_no_key_cert',
                    company=self.rec_name))
        # XXX: Join both with once 3.8 is no longer supported
        with NamedTemporaryFile(delete=True) as cert:
            with NamedTemporaryFile(delete=True) as pkey:
                cert.write(self.es_verifactu_certificate)
                cert.flush()
                pkey.write(self.es_verifactu_private_key)
                pkey.flush()
                yield (cert.name, pkey.name)


class LoadCredentialVerifactuStart(ModelView):
    "Company Load Credential Verifactu Start"
    __name__ = 'company.load_credential.verifactu.start'

    file = fields.Binary("File", required=True)
    password = fields.Char("Password", required=True)


class LoadCredentialVerifactu(Wizard):
    "Company Load Credential Verifactu"
    __name__ = 'company.load_credential.verifactu'

    start = StateView('company.load_credential.verifactu.start',
        'account_es_verifactu.load_credential_verifactu_start_view', [
            Button("Cancel", 'end'),
            Button("Load", 'load', default=True),
            ])
    load = StateTransition()

    def transition_load(self):
        with BytesIO(self.start.file) as file:
            try:
                # _ = additional_certificates
                private_key, certificate, _ = pkcs12.load_key_and_certificates(
                    file.read(), self.start.password.encode())
                pkey = private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption(),
                    )
                cert = certificate.public_bytes(serialization.Encoding.PEM)
                self.model.write([self.record], {
                        'es_verifactu_certificate': cert,
                        'es_verifactu_private_key': pkey,
                        })
            except (ValueError, TypeError, UnsupportedAlgorithm) as e:
                errors = e.args[0]
                if isinstance(errors, list):
                    message = ', '.join(error[2] for error in errors)
                elif isinstance(errors, str):
                    message = errors
                else:
                    message = ''
                raise UserError(gettext(
                        'account_es_verifactu.msg_error_loading_credentials',
                        message=message))
        return 'end'
