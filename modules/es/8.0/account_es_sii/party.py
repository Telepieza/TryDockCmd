# This file is part of Tryton. The COPYRIGHT file at the top level of
# this repository contains the full copyright notices and license terms.
from trytond.pool import PoolMeta


class Identifier(metaclass=PoolMeta):
    __name__ = 'party.identifier'

    def es_sii_values(self):
        if not self.type:
            return {}
        country = self.es_country()
        code = self.es_code()
        if country == 'ES':
            return {
                'NIF': code
                }
        if country is None:
            try:
                country, _ = self.type.split('_', 1)
                country = country.upper()
            except ValueError:
                country = ''
        id_type = self.es_vat_type()
        # In case of OSS we must send the real country
        real_country = country
        if country == 'EU':
            id_type = '04'
            for address in self.party.addresses:
                if address.country and address.country.code != 'ES':
                    real_country = address.country.code
                    break
        # Greece uses ISO-639-1 as prefix (EL)
        real_country = real_country.replace('EL', 'GR')
        country = country.replace('EL', 'GR')
        return {
            'IDOtro': {
                'ID': country + code,
                'IDType': id_type,
                'CodigoPais': real_country,
                }
            }
