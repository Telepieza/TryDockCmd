# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from trytond.model import fields
from trytond.pool import PoolMeta


class Party(metaclass=PoolMeta):
    __name__ = 'party.party'

    facturae = fields.Selection([
            (None, ''),
            ('manual', 'Manual'),
            # ('face', "Face WebService"),
            ], "Facturae")
