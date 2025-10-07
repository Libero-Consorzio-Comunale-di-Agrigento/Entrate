--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sbilancio_tares stripComments:false runOnChange:true 
 
create or replace function F_SBILANCIO_TARES
/******************************************************************************
 NOME:             F_SBILANCIO_TARES

 DESCRIZIONE:      Calcola lo sbilancio di importo lordo ruolo per rate causa TARES (C.Pereq.)
                   Lo sbilancio totale è la quota arrotondata TARES da togliere dal totale lordo
                   del ruolo arrotondato, quindi dopo aver calcolato le rate come al solito si
                   aggiunge ad ogni singola rata lo sbilancio specifico.
                   In questo modo il totale non cambia ma distribuisce meglio la quota TARES.
                   Uno sbilancio totale pari a zero indica che la TARES è stata spalmata 
                   equamente su tutte le rate, oppure che non esiste TARES.

 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   13/02/2025  RV      #77805
                             Versione Iniziale
*****************************************************************************
-- p_tipo_calcolo :
--    S  : Sbilancio totale tares e per rata (da raim)
--    SG : Sbilancio totale tares senza sgravi e per rata (da raim)
--    T  : Valore totale tares e per rata (da raim)
--    TG : Valore totale tares senza sgravi e per rata (da raim)
*****************************************************************************/
( p_cod_fiscale             varchar2                  -- Codice Fiscale
, p_ruolo                   number                    -- Numero di Ruolo
, p_rata                    number                    -- Numero della rata (0: per Sbilancio Totale)
, p_arrotondamento          number                    -- 0 : Intero o 2: Centesimi
, p_tipo_calcolo            varchar2 default null     -- Vedi sopra
) return number
is
  --
  w_arrotondamento          number;
  --
  w_tipo_calcolo            varchar2(2);
  w_tipo_calcolo_sub        varchar2(1);
  --
  w_applica_sgravi          varchar2(1);
  --
  w_rata_num                number;
  --
  w_importo                 number;
  --
--
-- Cursore per calcolo Sbilancio
--
cursor sel_sbil (a_cod_fiscale varchar2, a_ruolo number, a_arrotondamento number, a_applica_sgravi varchar2)
IS
  select
    rast.rata,
    rast.netto_rata as sbil_rata,
    case when sum(rast.netto_rata) over() > 0 then
      -- Se la TARES di nessuna rata supera il 75% del totale allora lo sbilancio
      -- non esiste in quanto egualmente distribuito sulle rate oppure assente
      rast.netto_tares
    else
      0
    end sbil_totale
  from
    (
    select
      rasg.rata,
--      case when rasg.maggiorazione_tares > (rasg.totale_tares * 0.75) then
--        round(rasg.maggiorazione_tares - sgravio_tares,a_arrotondamento)
--      else
--        0
--      end tares_rata,
--      round(rasg.totale_tares,a_arrotondamento) as totale_tares,
      case when rasg.maggiorazione_tares > (rasg.totale_tares * 0.75) then
        round(rasg.maggiorazione_tares - sgravio_tares,a_arrotondamento)
      else
        0
      end netto_rata,
      round(rasg.totale_tares - rasg.totale_sgravi,a_arrotondamento) as netto_tares
    from
      (
      select
        rasb.rata,
        rasb.maggiorazione_tares,
        round((rasb.totale_sgravi * rasb.maggiorazione_tares) / 
               decode(rasb.totale_tares,0,1,rasb.totale_tares),2) as sgravio_tares,
        rasb.totale_tares,
        rasb.totale_sgravi
      from
        (
        select
          ratt.rata,
          ratt.maggiorazione_tares,
          sum(ratt.maggiorazione_tares) over () as totale_tares,
          nvl(sgrav.totale_sgravi,0) as totale_sgravi
        from
          (
          select
            raim.rata,
            sum(nvl(raim.maggiorazione_tares,0)) as maggiorazione_tares
            from rate_imposta raim
           where raim.oggetto_imposta in
              (select oggetto_imposta
                 from oggetti_imposta
                where ruolo = a_ruolo and cod_fiscale = a_cod_fiscale
           )
          group by raim.rata
          ) ratt,
          (
          select
            sum(nvl(maggiorazione_tares,0)) as totale_sgravi
            from
            sgravi
           where ruolo = a_ruolo and cod_fiscale = a_cod_fiscale
             and nvl(a_applica_sgravi,'M') = 'S'
          ) sgrav
        ) rasb
      ) rasg
    ) rast
 ;
