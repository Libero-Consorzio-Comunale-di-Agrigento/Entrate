--liquibase formatted sql 
--changeset abrandolini:20250326_152401_immobili_catasto_urbano_cu stripComments:false runOnChange:true 
 
create or replace force view immobili_catasto_urbano_cu as
select distinct
  to_number (uiu.partita) contatore
   , to_number (uiu.partita) proprietario
   , rtrim ( decode (rtrim (ltrim (top.toponimo))
  , '', ''
   , rtrim (ltrim (top.toponimo)) || ' ') ||
 rtrim (ltrim (ind.indirizzo))) indirizzo
   , rtrim (ltrim (ltrim (ind.civico1, '0'))) ||
  decode (rtrim (ltrim (ltrim (ind.civico2, '0')))
  , '', ''
  , '-' || rtrim (ltrim (ltrim (ind.civico2, '0')))) ||
  decode (rtrim (ltrim (ltrim (ind.civico3, '0')))
  , '', ''
  , '-' || rtrim (ltrim (ltrim (ind.civico3, '0'))))
   num_civ
   , rtrim (ltrim (ltrim (ind.lotto, '0'))) lotto
   , rtrim (ltrim (ltrim (ind.edificio, '0'))) edificio
   , rtrim (ltrim (ltrim (ind.scala, '0'))) scala
   , rtrim (ltrim (ltrim (ind.interno, '0'))) interno
   , rtrim (ltrim (ltrim (ind.piano1, '0'))) ||
  decode ( rtrim (ltrim (ltrim (ind.piano2, '0')))
   , '', ''
    , '-' || rtrim (ltrim (ltrim (ind.piano2, '0')))) ||
  decode (rtrim (ltrim (ltrim (ind.piano3, '0')))
   , '', ''
    , '-' || rtrim (ltrim (ltrim (ind.piano3, '0'))))
   piano
   , rtrim (ltrim (ltrim (cuf.numeratore, '0'))) numeratore
   , rtrim (ltrim (ltrim (cuf.denominatore, '0'))) denominatore
   , rtrim (ltrim (cuf.cod_titolo)) cod_titolo
   , rtrim (ltrim (cuf.des_titolo)) des_titolo
   , 'F' tipo_immobile
   , to_char (cuf.partita) partita_titolarita
   , uiu.partita partita
   , rtrim (ltrim (ltrim (uiu.sezione, '0'))) sezione
   , substr (rtrim (ltrim (ltrim (uiu.foglio, '0'))), 1, 5) foglio
   , substr (rtrim (ltrim (ltrim (uiu.numero, '0'))), 1, 5) numero
   , rtrim (ltrim (ltrim (uiu.subalterno, '0'))) subalterno
   , rtrim (ltrim (ltrim (uiu.zona, '0'))) zona
   , rtrim (ltrim (ltrim (uiu.categoria1 || lpad (uiu.categoria2, 2, '0'), '0')))
   categoria
   , rtrim (ltrim (ltrim (uiu.classe, '0'))) classe
   , rtrim (ltrim (ltrim (to_number (uiu.consistenza), '0'))) consistenza
   , '' superficie
   , rtrim (ltrim (ltrim (to_number (uiu.rendita), '0'))) rendita
   , rtrim (ltrim (ltrim (to_number (uiu.rendita), '0'))) rendita_euro
   , rtrim (ltrim (uiu.descrizione)) descrizione
   , decode ( uiu.data_efficacia
   , '', to_date ('')
   , to_date (substr (uiu.data_efficacia, 5, 2) || '/' || substr (uiu.data_efficacia, 3, 2) || '/' || '19' || substr (uiu.data_efficacia, 1, 2), 'dd/mm/yyyy'))
   data_efficacia
   , to_date ('') data_fine_efficacia
   , decode ( uiu.data_iscrizione
   , '', to_date ('')
   , to_date (substr (uiu.data_iscrizione, 5, 2) || '/' || substr (uiu.data_iscrizione, 3, 2) || '/' || '19' || substr (uiu.data_iscrizione, 1, 2), 'dd/mm/yyyy'))
   data_iscrizione
   , to_date ('') data_fine_iscrizione
   , lpad (nvl (ltrim (ltrim (uiu.sezione, '0')), ' '), 3, ' ') ||
  lpad (nvl (ltrim (ltrim (uiu.foglio, '0')), ' '), 5, ' ') ||
  lpad (substr (nvl (ltrim (ltrim (uiu.numero, '0')), ' '), 1, 5), 5, ' ') ||
  lpad (nvl (ltrim (ltrim (uiu.subalterno, '0')), ' '), 4, ' ') ||
  lpad (nvl (ltrim (ltrim (uiu.zona, '0')), ' '), 3, ' ')
   estremi_catasto
   , '' note
   , uiu.sezione_ric
   , uiu.foglio_ric
   , uiu.numero_ric
   , uiu.subalterno_ric
   , rtrim ( decode (rtrim (ltrim (top.toponimo))
  , '', ''
  , rtrim (ltrim (top.toponimo)) || ' ') ||
  rtrim (ltrim (ind.indirizzo)))
   indirizzo_ric
   , uiu.zona_ric
   , uiu.categoria_ric
   , uiu.partita partita_ric
   from CUCODTOP top
   , CUINDIRI ind
   , CUFISICA cuf
   , CUARCUIU uiu
  where top.codice(+) = ind.toponimo
 and ind.chiave(+) = uiu.contatore
 and cuf.partita = to_number (uiu.partita)
 union all
 select distinct
  to_number (uiu.partita) contatore
   , to_number (uiu.partita) proprietario
   , rtrim ( decode (rtrim (ltrim (top.toponimo))
  , '', ''
  , rtrim (ltrim (top.toponimo)) || ' ') ||
  rtrim (ltrim (ind.indirizzo)))
   indirizzo
   , rtrim (ltrim (ltrim (ind.civico1, '0'))) ||
  decode (rtrim (ltrim (ltrim (ind.civico2, '0')))
   , '', ''
   , '-' || rtrim (ltrim (ltrim (ind.civico2, '0')))) ||
  decode (rtrim (ltrim (ltrim (ind.civico3, '0')))
   , '', ''
   , '-' || rtrim (ltrim (ltrim (ind.civico3, '0'))))
   num_civ
   , rtrim (ltrim (ltrim (ind.lotto, '0'))) lotto
   , rtrim (ltrim (ltrim (ind.edificio, '0'))) edificio
   , rtrim (ltrim (ltrim (ind.scala, '0'))) scala
   , rtrim (ltrim (ltrim (ind.interno, '0'))) interno
   , rtrim (ltrim (ltrim (ind.piano1, '0'))) ||
  decode (rtrim (ltrim (ltrim (ind.piano2, '0')))
   , '', ''
   , '-' || rtrim (ltrim (ltrim (ind.piano2, '0')))) ||
  decode (rtrim (ltrim (ltrim (ind.piano3, '0')))
   , '', ''
   , '-' || rtrim (ltrim (ltrim (ind.piano3, '0'))))
   piano
   , rtrim (ltrim (ltrim (cun.numeratore, '0'))) numeratore
   , rtrim (ltrim (ltrim (cun.denominatore, '0'))) denominatore
   , rtrim (ltrim (cun.cod_titolo)) cod_titolo
   , rtrim (ltrim (cun.des_titolo)) des_titolo
   , 'F' tipo_immobile
   , to_char (cun.partita) partita_titolarita
   , uiu.partita partita
   , rtrim (ltrim (ltrim (uiu.sezione, '0'))) sezione
   , substr (rtrim (ltrim (ltrim (uiu.foglio, '0'))), 1, 5) foglio
   , substr (rtrim (ltrim (ltrim (uiu.numero, '0'))), 1, 5) numero
   , rtrim (ltrim (ltrim (uiu.subalterno, '0'))) subalterno
   , rtrim (ltrim (ltrim (uiu.zona, '0'))) zona
   , rtrim ( ltrim (ltrim (uiu.categoria1 || lpad (uiu.categoria2, 2, '0'), '0')))
   categoria
   , rtrim (ltrim (ltrim (uiu.classe, '0'))) classe
   , rtrim (ltrim (ltrim (to_number (uiu.consistenza), '0'))) consistenza
   , '' superficie
   , rtrim (ltrim (ltrim (to_number (uiu.rendita), '0'))) rendita
   , rtrim (ltrim (ltrim (to_number (uiu.rendita), '0'))) rendita_euro
   , rtrim (ltrim (uiu.descrizione)) descrizione
   , decode ( uiu.data_efficacia
   , '', to_date ('')
   , to_date (substr (uiu.data_efficacia, 5, 2) || '/' || substr (uiu.data_efficacia, 3, 2) || '/' || '19' || substr (uiu.data_efficacia, 1, 2), 'dd/mm/yyyy'))
   data_efficacia
   , to_date ('') data_fine_efficacia
   , decode ( uiu.data_iscrizione
   , '', to_date ('')
   , to_date (substr (uiu.data_iscrizione, 5, 2) || '/' || substr (uiu.data_iscrizione, 3, 2) || '/' || '19' || substr (uiu.data_iscrizione, 1, 2), 'dd/mm/yyyy'))
   data_iscrizione
   , to_date ('') data_fine_efficacia
   , lpad (nvl (ltrim (ltrim (uiu.sezione, '0')), ' '), 3, ' ') ||
  substr (lpad (nvl (ltrim (ltrim (uiu.foglio, '0')), ' '), 5, ' '), 1, 5) ||
  substr (lpad (nvl (ltrim (ltrim (uiu.numero, '0')), ' '), 5, ' '), 1, 5) ||
  lpad (nvl (ltrim (ltrim (uiu.subalterno, '0')), ' '), 4, ' ') ||
  lpad (nvl (ltrim (ltrim (uiu.zona, '0')), ' '), 3, ' ')
   estremi_catasto
   , ''
   , uiu.sezione_ric
   , uiu.foglio_ric
   , uiu.numero_ric
   , uiu.subalterno_ric
   , rtrim (decode (rtrim (ltrim (top.toponimo))
    , '', ''
    , rtrim (ltrim (top.toponimo)) || ' ') ||
  rtrim (ltrim (ind.indirizzo)))
   indirizzo_ric
   , uiu.zona_ric
   , uiu.categoria_ric
   , uiu.partita partita_ric
   from CUCODTOP top
   , CUINDIRI ind
   , CUNONFIS cun
   , CUARCUIU uiu
  where top.codice(+) = ind.toponimo
 and ind.chiave(+) = uiu.contatore
 and cun.partita = to_number (uiu.partita);
comment on table IMMOBILI_CATASTO_URBANO_CU is 'Immobili Catasto Urbano CU';

