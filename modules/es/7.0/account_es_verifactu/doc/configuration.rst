*************
Configuration
*************

In order to authenticate with the web service one must set the SSL certificate
in the company. For each company the following fields must be filled:

``es_verifactu_certificate``
  Should the binary content of the SSL certificate.

``es_verifactu_private_key``
  Should the binary content of the SSL private key.

.. warning::
    The private key must be unencrypted.

How to obtain the certificate and private keys?
-----------------------------------------------

Both values should be extracted from the p12 certificate issued by the
`FNMT <https://www.sede.fnmt.gob.es/certificados/certificado-de-representante>`_.
The certificate should be related to the company presenting the information
or an authorized party.

Given a ``cert.p12`` certificate its keys can be extracted with following
commands:

.. code-block:: console

    $ openssl pkcs12 -in cert.p12 -clcerts -nokeys -out public.crt
    $ openssl pkcs12 -in cert.p12 -nocerts -out private.key
    $ openssl rsa -in private.key -out private_unencripted.key

The path to ``private_unencripted.key`` should be used as ``privatekey`` and
the one to ``public.crt`` as ``certificate``.

.. to remove, see https://www.tryton.org/develop/guidelines/documentation#configuration.rst
