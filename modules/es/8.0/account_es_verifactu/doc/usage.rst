*****
Usage
*****

Sending Invoices to Verifactu
=============================

In order to let Tryton know that the invoices should be sent to Verifactu you
should activate the ``Send invoices to Verifactu`` flag on the `Fiscalyear
<account:model-account.fiscalyear>` form.
When this flag is activated Tryton creates a `Verifactu Record
<model-account.invoice.verifactu>` for each invoice.
This record are sent automatically to the tax authority by a
*Scheduled Task*.

Tryton retries until the invoice is accepted by the tax authority.
