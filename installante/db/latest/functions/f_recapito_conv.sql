--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_recapito_conv stripComments:false runOnChange:true 
 
create or replace function F_RECAPITO_CONV
/*************************************************************************
 NOME:        F_RECAPITO_CONV
 DESCRIZIONE: Restituisce il recapito per soggetto, tipo_tributo, tipo_recapito,
              data.
              Se tipo_recapito = 1 (indirizzo) ritorna una stringa con
              l'indirizzo completo.
              Il parametro p_campo ha senso solo per tipo_recapito = 1
              (indirizzo) e può assumere i seguenti valori:
              CC  - comune completo (cap || comune || provincia o stato)
              SE  - Stato Estero
              PR  - Presso (compreso la scritta Presso:)
              CAP - Cap
              CO  - Comune (solo denominazione)
              SP  - Sigla provincia
              CV  - Codice via
              DV  - Denominazione via
              NC  - Numero civico
              SF  - Suffisso civico
              IN  - Interno
              SC  - Scala
              PI  - Piano
              ID  - Indirizzo senza dettaglio (solo via, num.civ. e suff.)
              DI  - Dettaglio indirizzo: contiene scala, piano e interno
                    concatenati in un'unica stringa (per invio postale
                    massivo)
              CP  - Denominazione comune concatenata con sigla provincia
                    tra parentesi (per invio postale massivo)
              SPS - Sigla provincia o stato ad uso DEPAG
              SS2 - Sigla Stato Estero
              PND - Indirizzo completo senza caratteri speciali (es. virgola)
              
              Il parametro p_se_comune ha senso solo per tipo_recapito 1 e
              ritorna il comune dell'indirizzo.
              Il parametro p_se_stato ha senso solo per tipo_recapito 1 e
              ritorna lo stato estero dell'indirizzo (se Italia ritorna null).
              Il parametro p_se_presso ha senso solo per tipo_recapito 1 e
              ritorna il presso dell'indirizzo (compreso la scritta Presso:)
 Rev.    Date         Author      Note
 012     11/12/2023   VM          #67904 - Aggiunta gestione p_campo = 'PND'
                                  per formattazione indirizzo completo 
                                  senza separatore (virgola)
 011     20/12/2021   AB          Gestione dei dati del Comune anche estero
 010     21/07/2021   VD          Corretta selezione stato estero: se la
                                  provincia è < 200 la funzione restituisce
                                  'ITALIA'.
 009     23/06/2021   VD          Personalizzazione Belluno/Canone Unico:
                                  se non esiste il tipo recapito 2 o 3 per
                                  il canone unico non si estrae nulla.
 008     24/11/2020   VD          Aggiunto valore SS per parametro p_campo.
 007     09/11/2020   VD          Eliminate parentesi da sigla provincia
                                  Aggiunto valore SPS per parametro p_campo
                                  SPS - Sigla provincia o stato ad uso DEPAG
 006     25/05/2020   VD          Aggiunta gestione p_campo = 'DI' - dettaglio
                                  indirizzo
 005     17/03/2020   VD          Corretta gestione valore 'SP' del parametro
                                  p_campo: ora se si tratta di uno stato
                                  estero restituisce la denominazione.
 004     04/04/2019   VD          Aggiunta gestione valori 'CV', 'DV', 'NC',
                                  'SF', 'IN', 'SC', 'PI' di p_campo.
 003     09/10/2014   Betta T.    Aggiunta gestione valori 'CAP', 'CO' e 'SP'
                                  di p_campo
 002     08/10/2014   Betta T.    Modificati parametri: eliminati p_se_comune,
                                  p_se_stato, p_se_presso per unificarli in un
                                  unico parametro p_campo per aggiungere i campi
                                  necessari alle proc. che devono estrarre
                                  i recapiti.
 001     30/09/2014   Betta T.    Aggiunto gestione presso
 000     06/08/2014               Prima emissione.
*************************************************************************/
(p_ni             number,
 p_tipo_tributo   varchar2,
 p_tipo_recapito  number,
 p_data_val       date default trunc(sysdate),
 p_campo          varchar2 default null)