--
-- Cursore per calcolo rate TARES da parziali raim
--
cursor sel_rtar(a_cod_fiscale varchar2, a_ruolo number, a_arrotondamento number, a_applica_sgravi varchar2)
IS
  select
      rarr.rata,
      rarr.maggiorazione_tares,
      case when rarr.rata = rarr.rate then
        rarr.totale_sgravi - sum(rarr.sgravio_tares) over() + rarr.sgravio_tares
      else
        rarr.sgravio_tares
      end sgravio_tares,
      rarr.totale_tares,
      rarr.totale_sgravi
  from
    (
    select
      rasb.rata,
      ruol.rate,
      round(rasb.maggiorazione_tares,a_arrotondamento) maggiorazione_tares,
      round((rasb.totale_sgravi * rasb.maggiorazione_tares) / 
             decode(rasb.totale_tares,0,1,rasb.totale_tares),a_arrotondamento) as sgravio_tares,
      round(rasb.totale_tares,a_arrotondamento) as totale_tares,
      round(rasb.totale_sgravi,a_arrotondamento) as totale_sgravi
    from
      ruoli ruol,
      (
      select
        ratt.rata,
        ratt.maggiorazione_tares,
        sum(ratt.maggiorazione_tares) over () as totale_tares,
        nvl(sgrav.totale_sgravi,0) as totale_sgravi
      from
        (
        select
          raim.rata,
          sum(nvl(raim.maggiorazione_tares,0)) as maggiorazione_tares
          from rate_imposta raim
         where raim.oggetto_imposta in
            (select oggetto_imposta
               from oggetti_imposta
              where ruolo = a_ruolo and cod_fiscale = a_cod_fiscale
         )
        group by raim.rata
        ) ratt,
        (
        select
          sum(nvl(maggiorazione_tares,0)) as totale_sgravi
          from
          sgravi
         where ruolo = a_ruolo and cod_fiscale = a_cod_fiscale
           and nvl(a_applica_sgravi,'M') = 'S'
        ) sgrav
      ) rasb
    where
        ruol.ruolo = a_ruolo
    ) rarr
 ;
begin
  --
  w_arrotondamento := round(p_arrotondamento,0);
  --
  w_tipo_calcolo := substr(nvl(p_tipo_calcolo,'S'),1,2);
  if length(w_tipo_calcolo) > 1 then
    w_tipo_calcolo_sub := substr(w_tipo_calcolo,2,1);
  else
    w_tipo_calcolo_sub := null;
  end if;
  w_tipo_calcolo := substr(w_tipo_calcolo,1,1);
  --
--dbms_output.put_line('Calcolo: '||w_tipo_calcolo||'/'||w_tipo_calcolo_sub);
  --
  if w_tipo_calcolo_sub = 'G' then
    w_applica_sgravi := 'S';
  else
    w_applica_sgravi := null;
  end if;
  --
  w_importo := 0;
  --
  if w_tipo_calcolo = 'S' then         -- Sbilancio
    begin
      FOR rec_sbil IN sel_sbil(p_cod_fiscale,p_ruolo,w_arrotondamento,w_applica_sgravi)
      LOOP
        if p_rata = 0 then
          w_importo := rec_sbil.sbil_totale;
          exit;
        else
          w_rata_num := rec_sbil.rata;
          if p_rata = w_rata_num then
            w_importo := rec_sbil.sbil_rata;
          end if;
        end if;
      END LOOP;
    exception
      when others then
        w_importo := 0;
    end;
  elsif w_tipo_calcolo = 'T' then      -- Rate TARES
    begin
      FOR rec_ratr IN sel_rtar(p_cod_fiscale,p_ruolo,w_arrotondamento,w_applica_sgravi)
      LOOP
        if p_rata = 0 then
          w_importo := rec_ratr.totale_tares - rec_ratr.totale_sgravi;
          exit;
        else
          w_rata_num := rec_ratr.rata;
          if p_rata = w_rata_num then
            w_importo := rec_ratr.maggiorazione_tares - rec_ratr.sgravio_tares;
          end if;
        end if;
      END LOOP;
    exception
      when others then
        w_importo := 0;
    end;
  else
    w_importo := 0;
  end if;
  --
  return w_importo;
  --
end;
/* End Function: F_SBILANCIO_TARES */
/
