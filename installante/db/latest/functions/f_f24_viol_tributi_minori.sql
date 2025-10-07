--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_viol_tributi_minori stripComments:false runOnChange:true 
 
create or replace function F_F24_VIOL_TRIBUTI_MINORI
/*************************************************************************
 NOME:        F_F24_VIOL_TRIBUTI_MINORI
 DESCRIZIONE: Modello F24 violazioni tributi minori: determina gli importi
              divisi per codice tributo delle pratiche di accertamento.
              Utilizzata in PB per w_f24_viol_titr_stampa.
 PARAMETRI:   Riga                Numero della riga del modulo F24 da
                                  da stampare
              Tipo tributo        TOSAP/ICP
              Anno                Anno di riferimento
              Pratica             Pratica di accertamento
              Flag Imp. Ridotto   Stampa F24 con importo ridotto
                                  S - Sì
                                  N o null - No
 RITORNA:     varchar2            Stringa contenente il codice tributo e
                                  l'importo
 NOTE:
 Rev.    Date         Author      Note
 001	 07/04/2023	  CM		  Implementato calcolo importi ridotti.
 000     22/11/2019   VD          Prima emissione.
*************************************************************************/
(a_riga                number
,a_tipo_tributo        varchar2
,a_anno                number
,a_pratica             number
,a_importo_ridotto     varchar2
)
    return varchar2
    is
    w_imposta_perm       varchar2(19);
    w_imposta_temp       varchar2(19);
    w_interessi          varchar2(19);
    w_sanzioni           varchar2(19);
    w_cf24_permanente    varchar2(4);
    w_cf24_temporanea    varchar2(4);
    w_cod_tributo        varchar2(4);
    w_tot_permanente     number := 0;
    w_tot_temporanea     number := 0;
    TYPE type_riga IS TABLE OF varchar2(19)
        INDEX BY binary_integer;
    t_riga       type_riga;
    i            binary_integer := 1;
begin
    --
    -- Selezione codici F24 da nuovo dizionario
    --
    begin
        select min(decode(tipo_codice,'C',tributo_f24,'')) cf24_permanente,
               max(decode(tipo_codice,'C',tributo_f24,'')) cf24_temporanea
        into w_cf24_permanente
            , w_cf24_temporanea
        from codici_f24
        where tipo_tributo = a_tipo_tributo
          and descrizione_titr = f_descrizione_titr(a_tipo_tributo,a_anno);
    exception
        when others then
            if a_tipo_tributo = 'TOSAP' then
                w_cf24_permanente := '3931';
                w_cf24_temporanea := '3932';
            else
                w_cf24_permanente := '3964';
                w_cf24_temporanea := '3964';
            end if;
    end;
    --
    -- Selezione sanzioni per pratica
    --
    for rec_sanz in (select sanz.cod_tributo_f24,
                            (select min(ogpr.tipo_occupazione)
                             from oggetti_pratica ogpr
                             where pratica = a_pratica) tipo_occupazione,
                            sum(sapr.importo *
                                (100 - decode(a_importo_ridotto, 'S', nvl(sapr.riduzione, 0), 0)) / 100) importo
                     from pratiche_tributo   prtr
                        , sanzioni_pratica   sapr
                        , sanzioni           sanz
                     where prtr.pratica = a_pratica
                       and prtr.pratica = sapr.pratica
                       and sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and sapr.tipo_tributo = sanz.tipo_tributo
                     group by sanz.cod_tributo_f24
                     order by sanz.cod_tributo_f24 nulls first)
        loop
            if rec_sanz.cod_tributo_f24 is null then
                if rec_sanz.tipo_occupazione = 'P' then
                    w_cod_tributo := w_cf24_permanente;
                else
                    w_cod_tributo := w_cf24_temporanea;
                end if;
            else
                w_cod_tributo := rec_sanz.cod_tributo_f24;
            end if;
            --
            if nvl(round(rec_sanz.importo,0),0) > 0 then
                t_riga(to_char(i)) := w_cod_tributo||to_char(round(rec_sanz.importo,0),'999999990');
                i := i+1;
            end if;
        end loop;
    return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_VIOL_TRIBUTI_MINORI */
/
