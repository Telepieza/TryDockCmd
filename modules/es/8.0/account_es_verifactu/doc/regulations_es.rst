*******************
Normativa VeriFactu
*******************

Este es un pequeño resumen de las obligaciones tecnicas que tryton debe 
de cumplir para ser considerado Sistema informatico de facturacion (SIF)


* 2.a Registros de facturacion (RF) separados por empresa
* 2.d Visualizar en todo momento la empresa con la que se trabaja

* 4.b Gestionar certificados electrónicos para enviar los RF a la Agencia 
  Tributaria
* 4.c Enviar los RF a la Agencia Tributaria en el momento de la creacion.
* 4.d Procesar las respuestas de la Agencia Tributaria de los envios

* 6.a Generacion de huella por registro
* 7.e-g Fecha y hora exactas de generación del RF de acuerto al territorio
  desde donde se expide la factura,incluyendo el uso horario
* 15.3 Declaración responsable disponible de manera legible e individualizada
* 16.2 Sistema de control de flujo basado en el tiempo de espera entre envíos
  (por defecto 60 segundos) y número máximo de registros por envío (por defecto 1000).
* 16.4 En caso de no poder enviarse los registros de forma inmediata, se deberá
  reinentar el envío, respetando el orden temporal de generación, al menos una
  vez cada hora.
* 20.a Las representaciones graficas de la factura debe incluir codigo QR
* 20.b Debajo del codigo QR, la frase «Factura verificable en la sede
  electrónica de la AEAT» o «VERI*FACTU»


**********************
Normativa NO-VeriFactu
**********************
Estas obligaciones son adicionales para los SIF que no quieran enviar la 
informacion a la AEAT

* 2.a Registros de evento separados por empresa
* 4.b Gestionar certificados electrónicos que permitan la firma de los RF
* 4.c Enviar los RF en respuesta a un requerimiento.
* 6.b Comprobacion de la huella por registro
* 6.c Firmar electrónicamente todos los RF mediante «XAdES Enveloped Signature»
* 6.d Comprobacion firma de cualquier registro facturacion individual
* 6.e Comprobacion si es correcta toda o una determinada parte de la cadena 
  de registros de facturación.
* 6.f Generar un evento si sucede cualquier tipo de circunstancia que impida
  garantizar o que vulnere o pueda vulnerar la integridad e inalterabilidad de los registros.
* 7.i Al generar un nuevo RF comprobar que el último registro es correcto
  y que la fecha y hora de generación de éste no es superior a la del nuevo
* 9.2 Generar un registro resumen de eventos cada 6 horas y antes de apagarse.

***********************
Generación de la huella
***********************
El registro de facturas incluye una huella (hash) de los campos y valores
por linea ademas de ir encadenado con la huella del registro anterior.

* solo se permite generar hash de una cadena de texto con *sha-256*
* el formato de salida será en hexadecimal y en mayúsculas
* la cadena de texto para registros de alta se compone de 8 campos
    * IDEmisorFactura
    * NumSerieFactura
    * FechaExpedicionFactura
    * TipoFactura
    * CuotaTotal
    * ImporteTotal
    * Huella (del RegistroAnterior)
    * FechaHoraHusoGenRegistro
* la cadena de texto para registros de anulación se compone de 5 campos
    * IDEmisorFacturaAnulada
    * NumSerieFacturaAnulada
    * FechaExpedicionFacturaAnulada
    * Huella (del RegistroAnterior)
    * FechaHoraHusoGenRegistro
* El formato para componer la cadena de texto:
  NombreDeCampo=Valor&OtroNombreDeCampo=OtroValor& ..etc...

*********
Codigo QR
*********
Grafico obligatorio en las facturas impresas o representacion de estas (PDF).

Se compone de una URL con los siguientes parametros:

* Nif del cliente (nif)
* Numero de factura y serie (numserie)
* Fecha de expedicion de factura (fecha)
* Importe total (importe)

Tiene que ser el primer codigo QR de la factura antes del contenido
* solamente en la primera pagina
* tamaño 30x30mm o 40x40mm.
* Se adorna con el texto: "QR tributario:"

*********************************************
Estructura del registro - Sistema informatico
*********************************************
Los registros de facturación deben incluir un bloque "SistemaInformatico"
con los datos del sistema de facturación con la siguiente información:

* Nombre o razón social del productor del sistema informatico
* Identificador fiscal del productor del sistema informatico
* Nombre del sistema informatico
* ID del sistema informatico
* Versión del sistema informatico
* Numero de instalación del sistema informatico
* Si el sistema puede funcionar como No-VeriFactu
* Si el sistema permite llevar la facturación de varias empresas
* Si el sistema está soportando, actualmente, la facturación de varias empresas

***********
Referencias
***********

* `Reglamento VERI-Factu <https://www.boe.es/buscar/act.php?id=BOE-A-2024-22138>`_
* `Codigo QR <https://www.agenciatributaria.es/static_files/AEAT_Desarrolladores/EEDD/IVA/VERI-FACTU/DetalleEspecificacTecnCodigoQRfactura.pdf>`_
* `Generación de la huella <https://www.agenciatributaria.es/static_files/AEAT_Desarrolladores/EEDD/IVA/VERI-FACTU/Veri-Factu_especificaciones_huella_hash_registros.pdf>`_
* `Diseño de los registros de facturacion <https://www.agenciatributaria.es/static_files/AEAT_Desarrolladores/EEDD/IVA/VERI-FACTU/DsRegistroVeriFactu.xlsx>`_
* `Documentación general para desarrolladores <https://www.agenciatributaria.es/AEAT.desarrolladores/Desarrolladores/_menu_/Documentacion/Sistemas_Informaticos_de_Facturacion_y_Sistemas_VERI_FACTU/Sistemas_Informaticos_de_Facturacion_y_Sistemas_VERI_FACTU.html>`_
* `Consulta de registro VERI*FACTU <https://preportal.aeat.es/PRE-Exteriores/Inicio/_menu_/VERI_FACTU___Sistemas_Informaticos_de_Facturacion/VERI_FACTU___Sistemas_Informaticos_de_Facturacion.html>`_
* `Servicio para verificar NIF <https://sede.agenciatributaria.gob.es/static_files/Sede/Biblioteca/Manual/Tecnicos/WS/030_036_037/Manual_Tecnico_WS_Masivo_Calidad_Datos_Identificativos.pdf>`_