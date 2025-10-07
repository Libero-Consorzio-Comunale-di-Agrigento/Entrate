--liquibase formatted sql 
--changeset abrandolini:20250326_152401_soggetti_pratica stripComments:false runOnChange:true 
 
create or replace force view soggetti_pratica as
select com_ente.denominazione comune_ente
      , decode (pro_ente.sigla, null, '', ' (' || pro_ente.sigla || ')')
         sigla_ente
      , pro_ente.denominazione provincia_ente
      , translate (sogg.cognome_nome, '/', ' ') cognome_nome
      , sogg.ni
      , sogg.sesso cod_sesso
      , decode (sogg.sesso,  'M', 'Maschio',  'F', 'Femmina',  '') sesso
      , cont.cod_contribuente
      , cont.cod_controllo
      , cont.cod_fiscale
      , decode (sogg.ni_presso
              , null, f_recapito (sogg.ni
                                , prtr.tipo_tributo
                                , 1
                                , prtr.data
                                , 'PR')
              , 'Presso: ' || translate (sogg_p.cognome_nome, '/', ' '))
         presso
      , decode (
         sogg.ni_presso
       , null, nvl (
                f_recapito (sogg.ni
                          , prtr.tipo_tributo
                          , 1
                          , prtr.data)
              , decode (sogg.cod_via
                      , null, sogg.denominazione_via
                      , arvi.denom_uff) ||
                decode (sogg.num_civ
                      , null, ''
                      , ', ' || to_char (sogg.num_civ)) ||
                decode (SOGG.suffisso, null, '', '/' || sogg.suffisso) ||
                decode (sogg.scala, null, '', ' Sc.' || sogg.scala) ||
                decode (sogg.piano, null, '', ' P.' || sogg.piano) ||
                decode (sogg.interno, null, '', ' Int.' || sogg.interno))
       , decode (sogg_p.cod_via
               , null, sogg_p.denominazione_via
               , arvi_p.denom_uff) ||
         decode (sogg_p.num_civ, null, '', ', ' || to_char (sogg_p.num_civ)) ||
         decode (sogg_p.suffisso, null, '', '/' || sogg_p.suffisso) ||
         decode (sogg_p.scala, null, '', ' Sc.' || sogg_p.scala) ||
         decode (sogg_p.piano, null, '', ' P.' || sogg_p.piano) ||
         decode (sogg_p.interno, null, '', ' Int.' || sogg_p.interno))
         indirizzo
      , decode (
         sogg.ni_presso
       , null, nvl (
                f_recapito (sogg.ni
                          , prtr.tipo_tributo
                          , 1
                          , prtr.data
              , 'PND')
              , decode (sogg.cod_via
                , null, sogg.denominazione_via
                , arvi.denom_uff) ||
             decode (sogg.num_civ
                , null, ''
                , ' ' || to_char (sogg.num_civ)) ||
             decode (SOGG.suffisso, null, '', '/' || sogg.suffisso) ||
             decode (sogg.scala, null, '', ' Sc.' || sogg.scala) ||
             decode (sogg.piano, null, '', ' P.' || sogg.piano) ||
             decode (sogg.interno, null, '', ' Int.' || sogg.interno))
             , decode (sogg_p.cod_via
               , null, sogg_p.denominazione_via
               , arvi_p.denom_uff) ||
               decode (sogg_p.num_civ, null, '', ' ' || to_char (sogg_p.num_civ)) ||
               decode (sogg_p.suffisso, null, '', '/' || sogg_p.suffisso) ||
               decode (sogg_p.scala, null, '', ' Sc.' || sogg_p.scala) ||
               decode (sogg_p.piano, null, '', ' P.' || sogg_p.piano) ||
               decode (sogg_p.interno, null, '', ' Int.' || sogg_p.interno))
               indirizzo_pnd
               , decode (
               sogg.ni_presso
             , null, nvl (
             f_recapito (sogg.ni
              , prtr.tipo_tributo
              , 1
              , prtr.data
                          , 'CC')
              , decode (
                 nvl (sogg.zipcode, nvl (sogg.cap, comu.cap))
               , '99999', ''
               , nvl (sogg.zipcode, lpad (nvl (sogg.cap, comu.cap), 5, '0')) ||
                 ' ') ||
                comu.denominazione ||
                decode (
                 sign (200 - sogg.cod_pro_res)
               , 1, decode (prov.sigla, null, '', ' (' || prov.sigla || ')')
               , decode (stte.denominazione
                       , null, ''
                       , comu.denominazione, ''
                       , ' (' || stte.denominazione || ')')))
       , decode (
          nvl (sogg_p.zipcode, nvl (sogg_p.cap, comu_p.cap))
        , '9999', ''
        , nvl (sogg_p.zipcode, lpad (nvl (sogg_p.cap, comu_p.cap), 5, '0')) ||
          ' ') ||
         comu_p.denominazione ||
         decode (
          sign (200 - sogg_p.cod_pro_res)
        , 1, decode (prov_p.sigla, null, '', ' (' || prov_p.sigla || ')')
        , decode (stte_p.denominazione
                , null, ''
                , comu_p.denominazione, ''
                , ' (' || stte_p.denominazione || ')')))
         comune
      , decode (
         denunce_ici.num_telefonico
       , null, ''
       , denunce_ici.prefisso_telefonico ||
         ' / ' ||
         to_char (denunce_ici.num_telefonico))
         telefono
      , to_char (sogg.data_nas, 'dd/mm/yyyy') data_nascita
      , com_nas.denominazione ||
        decode (pro_nas.sigla, null, '', ' (' || pro_nas.sigla || ')')
         comune_nascita
      , decode (sogg.rappresentante, '', '', 'Rappresentante ') label_rap
      , sogg.rappresentante
      , sogg.cod_fiscale_rap
      , sogg.indirizzo_rap
      , lpad (com_rap.CAP, 5, '0') ||
        ' ' ||
        com_rap.denominazione ||
        decode (pro_rap.SIGLA, null, '', ' (' || pro_rap.sigla || ')')
         comune_rap
      , sogg.tipo_carica tipo_carica_rap
      , (select tica.descrizione
           from tipi_carica tica
          where tica.tipo_carica = sogg.tipo_carica)
         descr_carica
      , prtr.pratica
      , prtr.tipo_tributo
      , f_descrizione_titr (prtr.tipo_tributo, prtr.anno) descr_prtr
      , prtr.tipo_pratica
      , prtr.tipo_evento
      , prtr.anno
      , prtr.numero
      , ratr.tipo_rapporto
      , substr (to_char (prtr.data, 'dd/mm/yyyy'), 1, 10) data_pratica
      , substr (to_char (prtr.data_notifica, 'dd/mm/yyyy'), 1, 10)
         data_notifica
      , substr (to_char (sysdate, 'dd/mm/yyyy'), 1, 10) data_odierna
      , decode (sogg_erso.cognome_nome, '', '', 'Erede di ') erede_di
      , translate (sogg_erso.cognome_nome, '/', ' ') cognome_nome_erede
      , sogg_erso.cod_fiscale cod_fiscale_erede
      , nvl (f_recapito (sogg_erso.ni
                        , prtr.tipo_tributo
                        , 1
                        , trunc (sysdate)
                        , 'ID')
            ,decode (sogg_erso.cod_via
                    , null, sogg_erso.denominazione_via
                    , arvi_erso.denom_uff) ||
             decode (sogg_erso.num_civ, null, '', ', ' || sogg_erso.num_civ) ||
             decode (sogg_erso.suffisso, null, '', '/' || sogg_erso.suffisso))
         indirizzo_erede
      , nvl (f_recapito (sogg_erso.ni
                        , prtr.tipo_tributo
                        , 1
                        , trunc (sysdate)
                        , 'PND')
            ,decode (sogg_erso.cod_via
                    , null, sogg_erso.denominazione_via
                    , arvi_erso.denom_uff) ||
             decode (sogg_erso.num_civ, null, '', ' ' || sogg_erso.num_civ) ||
             decode (sogg_erso.suffisso, null, '', '/' || sogg_erso.suffisso))
         indirizzo_erede_pnd
      , nvl (
         f_recapito (sogg_erso.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'CC')
        ,lpad (com_erso.CAP, 5, '0') ||
         ' ' ||
         com_erso.denominazione ||
         decode (pro_erso.SIGLA, null, '', ' (' || pro_erso.sigla || ')'))
         comune_erede
      , prtr.note note_pratica
      , prtr.motivo motivo_pratica
      , '' dati_db1
      , '' dati_db2
      , prtr.utente utente_pratica
      , nvl (uten.nominativo, prtr.utente) des_utente_pratica
      , sogg.tipo_residente
      , sogg.tipo
      , decode (sogg_erso.ni_presso
               ,'',f_recapito (sogg_erso.ni
                              ,prtr.tipo_tributo
                              ,1
                              ,trunc (sysdate)
                              ,'PR')
               ,'Presso: ' ||
                     (select translate (soggetti.cognome_nome, '/', ' ')
                        from soggetti
                       where soggetti.ni = sogg_erso.ni_presso))
         presso_erede
      , nvl (
         f_recapito (sogg_erso.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'ID')
       , decode (sogg_erso.cod_via
               , null, sogg_erso.denominazione_via
               , arvi.denom_uff) ||
         decode (sogg_erso.num_civ
               , null, ''
               , ', ' || to_char (sogg_erso.num_civ)) ||
         decode (sogg_erso.suffisso, null, '', '/' || sogg_erso.suffisso))
         via_erede
      , trim (nvl (f_recapito_conv (sogg_erso.ni
                                  , prtr.tipo_tributo
                                  , 1
                                  , trunc (sysdate)
                                  , 'SC')
                 , sogg_erso.scala))
         scala_erede
      , trim (nvl (f_recapito_conv (sogg_erso.ni
                                  , prtr.tipo_tributo
                                  , 1
                                  , trunc (sysdate)
                                  , 'PI')
                 , sogg_erso.piano))
         piano_erede
      , decode (f_recapito_conv (sogg_erso.ni
                               , prtr.tipo_tributo
                               , 1
                               , trunc (sysdate)
                               , 'IN')
              , -1, to_number (null)
              , null, sogg_erso.interno
              , f_recapito_conv (sogg_erso.ni
                               , prtr.tipo_tributo
                               , 1
                               , trunc (sysdate)
                               , 'IN'))
         interno_erede
      , nvl (
         f_recapito (sogg_erso.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'DI')
       , decode (sogg_erso.scala, null, '', ' Scala ' || sogg_erso.scala) ||
         decode (sogg_erso.piano, null, '', ' Piano ' || sogg_erso.piano) ||
         decode (sogg_erso.interno, null, '', ' Int.' || sogg_erso.interno))
         dett_ind_erede
       , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'DV')
         via_dest
      , to_number (f_get_campo_csv (prtr.tipo_tributo
                                  , sogg.ni
                                  , sogg_erso.ni
                                  , sogg.tipo_residente || sogg.tipo
                                  , 'NC'))
         num_civ_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'SF')
         suffisso_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'SC')
         scala_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'PI')
         piano_dest
      , to_number (f_get_campo_csv (prtr.tipo_tributo
                                  , sogg.ni
                                  , sogg_erso.ni
                                  , sogg.tipo_residente || sogg.tipo
                                  , 'IN'))
         interno_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'CAP')
         cap_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'CO')
         comune_dest
      , f_get_campo_csv (prtr.tipo_tributo
                       , sogg.ni
                       , sogg_erso.ni
                       , sogg.tipo_residente || sogg.tipo
                       , 'SP')
         provincia_dest
      , sogg.stato
      --------------------- EREDE PRINCIPALE
      , translate (sogg_erso_princ.cognome_nome, '/', ' ') cognome_nome_erede_princ
      , sogg_erso_princ.cod_fiscale cod_fiscale_erede_princ
      , nvl (f_recapito (sogg_erso_princ.ni
                        , prtr.tipo_tributo
                        , 1
                        , trunc (sysdate)
                        , 'ID')
            ,decode (sogg_erso_princ.cod_via
                    , null, sogg_erso_princ.denominazione_via
                    , arvi_erso.denom_uff) ||
             decode (sogg_erso_princ.num_civ, null, '', ', ' || sogg_erso_princ.num_civ) ||
             decode (sogg_erso_princ.suffisso, null, '', '/' || sogg_erso_princ.suffisso))
         indirizzo_erede_princ
      , nvl (
         f_recapito (sogg_erso_princ.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'CC')
        ,lpad (com_erso_princ.CAP, 5, '0') ||
         ' ' ||
         com_erso_princ.denominazione ||
         decode (pro_erso_princ.SIGLA, null, '', ' (' || pro_erso_princ.sigla || ')'))
         comune_erede_princ
      , decode (sogg_erso_princ.ni_presso
               ,'',f_recapito (sogg_erso_princ.ni
                              ,prtr.tipo_tributo
                              ,1
                              ,trunc (sysdate)
                              ,'PR')
               ,'Presso: ' ||
                     (select translate (soggetti.cognome_nome, '/', ' ')
                        from soggetti
                       where soggetti.ni = sogg_erso_princ.ni_presso))
         presso_erede_princ
      , nvl (
         f_recapito (sogg_erso_princ.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'ID')
       , decode (sogg_erso_princ.cod_via
               , null, sogg_erso_princ.denominazione_via
               , arvi.denom_uff) ||
         decode (sogg_erso_princ.num_civ
               , null, ''
               , ', ' || to_char (sogg_erso_princ.num_civ)) ||
         decode (sogg_erso_princ.suffisso, null, '', '/' || sogg_erso_princ.suffisso))
         via_erede_princ
      , trim (nvl (f_recapito_conv (sogg_erso_princ.ni
                                  , prtr.tipo_tributo
                                  , 1
                                  , trunc (sysdate)
                                  , 'SC')
                 , sogg_erso_princ.scala))
         scala_erede_princ
      , trim (nvl (f_recapito_conv (sogg_erso_princ.ni
                                  , prtr.tipo_tributo
                                  , 1
                                  , trunc (sysdate)
                                  , 'PI')
                 , sogg_erso_princ.piano))
         piano_erede_princ
      , decode (f_recapito_conv (sogg_erso_princ.ni
                               , prtr.tipo_tributo
                               , 1
                               , trunc (sysdate)
                               , 'IN')
              , -1, to_number (null)
              , null, sogg_erso_princ.interno
              , f_recapito_conv (sogg_erso_princ.ni
                               , prtr.tipo_tributo
                               , 1
                               , trunc (sysdate)
                               , 'IN'))
         interno_erede_princ
      , nvl (
         f_recapito (sogg_erso_princ.ni
                   , prtr.tipo_tributo
                   , 1
                   , trunc (sysdate)
                   , 'DI')
       , decode (sogg_erso_princ.scala, null, '', ' Scala ' || sogg_erso_princ.scala) ||
         decode (sogg_erso_princ.piano, null, '', ' Piano ' || sogg_erso_princ.piano) ||
         decode (sogg_erso_princ.interno, null, '', ' Int.' || sogg_erso_princ.interno))
         dett_ind_erede_princ
   from soggetti sogg
      , soggetti sogg_p
      , archivio_vie arvi
      , archivio_vie arvi_p
      , ad4_utenti uten
      , ad4_provincie pro_ente
      , ad4_comuni com_ente
      , ad4_provincie prov
      , ad4_provincie prov_p
      , ad4_comuni comu
      , ad4_comuni comu_p
      , contribuenti cont
      , dati_generali dage
      , rapporti_tributo ratr
      , pratiche_tributo prtr
      , ad4_comuni com_rap
      , ad4_provincie pro_rap
      , ad4_comuni com_nas
      , ad4_provincie pro_nas
      , denunce_ici
      , ad4_stati_territori stte
      , ad4_stati_territori stte_p
      , soggetti sogg_erso
      , soggetti sogg_erso_princ
      , ad4_comuni com_erso
      , ad4_comuni com_erso_princ      
      , ad4_provincie pro_erso
      , ad4_provincie pro_erso_princ      
      , archivio_vie arvi_erso
      , archivio_vie arvi_erso_princ
  where (uten.utente(+) = prtr.utente)
    and (com_rap.provincia_stato = pro_rap.provincia(+))
    and (sogg.cod_pro_rap = com_rap.provincia_stato(+))
    and (sogg.cod_com_rap = com_rap.comune(+))
    and (sogg.cod_via = arvi.cod_via(+))
    and (sogg_p.cod_via = arvi_p.cod_via(+))
    and (sogg.ni = cont.ni)
    and (sogg_p.ni(+) = sogg.ni_presso)
    and (dage.pro_cliente = com_ente.provincia_stato(+))
    and (dage.com_cliente = com_ente.comune(+))
    and (com_ente.provincia_stato = pro_ente.provincia(+))
    and (sogg.cod_pro_res = stte.stato_territorio(+))
    and (sogg.cod_pro_res = comu.provincia_stato(+))
    and (sogg.cod_com_res = comu.comune(+))
    and (sogg_p.cod_pro_res = stte_p.stato_territorio(+))
    and (sogg_p.cod_pro_res = comu_p.provincia_stato(+))
    and (sogg_p.cod_com_res = comu_p.comune(+))
    and (sogg.cod_pro_nas = com_nas.provincia_stato(+))
    and (sogg.cod_com_nas = com_nas.comune(+))
    and (comu.provincia_stato = prov.provincia(+))
    and (comu_p.provincia_stato = prov_p.provincia(+))
    and (com_nas.provincia_stato = pro_nas.provincia(+))
    and cont.cod_fiscale = ratr.cod_fiscale
    and ratr.pratica = prtr.pratica
    and denunce_ici.pratica(+) = prtr.pratica
    and nvl(stampa_common.get_ni_erede_principale, f_primo_erede_ni (sogg.ni)) = sogg_erso.ni(+)
    and f_primo_erede_ni (sogg.ni) = sogg_erso_princ.ni(+)
    and com_erso.provincia_stato = pro_erso.provincia(+)
    and com_erso_princ.provincia_stato = pro_erso_princ.provincia(+)    
    and sogg_erso.cod_pro_res = com_erso.provincia_stato(+)
    and sogg_erso.cod_com_res = com_erso.comune(+)
    and sogg_erso.cod_via = arvi_erso.cod_via(+)
    and sogg_erso_princ.cod_pro_res = com_erso_princ.provincia_stato(+)
    and sogg_erso_princ.cod_com_res = com_erso_princ.comune(+)
    and sogg_erso_princ.cod_via = arvi_erso_princ.cod_via(+)
;
comment on table SOGGETTI_PRATICA is 'SOPR - Soggetti Pratica';

