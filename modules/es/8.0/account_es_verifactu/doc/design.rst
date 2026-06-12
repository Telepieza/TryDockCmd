******
Design
******

The *Account ES Verifactu Module* introduces the following concepts:

.. _model-account.invoice.verifactu:

Verifactu Invoice
=================

The main concept introduced by the *Account ES Verifactu Module* is the *Verifactu Invoice*.
It relates a `Invoice <account_invoice:model-account.invoice>` with it
state in the :abbr:`Verifactu`.
A record is automatically created when an invoices that should be sent to Verifactu
is posted.

When the invoice is correctly set it stores the secure validation code of
the delivery.
If there are any error with the invoice, the error code and description are
stored.

.. seealso::

   The SSI Invoices can be found by opening the main menu item:

      |Financial --> Invoices --> Verifactu Invoices|__

      .. |Financial --> Invoices --> Verifactu Invoices| replace:: :menuselection:`Financial --> Invoices --> Verifactu Invoices`
      __ https://demo.tryton.org/model/account.invoice.verifactu