/* p_se_comune      varchar2 default null,
 p_se_stato       varchar2 default null,
 p_se_presso      varchar2 default null)*/
RETURN varchar2
IS
  reso                          recapiti_soggetto%rowtype;
  w_recapito                    varchar2(2000);
  w_cap                         varchar2(10);
  w_sigla_prov                  varchar2(2000);
  w_sigla_depag                 varchar2(2);
  w_sigla_stato_alpha2          varchar2(2);
  w_denominazione               ad4_comuni.denominazione%type;
  w_denominazione_via           archivio_vie.denom_uff%type;
  w_comune_provincia            varchar2(2000);
  w_dati_comune                 varchar2(6);
  w_separator                   varchar2(1) := ',';
BEGIN
  begin
    select lpad(pro_cliente,3,'0')||lpad(com_cliente,3,'0')
      into w_dati_comune
      from dati_generali;
  exception
    when others then
      w_dati_comune := '000000';
  end;
  begin
    select *
    into   reso
    from   recapiti_soggetto
    where  ni = p_ni
    and    tipo_tributo = p_tipo_tributo
    and    tipo_recapito = p_tipo_recapito
    and    p_data_val between nvl(dal,to_date('01/01/1900','dd/mm/yyyy'))
                          and nvl(al,to_date('01/01/3900','dd/mm/yyyy'))
    ;
  exception
    when no_data_found
    then if w_dati_comune <> '025006' or
            p_tipo_tributo <> 'CUNI' or
            p_tipo_recapito not in (2,3) then
            begin
              select *
              into   reso
              from   recapiti_soggetto
              where  ni = p_ni
              and    tipo_tributo is null
              and    tipo_recapito = p_tipo_recapito
              and    p_data_val between nvl(dal,to_date('01/01/1900','dd/mm/yyyy'))
                                    and nvl(al,to_date('01/01/3900','dd/mm/yyyy'))
              ;
            exception
              when no_data_found then w_recapito := null;
              when too_many_rows then
                   begin
                     select *
                     into   reso
                     from   recapiti_soggetto reso
                     where  reso.ni = p_ni
                     and    reso.tipo_tributo is null
                     and    reso.tipo_recapito = p_tipo_recapito
                     and    p_data_val between nvl(reso.dal,to_date('01/01/1900','dd/mm/yyyy'))
                                           and nvl(reso.al,to_date('01/01/3900','dd/mm/yyyy'))
                     and    nvl(reso.dal,to_date('01/01/1900','dd/mm/yyyy')) =
                           (select max(nvl(x.dal,to_date('01/01/1900','dd/mm/yyyy')))
                            from   recapiti_soggetto x
                            where  x.ni = p_ni
                            and    x.tipo_tributo is null
                            and    reso.tipo_recapito = p_tipo_recapito)
                     ;
                   exception
                     when others then
                       w_recapito := null;
                   end;
            end;
        end if;
    when too_many_rows then
         begin
           select *
           into   reso
           from   recapiti_soggetto reso
           where  reso.ni = p_ni
           and    reso.tipo_tributo = p_tipo_tributo
           and    reso.tipo_recapito = p_tipo_recapito
           and    p_data_val between nvl(reso.dal,to_date('01/01/1900','dd/mm/yyyy'))
                                 and nvl(reso.al,to_date('01/01/3900','dd/mm/yyyy'))
           and    nvl(reso.dal,to_date('01/01/1900','dd/mm/yyyy')) =
                 (select max(nvl(x.dal,to_date('01/01/1900','dd/mm/yyyy')))
                  from   recapiti_soggetto x
                  where  x.ni = p_ni
                  and    x.tipo_tributo = p_tipo_tributo
                  and    reso.tipo_recapito = p_tipo_recapito)
           ;
         exception
           when others then
             w_recapito := null;
         end;
  end;
  if reso.ni is not null then -- abbiamo trovato qualcosa
     if p_tipo_recapito = 1 then -- indirizzo, dobbiamo ritornare una stringa composta
       
       if nvl(p_campo,'*') = 'PND' then
         w_separator := '';
       end if;
       
       if nvl(p_campo,'*') in ('CC','CAP','CO','SP','CP','SPS','SS2') then --dobbiamo ritornare dati del comune
         begin
           select decode(nvl(reso.zipcode,nvl(reso.cap,comu.cap))
--                   decode(nvl(reso.cap,comu.cap)
                         ,'99999',''
                         ,nvl(reso.zipcode,lpad(nvl(reso.cap,comu.cap),5,'0'))||' '
                         )
                   ||comu.denominazione
                   ||decode(sign(200-reso.cod_pro)
                           ,1,decode(prov.sigla,null,'',' (' ||prov.sigla|| ')')
                           ,decode(stte.denominazione
                                  ,null,''
                                  ,comu.denominazione,''
                                  ,' (' ||stte.denominazione || ')'
                                  )
                           )
                , decode(nvl(reso.zipcode,nvl(reso.cap,comu.cap))
                         ,'99999',''
                         ,nvl(reso.zipcode,lpad(nvl(reso.cap,comu.cap),5,'0')))
--                , decode(nvl(reso.cap,comu.cap)
--                         ,'99999',''
--                         ,lpad(nvl(reso.cap,comu.cap),5,'0')
--                         )
                , comu.denominazione
                , decode(sign(200-reso.cod_pro)
                        ,1,decode(prov.sigla,null,'',' (' ||prov.sigla|| ')')
                          ,decode(stte.denominazione
                                 ,comu.denominazione,''
                                                    ,' ('||stte.denominazione || ')'
                                 )
                        )
                , comu.denominazione||
                  decode(sign(200-reso.cod_pro)
                        ,1,decode(prov.sigla,null,'',' (' ||prov.sigla|| ')')
                          ,decode(stte.denominazione
                                 ,comu.denominazione,''
                                                    ,' '||stte.denominazione
                                 )
                        )
                , decode(sign(200-reso.cod_pro)
                        ,1,decode(nvl(length(prov.sigla),0),2,prov.sigla,'')
                          ,decode(nvl(length(stte.sigla_iso3166_alpha2),0)
                                 ,2,stte.sigla_iso3166_alpha2,'')
                        )
                , decode(sign(200-reso.cod_pro)
                        ,1,'IT'
                          ,decode(nvl(length(stte.sigla_iso3166_alpha2),0)
                                 ,2,stte.sigla_iso3166_alpha2,'')
                        )
           into   w_recapito
                 ,w_cap
                 ,w_denominazione
                 ,w_sigla_prov
                 ,w_comune_provincia
                 ,w_sigla_depag
                 ,w_sigla_stato_alpha2
           from   ad4_comuni comu,
                  ad4_provincie      prov,
                  ad4_stati_territori stte
           where  reso.cod_pro           = comu.provincia_stato
           and    reso.cod_com           = comu.comune
           and    comu.provincia_stato   = prov.provincia (+)
           and    comu.provincia_stato   = stte.stato_territorio (+)
           ;
         exception
           when no_data_found then w_recapito := null;
         end;
         if nvl(p_campo,'*') = 'CC' then -- comune completo è già in w_recapito
            null;
         elsif nvl(p_campo,'*') = 'CAP' then -- cap
            w_recapito := w_cap;
         elsif nvl(p_campo,'*') = 'CO' then -- denom. comune
            w_recapito := w_denominazione;
         elsif nvl(p_campo,'*') = 'SP' then -- sigla provincia
            w_recapito := w_sigla_prov;
         elsif nvl(p_campo,'*') = 'CP' then -- comune + provincia
            w_recapito := w_comune_provincia;
         elsif nvl(p_campo,'*') = 'SPS' then  -- sigla provincia o stato estero x depag
            w_recapito := w_sigla_depag;
         else
            w_recapito := w_sigla_stato_alpha2; -- SS - Sigla stato ISO 3166 2 crt per depag
         end if;
       elsif nvl(p_campo,'*') = 'SE' then --dobbiamo ritornare lo stato estero
           if reso.cod_pro < 200 then  -- Comune italiano
              w_recapito := 'ITALIA';
           else
              select stte.denominazione
              into   w_recapito
              from   ad4_comuni comu,
                     ad4_provincie      prov,
                     ad4_stati_territori stte
              where  reso.cod_pro           = comu.provincia_stato
              and    reso.cod_com           = comu.comune
              and    comu.provincia_stato   = prov.provincia (+)
              and    comu.provincia_stato   = stte.stato_territorio (+)
              ;
           end if;
       elsif nvl(p_campo,'*') = 'PR' then --dobbiamo ritornare il presso
           if reso.presso is null
              or upper(reso.presso) like 'C/O%'
              or upper(reso.presso) like 'PRESSO:%'
              or upper(reso.presso) like 'PRESSO %' then
              w_recapito := reso.presso;
           else
              w_recapito := 'Presso: '||upper(reso.presso);
           end if;
       else
         begin
           select arvi.denom_uff
                  ||decode(reso.num_civ,null,'', w_separator||' '||to_char(reso.num_civ))
                  ||decode(reso.suffisso,null,'', '/'||reso.suffisso)
                  ||decode(reso.scala, NULL, '', ' Sc.'||reso.scala)
                  ||decode(reso.piano, NULL, '', ' P.'||reso.piano)
                  ||decode(reso.interno, NULL, '',  ' Int.'||reso.interno),
                  arvi.denom_uff
           into   w_recapito,
                  w_denominazione_via
           from   archivio_vie arvi
           where  arvi.cod_via = reso.cod_via
           ;
         exception
           when no_data_found
           then select reso.descrizione
                      ||decode(reso.num_civ,null,'', w_separator||' '||to_char(reso.num_civ))
                      ||decode(reso.suffisso,null,'', '/'||reso.suffisso)
                      ||decode(reso.scala, NULL, '', ' Sc.'||reso.scala)
                      ||decode(reso.piano, NULL, '', ' P.'||reso.piano)
                      ||decode(reso.interno, NULL, '',  ' Int.'||reso.interno),
                       upper(reso.descrizione)
               into   w_recapito,
                      w_denominazione_via
               from   dual
               ;
         end;
         if nvl(p_campo,'*') = 'DV' then -- denominazione via
            w_recapito := w_denominazione_via;
         elsif nvl(p_campo,'*') = 'CV' then -- Codice via
            w_recapito := reso.cod_via;
         elsif nvl(p_campo,'*') = 'NC' then -- Numero civico
            if w_denominazione_via is null then
               w_recapito := to_number(null);
            else
               w_recapito := nvl(reso.num_civ,-1);
            end if;
         elsif nvl(p_campo,'*') = 'SF' then -- Suffisso civico
            if w_denominazione_via is null then
               w_recapito := null;
            else
               w_recapito := nvl(reso.suffisso,' ');
            end if;
         elsif nvl(p_campo,'*') = 'SC' then -- Scala
            if w_denominazione_via is null then
               w_recapito := null;
            else
               w_recapito := nvl(reso.scala,' ');
            end if;
         elsif nvl(p_campo,'*') = 'PI' then -- Piano
            if w_denominazione_via is null then
               w_recapito := null;
            else
               w_recapito := nvl(reso.piano,' ');
            end if;
         elsif nvl(p_campo,'*') = 'IN' then -- Interno
            if w_denominazione_via is null then
               w_recapito := null;
            else
               w_recapito := nvl(reso.interno,-1);
            end if;
         elsif nvl(p_campo,'*') = 'ID' then -- Indirizzo senza dettaglio
            w_recapito := w_denominazione_via||' '||reso.num_civ;
            if reso.suffisso is not null then
               w_recapito := w_recapito||'/'||reso.suffisso;
            end if;
         elsif nvl(p_campo,'*') = 'DI' then -- Dettaglio indirizzo
            w_recapito := '';
            if reso.scala is not null then
               w_recapito := 'Scala '||reso.scala;
            end if;
            if reso.piano is not null then
               w_recapito := w_recapito || ' Piano '||reso.piano;
            end if;
            if reso.interno is not null then
               w_recapito := w_recapito || ' Int. '||reso.interno;
            end if;
            w_recapito := ltrim(w_recapito);
         end if;
       end if;
     else
        w_recapito := reso.descrizione;
     end if;
  end if;
  RETURN w_recapito;
END;
/* End Function: F_RECAPITO_CONV */
/
