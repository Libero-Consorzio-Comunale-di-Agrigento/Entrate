--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_anno_tarsu stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_ANNO_TARSU
/*************************************************************************
 NOME:        F_IMPORTI_ANNO_TARSU
 DESCRIZIONE: Determina gli importi di imposta e addizionali da esporre
              nel riepilogo dei versamenti TARSU
 PARAMETRI:   Codice fiscale
              Anno
              Tipo tributo
              Rata
              Sequenza versamento
              Tipo                Identifica il tipo di importo che si
                                  vuole ottenere dalla funzione
                                  F_IMPORTI_RUOLI_TARSU
                                  IMPOSTA        Imposta (comprensiva di add.li)
                                  ADD_ECA        Addizionale ECA
                                  MAG_ECA        Maggiorazione ECA
                                  ECA            Add. + Magg. ECA
                                  ADD_PRO        Addizionale provinciale
                                  NETTO          Imposta al netto delle add.li
 RITORNA:     number              Importo della tipologia prescelta
 NOTE:
 Rev.    Date         Author      Note
 000     27/05/2016   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale                   varchar2
, p_anno                          number
, p_tipo_tributo                  varchar2
, p_sequenza                      number
, p_ruolo                         number
, p_rata                          number
, p_tipo                          varchar2
)
  return number
is
  w_min_sequenza                  versamenti.sequenza%type;
  w_ruolo                         ruoli.ruolo%type;
  w_tipo_emissione                ruoli.tipo_emissione%type;
  w_contatore                     number := 0;
  w_importo_tot                   number(15,2);
  w_importo                       number(15,2);
  w_tipo_sgravio                  varchar2(1);
--
begin
  w_ruolo := to_number(null);
  w_tipo_emissione := null;
  w_min_sequenza := to_number(null);
--
-- Si verifica se il versamento che si sta trattando e' il primo
-- per contribuente/anno: se si', si calcolano gli importi
-- altrimenti si restituisce null
--
  for vers in (select sequenza
                 from versamenti
                where cod_fiscale = p_cod_fiscale
                  and anno = p_anno
                  and tipo_tributo||'' = p_tipo_tributo
                  and pratica is null
--                  and ruolo is null
             order by data_pagamento,nvl(rata,0),sequenza)
  loop
    w_contatore := w_contatore + 1;
    if w_contatore = 1 then
       w_min_sequenza := vers.sequenza;
       exit;
    end if;
  end loop;
--
  if w_min_sequenza is null or
     w_min_sequenza <> p_sequenza then
     w_importo_tot := to_number(null);
  else
     --
     -- Si verifica se il versamento e' relativo a un ruolo e di
     -- che tipo di ruolo si tratta
     --
     if p_ruolo is not null then
        begin
          select ruolo
               , tipo_emissione
            into w_ruolo
               , w_tipo_emissione
            from ruoli
           where ruolo = p_ruolo;
        exception
          when others then
            w_ruolo := p_ruolo;
            w_tipo_emissione := null;
        end;
     end if;
     --
     -- Si determina l'ultimo ruolo per il contribuente e l'anno passati
     --
     if p_tipo_tributo = 'TARSU' then
        w_contatore := 0;
        for ruol in (select distinct ruoli.ruolo
                          , ruoli.tipo_emissione
                          , ruoli.data_emissione
                       from ruoli, ruoli_contribuente ruco
                      where ruoli.ruolo = ruco.ruolo
                        and ruco.cod_fiscale = p_cod_fiscale
                        and ruoli.anno_ruolo = p_anno
                        and ruoli.tipo_tributo = p_tipo_tributo
                        and ruoli.invio_consorzio is not null
                        and ruoli.tipo_emissione is not null
                   order by ruoli.data_emissione desc)
        loop
          w_contatore := w_contatore + 1;
          if w_contatore = 1 then
             w_ruolo := ruol.ruolo;
             w_tipo_emissione := ruol.tipo_emissione;
             exit;
          end if;
        end loop;
     end if;
     --
     if (w_ruolo is null or
         nvl(w_tipo_emissione,'X') = 'X') and
        p_ruolo is not null AND
        p_rata is not null then
        w_importo_tot := f_importi_ruoli_tarsu(p_cod_fiscale,p_anno,p_ruolo,p_rata,p_tipo);
     else
        --
        -- Si calcolano i vari importi del ruolo o dei ruoli da considerare
        -- (se si tratta di ruolo a saldo, occorre considerare anche i relativi
        --  ruoli in acconto)
        --
        w_importo_tot := 0;
        for ruco in (select w_ruolo ruolo
                       from dual
                      where w_tipo_emissione is not null
                      union
                     select ruol_succ.ruolo
                       from ruoli, ruoli ruol_succ
                      where nvl(ruol_succ.tipo_emissione,'X') in ('S','T')
                        and ruol_succ.invio_consorzio is not null
                        and ruol_succ.anno_ruolo = ruoli.anno_ruolo
                        and ruol_succ.tipo_tributo || '' = ruoli.tipo_tributo
                        and ruoli.ruolo = w_ruolo
                        and nvl(ruoli.tipo_emissione, 'T') = 'A'
                        and ruoli.tipo_ruolo = 1
                        and ruol_succ.ruolo != ruoli.ruolo
                        and w_tipo_emissione = 'A'
                      union
                     select ruol_prec.ruolo
                       from ruoli, ruoli ruol_prec
                      where nvl(ruol_prec.tipo_emissione,'X') = 'A'
                        and ruol_prec.invio_consorzio is not null
                        and ruol_prec.anno_ruolo = ruoli.anno_ruolo
                        and ruol_prec.tipo_tributo || '' = ruoli.tipo_tributo
                        and ruoli.ruolo = w_ruolo
                        and nvl(ruoli.tipo_emissione, 'T') = 'S'
                        and ruoli.tipo_ruolo = 1
                        and ruol_prec.ruolo != ruoli.ruolo
                        and w_tipo_emissione in ('S','T')
                      order by 1)
        loop
          for dett in (select decode(p_tipo,'IMPOSTA',ogim.imposta
                                                    + nvl(ogim.addizionale_eca,0)
                                                    + nvl(ogim.maggiorazione_eca,0)
                                                    + nvl(ogim.addizionale_pro,0)
                                                    + nvl(ogim.maggiorazione_tares,0)
                                           ,'ECA',    nvl(ogim.addizionale_eca,0) +
                                                      nvl(ogim.maggiorazione_eca,0)
                                           ,'ADD_PRO',nvl(ogim.addizionale_pro,0)
                                           ,'MAG_TAR',nvl(ogim.maggiorazione_tares,0)
                                           ,'NETTO',  ogim.imposta) importo
                         from oggetti_imposta  ogim
                        where ogim.cod_fiscale  = p_cod_fiscale
                          and ogim.anno         = p_anno
                          and ogim.ruolo        = ruco.ruolo)
          loop
            w_importo_tot := w_importo_tot + nvl(dett.importo,0);
          end loop;
          --
          -- Trattamento sgravi: si tolgono dall'importo del ruolo
          -- eventuali sgravi gia' emessi
          --
          begin
            select decode(p_tipo,'IMPOSTA','L'
                                ,'ECA'    ,'E'
                                ,'ADD_PRO','P'
                                ,'NETTO'  ,'N'
                                ,'MAG_TAR','M')
              into w_tipo_sgravio
              from dual;
          exception
            when others then
              w_tipo_sgravio := null;
          end;
          --
          if w_tipo_sgravio is not null then
             w_importo := f_sgravio_anno(ruco.ruolo,p_cod_fiscale,w_tipo_sgravio);
             w_importo_tot := w_importo_tot - nvl(w_importo,0);
           end if;
        end loop;
     end if;
  end if;
--
  return w_importo_tot;
--
end;
/* End Function: F_IMPORTI_ANNO_TARSU */
/

