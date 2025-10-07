--liquibase formatted sql 
--changeset rvattolo:20250312_100909_f_importo_ruolo_ruxx stripComments:false runOnChange:true 

create or replace function F_IMPORTO_RUOLO_RUXX
/******************************************************************************
 NOME:             F_IMPORTO_RUOLO_RUXX

 DESCRIZIONE:      Calcola il totale del ruolo per il CF usando i dati
                   di ruoli_contribuente e ruoli_eccedenze.

 NOTE:             Al contrario di f_calcolo_rata_tarsu non considera 
                   le addizionali provinciali come arrotondate a se, ma
                   come cifra parziale integrata nel totale arrotondato.
                   Questo ai fini dei pagamenti unici come DePag.

 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   12/03/2025  XX      #78971
                             Versione Iniziale
*****************************************************************************
-- p_tipo_calcolo :
--    L  : Totale Lordo
--    I  : Totale Imposta
--    A  : Totale Addizionale Provinciale
--    M  : Totale Maggiorazione TARES (Componenti perequative)
*****************************************************************************/
( p_cod_fiscale             varchar2                  -- Codice Fiscale
, p_ruolo                   number                    -- Numero di Ruolo
, p_arrotondamento          number                    -- 0 : Intero o 2: Centesimi
, p_tipo_calcolo            varchar2 default null     -- Vedi sopra
) return number
is
  --
  w_arrotondamento          number;
  --
  w_tipo_calcolo            varchar2(2);
  --
  w_importo                 number;
  --
--
------------------------------------------------------------------
-- Cursore per calcolo totali ruxx
------------------------------------------------------------------
cursor sel_ruxx(a_cod_fiscale varchar2, a_ruolo number, a_arrotondamento number)
IS
  select
    round(sum(dett.lordo),a_arrotondamento) totale_lordo,
    round(sum(dett.imposta),a_arrotondamento) totale_imposta,
    round(sum(dett.add_pro),a_arrotondamento) totale_add_pro,
    round(sum(dett.magg_tares),a_arrotondamento) totale_magg_tares
  from
     (
     -- Totale RUCO per cod_fiscale
     select ruco.ruolo,
            ruco.cod_fiscale,
            sum(ruco.importo) lordo,
            sum(nvl(ogim.imposta,0)) imposta,
            sum(nvl(ogim.add_pro,0)) add_pro,
            sum(nvl(ogim.magg_tares,0)) magg_tares
       from ruoli_contribuente ruco,
            (
            select ruco.ruolo,
                   ruco.cod_fiscale,
                   ruco.sequenza,
                   nvl(sum(nvl(ogim.imposta,0)),0) as imposta,
                   nvl(sum(nvl(ogim.addizionale_pro,0)),0) as add_pro,
                   nvl(sum(nvl(ogim.maggiorazione_tares,0)),0) as magg_tares
             from  ruoli_contribuente ruco,
                   oggetti_imposta ogim
             where ruco.ruolo = a_ruolo
               and ruco.cod_fiscale = a_cod_fiscale
               and ruco.oggetto_imposta = ogim.oggetto_imposta(+)
             group by
                   ruco.ruolo,
                   ruco.cod_fiscale,
                   ruco.sequenza
              ) ogim
      where ruco.ruolo = a_ruolo
        and ruco.cod_fiscale = a_cod_fiscale
        and ruco.ruolo = ogim.ruolo(+)
        and ruco.cod_fiscale = ogim.cod_fiscale(+)
        and ruco.sequenza = ogim.sequenza(+)
     group by
           ruco.ruolo,
           ruco.cod_fiscale
     union
     -- Totale RUEC per cod_fiscale
     select ruec.ruolo,
            ruec.cod_fiscale,
            sum(nvl(ruec.importo_ruolo,0)) lordo,
            sum(nvl(ruec.imposta,0)) imposta,
            sum(nvl(ruec.addizionale_pro,0)) add_pro,
            0 as magg_tares
       from ruoli_eccedenze ruec
      where ruec.ruolo = a_ruolo
        and ruec.cod_fiscale = a_cod_fiscale
     group by
           ruec.ruolo,
           ruec.cod_fiscale
     ) dett
  ;
--
------------------------------------------------------------------
--
begin
  --
  w_arrotondamento := round(p_arrotondamento,0);
  --
  w_tipo_calcolo := nvl(p_tipo_calcolo,'L');
  --
  begin
    FOR rec_sbil IN sel_ruxx(p_cod_fiscale,p_ruolo,w_arrotondamento)
    LOOP
      if w_tipo_calcolo = 'L' then
        w_importo := rec_sbil.totale_lordo;
      elsif w_tipo_calcolo = 'I' then
        w_importo := rec_sbil.totale_imposta;
      elsif w_tipo_calcolo = 'A' then
        w_importo := rec_sbil.totale_add_pro;
      elsif w_tipo_calcolo = 'M' then
        w_importo := rec_sbil.totale_magg_tares;
      else
        w_importo := 0;
      end if;
      --
      exit;
    END LOOP;
  exception
    when others then
      w_importo := 0;
  end;
  --
  return w_importo;
  --
end;
/* End Function: F_IMPORTO_RUOLO_RUXX */
/
