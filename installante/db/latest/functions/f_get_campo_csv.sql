--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_campo_csv stripComments:false runOnChange:true 
 
create or replace function F_GET_CAMPO_CSV
/*************************************************************************
 NOME:        F_GET_CAMPO_CSV
 DESCRIZIONE: Dati tipo tributo, ni soggetto, ni erede e tipo soggetto,
              restituisce il dato dell'indirizzo richiesto nel parametro
              a_campo necessario per la composizione dell'indirizzo del
              destinatario.
              Quindi:
              - se il soggetto è persona fisica, si verifica l'esistenza
              di un eventuale erede; se esiste, si restituiscono i dati
              dell'indirizzo dell'erede, altrimenti si restituiscono i
              dati dell'indirizzo del contribuente.
              - se il soggetto è persona giuridica, si verifica l'esistenza
              di un eventuale rappresentante legale; se esiste si restituiscono
              i dati dell'indirizzo del rappresentante legale, altrimenti
              si restituiscono i dati dell'indirizzo del contribuente.
              In casi di contribuene o di erede, si tiene conto anche di
              un eventuale recapito; per il rappresentante legale non e'
              prevista la gestione dei recapiti.
 PARAMETRI:
 a_tipo_tributo                   Per ricerca eventuale recapito
 a_ni                             Ni del soggetto di cui si deve comporre
                                  l'indirizzo di destinazione
 a_ni_erede                       Ni dell'eventuale erede del contribuente
 a_tipo_soggetto                  Tipo soggetto del contribuente
                                  11 - persona giuridica
                                  altri valori - persona fisica
 a_campo                          Identificativo del campo richiesto.
                                  Può assumere i seguenti valori:
                                  DV - Denominazione via
                                  NC - Numero civico
                                  SF - Suffisso
                                  SC - Scala
                                  PI - Piano
                                  IN - Interno
                                  CAP - Cap
                                  CO - Denominazione comune
                                  SP - Sigla provincia
                                  SE - Sigla stato estero
 RITORNA:     varchar2            Valore del dato dell'indirizzo richiesto
 NOTE:
 Rev.    Date         Author      Note
 000     08/07/2020   VD          Prima emissione.
 001     28/01/2022   VD          Modificata gestione rappresentante legale:
                                  ora si restituiscono sempre i dati
                                  dell'indirizzo del contribuente.
 002     20/12/2022   AB          Gestione del comune e della provncia estera
*************************************************************************/
( a_tipo_tributo           varchar2
, a_ni                     number
, a_ni_erede               number
, a_tipo_soggetto          number
, a_campo                  varchar2
) return varchar2 is
w_denominazione_via        varchar2(100);
w_num_civ                  soggetti.num_civ%type;
w_suffisso                 recapiti_soggetto.suffisso%type;
w_scala                    soggetti.scala%type;
w_piano                    soggetti.piano%type;
w_interno                  soggetti.interno%type;
w_cap                      varchar2(10);
w_comune                   varchar2(100);
w_provincia                varchar2(100);
w_stato                    varchar2(100);
w_rappresentante           soggetti.rappresentante%type;
w_rap_indirizzo            soggetti.indirizzo_rap%type;
w_rap_comune               varchar2(100);
w_rap_provincia            varchar2(5);
w_rap_cap                  varchar2(5);
w_rap_stato                varchar2(100);
w_erede_denominazione_via  varchar2(60);
w_erede_num_civ            soggetti.num_civ%type;
w_erede_suffisso           recapiti_soggetto.suffisso%type;
w_erede_scala              soggetti.scala%type;
w_erede_piano              soggetti.piano%type;
w_erede_interno            soggetti.interno%type;
w_erede_cap                varchar2(10);
w_erede_comune             varchar2(40);
w_erede_provincia          varchar2(5);
w_erede_stato              varchar2(100);
w_risultato                varchar2(2000);
begin
--dbms_output.put_line('Parametri: '||a_tipo_tributo||', '||a_ni||', '||a_ni_erede||', '||a_tipo_soggetto||', '||a_campo);
-- Selezione dati soggetto
  begin
    select decode(sogg.ni_presso
                 ,null,nvl(f_recapito( sogg.ni
                                     , a_tipo_tributo
                                     , 1
                                     , trunc (sysdate)
                                     , 'DV'
                                     )
                          ,decode(sogg.cod_via
                                 ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                          )
                      ,decode(sogg_p.cod_via
                             ,null,sogg_p.denominazione_via
                             ,arvi_p.denom_uff))
         , decode(sogg.ni_presso
                 ,null,decode(f_recapito_conv( sogg.ni
                                             , a_tipo_tributo
                                             , 1
                                             , trunc (sysdate)
                                             , 'NC')
                             ,-1,to_number(null)
                             ,null,sogg.num_civ
                                  ,to_number(f_recapito_conv( sogg.ni
                                                  , a_tipo_tributo
                                                  , 1
                                                  , trunc (sysdate)
                                                  , 'NC'))
                            )
                 ,sogg_p.num_civ)
         , decode(sogg.ni_presso
                 ,null,trim(nvl(f_recapito_conv( sogg.ni
                                               , a_tipo_tributo
                                               , 1
                                               , trunc (sysdate)
                                               , 'SF')
                               ,sogg.suffisso)
                           )
                      ,sogg_p.suffisso)
         , decode(sogg.ni_presso
                 ,null,trim(nvl(f_recapito_conv( sogg.ni
                                               , a_tipo_tributo
                                               , 1
                                               , trunc (sysdate)
                                               , 'SC')
                               , sogg.scala)
                           )
                      ,sogg_p.scala)
         , decode(sogg.ni_presso
                 ,null,trim(nvl(f_recapito_conv( sogg.ni
                                               , a_tipo_tributo
                                               , 1
                                               , trunc (sysdate)
                                               , 'PI')
                               ,sogg.piano)
                           )
                      ,sogg_p.piano)
         , decode(sogg.ni_presso
                 ,null,decode(f_recapito_conv ( sogg.ni
                                              , a_tipo_tributo
                                              , 1
                                              , trunc (sysdate)
                                              , 'IN')
                             ,-1,to_number(null)
                             ,null,sogg.interno
                             ,to_number(f_recapito_conv ( sogg.ni
                                              , a_tipo_tributo
                                              , 1
                                              , trunc (sysdate)
                                              , 'IN'))
                             )
                 ,sogg_p.interno)
         , decode(sogg.ni_presso
                 ,null,nvl(f_recapito( sogg.ni
                                     , a_tipo_tributo
                                     , 1
                                     , trunc (sysdate)
                                     , 'CAP')
                          ,decode(nvl(sogg.zipcode,nvl(sogg.cap,ad4_comune.get_cap(sogg.cod_pro_res,sogg.cod_com_res)))
                                 ,'99999',''
                                 ,nvl(sogg.zipcode,lpad(nvl(sogg.cap,ad4_comune.get_cap(sogg.cod_pro_res,sogg.cod_com_res)),5,'0'))))
                 ,decode(nvl(sogg_p.zipcode,nvl(sogg_p.cap,ad4_comune.get_cap(sogg_p.cod_pro_res,sogg_p.cod_com_res)))
                        ,'99999',''
                        ,nvl(sogg_p.zipcode,lpad(nvl(sogg_p.cap,ad4_comune.get_cap(sogg_p.cod_pro_res,sogg_p.cod_com_res)),5,'0'))))
         , decode(sogg.ni_presso
                 ,null,nvl(f_recapito( sogg.ni
                                     , a_tipo_tributo
                                     , 1
                                     , trunc (sysdate)
                                     , 'CO')
                          ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                 ,ad4_comune.get_denominazione(sogg_p.cod_pro_res,sogg_p.cod_com_res))
--                      ,decode(sign(200 - sogg.cod_pro_res)
--                             ,1,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res)
--                             ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res)
--                             )
--                          )
--                 ,decode(sign(200 - sogg.cod_pro_res)
--                         ,1,ad4_comune.get_denominazione(sogg_p.cod_pro_res,sogg_p.cod_com_res)
--                         ,ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res)
--                         )
--                 )
         , decode(sogg.ni_presso
                 ,null,nvl(trim(replace(replace(f_recapito( sogg.ni
                                     , a_tipo_tributo
                                     , 1
                                     , trunc (sysdate)
                                     , 'SP'),'(',''),')',''))
                      ,decode(sign(200 - sogg.cod_pro_res)
                             ,1,ad4_provincia.get_sigla(sogg.cod_pro_res)
                             ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res)
                             )
                          )
                 ,decode(sign(200 - sogg_p.cod_pro_res)
                         ,1,ad4_provincia.get_sigla(sogg_p.cod_pro_res)
                         ,ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res)
                         ))
--                          ,ad4_provincia.get_sigla(sogg.cod_pro_res))
--                 ,ad4_provincia.get_sigla(sogg_p.cod_pro_res))
         , nvl(decode(sogg.ni_presso
                     ,null,nvl(f_recapito( sogg.ni
                                         , a_tipo_tributo
                                         , 1
                                         , trunc (sysdate)
                                         , 'SE')
                              ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res))
                     ,ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res))
               ,'ITALIA')
         , sogg.rappresentante
         , sogg.indirizzo_rap
         , decode(sign(200 - sogg.cod_pro_rap)
                 ,1,ad4_comune.get_denominazione(sogg.cod_pro_rap,sogg.cod_com_rap)
                 ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_rap)
                 )
         , decode(sign(200 - sogg.cod_pro_rap)
                 ,1,ad4_provincia.get_sigla(sogg.cod_pro_rap)
                 ,null)
         , ad4_comune.get_cap(sogg.cod_pro_rap,sogg.cod_com_rap)
         , decode(sign(200 - sogg.cod_pro_rap)
                 ,1,'ITALIA'
                 ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_rap)
                 )
      into w_denominazione_via
         , w_num_civ
         , w_suffisso
         , w_scala
         , w_piano
         , w_interno
         , w_cap
         , w_comune
         , w_provincia
         , w_stato
         , w_rappresentante
         , w_rap_indirizzo
         , w_rap_comune
         , w_rap_provincia
         , w_rap_cap
         , w_rap_stato
      from soggetti sogg
         , soggetti sogg_p
         , archivio_vie arvi
         , archivio_vie arvi_p
     where sogg.ni = a_ni
       and sogg.cod_via = arvi.cod_via(+)
       and sogg.ni_presso = sogg_p.ni (+)
       and sogg_p.cod_via = arvi_p.cod_via(+)
     ;
  --DBMS_OUTPUT.PUT_LINE('Denominazione via 0: '||w_denominazione_via);
  exception
    when others then
      w_denominazione_via := null;
      w_num_civ := to_number(null);
      w_suffisso := null;
      w_scala := null;
      w_piano := null;
      w_interno := to_number(null);
      w_cap := null;
      w_comune := null;
      w_provincia := null;
      w_stato := null;
      w_rappresentante := null;
      w_rap_indirizzo := null;
      w_rap_comune := null;
      w_rap_provincia := null;
      w_rap_cap := null;
      w_rap_stato := null;
  end;
  --DBMS_OUTPUT.PUT_LINE('Denominazione via 1: '||w_denominazione_via);
  -- Selezione dati erede
  if a_ni_erede is not null then
     begin
       select decode(sogg.ni_presso
                    ,null,nvl(f_recapito( sogg.ni
                                        , a_tipo_tributo
                                        , 1
                                        , trunc (sysdate)
                                        , 'DV'
                                        )
                             ,decode(sogg.cod_via
                                    ,null,sogg.denominazione_via
                                    ,arvi.denom_uff)
                             )
                         ,decode(sogg_p.cod_via
                                ,null,sogg_p.denominazione_via
                                ,arvi_p.denom_uff))
            , decode(sogg.ni_presso
                    ,null,decode(f_recapito_conv( sogg.ni
                                                , a_tipo_tributo
                                                , 1
                                                , trunc (sysdate)
                                                , 'NC')
                                ,-1,to_number(null)
                                ,null,sogg.num_civ
                                     ,to_number(f_recapito_conv( sogg.ni
                                                     , a_tipo_tributo
                                                     , 1
                                                     , trunc (sysdate)
                                                     , 'NC'))
                               )
                    ,sogg_p.num_civ)
            , decode(sogg.ni_presso
                    ,null,trim(nvl(f_recapito_conv( sogg.ni
                                                  , a_tipo_tributo
                                                  , 1
                                                  , trunc (sysdate)
                                                  , 'SF')
                                  ,sogg.suffisso)
                              )
                         ,sogg_p.suffisso)
            , decode(sogg.ni_presso
                    ,null,trim(nvl(f_recapito_conv( sogg.ni
                                                  , a_tipo_tributo
                                                  , 1
                                                  , trunc (sysdate)
                                                  , 'SC')
                                  , sogg.scala)
                              )
                         ,sogg_p.scala)
            , decode(sogg.ni_presso
                    ,null,trim(nvl(f_recapito_conv( sogg.ni
                                                  , a_tipo_tributo
                                                  , 1
                                                  , trunc (sysdate)
                                                  , 'PI')
                                  ,sogg.piano)
                              )
                         ,sogg_p.piano)
            , decode(sogg.ni_presso
                    ,null,decode(f_recapito_conv ( sogg.ni
                                                 , a_tipo_tributo
                                                 , 1
                                                 , trunc (sysdate)
                                                 , 'IN')
                                ,-1,to_number(null)
                                ,null,sogg.interno
                                ,to_number(f_recapito_conv ( sogg.ni
                                                 , a_tipo_tributo
                                                 , 1
                                                 , trunc (sysdate)
                                                 , 'IN'))
                                )
                    ,sogg_p.interno)
            , decode(sogg.ni_presso
                    ,null,nvl(f_recapito( sogg.ni
                                        , a_tipo_tributo
                                        , 1
                                        , trunc (sysdate)
                                        , 'CAP')
                             ,decode(nvl(sogg.zipcode,nvl(sogg.cap,ad4_comune.get_cap(sogg.cod_pro_res,sogg.cod_com_res)))
                                    ,'99999',''
                                            ,nvl(sogg.zipcode,lpad(nvl(sogg.cap,ad4_comune.get_cap(sogg.cod_pro_res,sogg.cod_com_res)),5,'0'))))
                    ,decode(nvl(sogg_p.zipcode,nvl(sogg_p.cap,ad4_comune.get_cap(sogg_p.cod_pro_res,sogg_p.cod_com_res)))
                           ,'99999',''
                           ,nvl(sogg_p.zipcode,lpad(nvl(sogg_p.cap,ad4_comune.get_cap(sogg_p.cod_pro_res,sogg_p.cod_com_res)),5,'0'))))
            , decode(sogg.ni_presso
                    ,null,nvl(f_recapito( sogg.ni
                                        , a_tipo_tributo
                                        , 1
                                        , trunc (sysdate)
                                        , 'CO')
                             ,decode(sign(200 - sogg.cod_pro_res)
                                    ,1,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res)
                                    ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res)
                                    )
                             )
                    ,decode(sign(200 - sogg.cod_pro_res)
                           ,1,ad4_comune.get_denominazione(sogg_p.cod_pro_res,sogg_p.cod_com_res)
                           ,ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res)
                           )
                    )
            ,decode(sogg.ni_presso
                    ,null,nvl(trim(replace(replace(f_recapito( sogg.ni
                                        , a_tipo_tributo
                                        , 1
                                        , trunc (sysdate)
                                        , 'SP'),'(',''),')',''))
                             ,ad4_provincia.get_sigla(sogg.cod_pro_res))
                    ,ad4_provincia.get_sigla(sogg_p.cod_pro_res))
            , nvl(decode(sogg.ni_presso
                        ,null,nvl(f_recapito( sogg.ni
                                            , a_tipo_tributo
                                            , 1
                                            , trunc (sysdate)
                                            , 'SE')
                                 ,ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res))
                        ,ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res))
                 ,'ITALIA')
         into w_erede_denominazione_via
            , w_erede_num_civ
            , w_erede_suffisso
            , w_erede_scala
            , w_erede_piano
            , w_erede_interno
            , w_erede_cap
            , w_erede_comune
            , w_erede_provincia
            , w_erede_stato
         from soggetti sogg
            , soggetti sogg_p
            , archivio_vie arvi
            , archivio_vie arvi_p
        where sogg.ni = a_ni_erede
          and sogg.cod_via = arvi.cod_via(+)
          and sogg.ni_presso = sogg_p.ni (+)
          and sogg_p.cod_via = arvi_p.cod_via(+)
        ;
     exception
       when others then
         w_erede_denominazione_via := null;
         w_erede_num_civ := to_number(null);
         w_erede_suffisso := null;
         w_erede_scala := null;
         w_erede_piano := null;
         w_erede_interno := to_number(null);
         w_erede_cap := null;
         w_erede_comune := null;
         w_erede_provincia := null;
         w_erede_stato := null;
     end;
  end if;
  -- Determinazione via_dest
  --DBMS_OUTPUT.PUT_LINE('Denominazione via 2: '||w_denominazione_via);
  if a_campo = 'DV' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := w_rap_indirizzo;
        --else
           w_risultato := w_denominazione_via;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_denominazione_via;
        else
           w_risultato := w_denominazione_via;
        end if;
     end if;
  end if;
  --
  if a_campo = 'NC' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := '';
        --else
           w_risultato := w_num_civ;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_num_civ;
        else
           w_risultato := w_num_civ;
        end if;
     end if;
  end if;
  --
  if a_campo = 'SF' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := '';
        --else
           w_risultato := w_suffisso;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_suffisso;
        else
           w_risultato := w_suffisso;
        end if;
     end if;
  end if;
  --
  if a_campo = 'SC' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := '';
        --else
           w_risultato := w_scala;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_scala;
        else
           w_risultato := w_scala;
        end if;
     end if;
  end if;
  --
  if a_campo = 'PI' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := '';
        --else
           w_risultato := w_piano;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_piano;
        else
           w_risultato := w_piano;
        end if;
     end if;
  end if;
  --
  if a_campo = 'IN' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := '';
        --else
           w_risultato := w_interno;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_interno;
        else
           w_risultato := w_interno;
        end if;
     end if;
  end if;
  --
  if a_campo = 'CO' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := w_rap_comune;
        --else
           w_risultato := w_comune;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_comune;
        else
           w_risultato := w_comune;
        end if;
     end if;
  end if;
  --
  if a_campo = 'SP' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := w_rap_provincia;
        --else
           w_risultato := w_provincia;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_provincia;
        else
           w_risultato := w_provincia;
        end if;
     end if;
  end if;
  --
  if a_campo = 'CAP' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := w_rap_cap;
        --else
           w_risultato := w_cap;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_cap;
        else
           w_risultato := w_cap;
        end if;
     end if;
  end if;
  --
  if a_campo = 'SE' then
     if a_tipo_soggetto = 11 then
        -- (VD - 28/01/2022): In caso di persona giuridica si passa il dato
        --                    del contribuente anche in presenza di
        --                    rappresentante legale
        --if w_rappresentante is not null then
        --   w_risultato := w_rap_stato;
        --else
           w_risultato := w_stato;
        --end if;
     else
        if a_ni_erede is not null then
           w_risultato := w_erede_stato;
        else
           w_risultato := w_stato;
        end if;
     end if;
  end if;
  --
  return w_risultato;
end;
/* End Function: F_GET_CAMPO_CSV */
/

