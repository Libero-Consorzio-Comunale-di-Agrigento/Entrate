--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sanzioni_pratica_fi stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE SANZIONI_PRATICA_FI
(a_pratica_old		IN	number,
 a_pratica_new		IN	number,
 a_importo_old		IN 	number,
 a_importo_new		IN  number,
 a_riduzione_old	IN	number,
 a_riduzione_new	IN	number,
 a_riduzione_2_old	IN	number,
 a_riduzione_2_new	IN	number,
 a_cod_sanzione		IN	number,
 a_sequenza_sanz  IN  number)
/**
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   003   06/02/2025  RV      #77116 - Sanzione minima su riduzione
                             Aggiunto nuova gestione flag_sanz_min_rid di pratiche_tributo
   002   19/11/2024  AB      #75090 - Aggiunto il nuovo campo sequenza_sanz
   001   20/11/2023  RV      #65966 - Sanzione minima su riduzione
                             Aggiunto logica gestione
   000   xx/xx/xxxx  XX      Prima emissione
**/
IS
  --
  w_importo_totale	  number;
  w_importo_ridotto   number;
  w_importo_ridotto_2	number;
  --
  w_tipo_tributo      varchar(5);
  w_tipo_pratica      varchar(1);
  w_data_pratica      date;
  --
  w_sanz_min_rid      varchar2(1);
  w_sanz_min_dal      date;
  w_sanz_min_rid_prat varchar2(1);
  --
  w_sanz_ridotto_old	number;
  w_sanz_ridotto_new	number;
  w_sanz_imp_min      number;
  --
FUNCTION APPLICA_DELTA_SANZIONE
  ( a_importo         number,
    a_sanzione_old    number,
    a_sanzione_new    number,
    a_sanzione_min    number
  )
  return number
IS
  --
  w_sanzione_old     number;
  w_sanzione_new     number;
  --
  w_result           number;
  --
BEGIN
  --
  w_sanzione_old := a_sanzione_old;
  w_sanzione_new := a_sanzione_new;
  --
  if w_sanzione_old > 0 then
    if(w_sanzione_old < a_sanzione_min) then
      w_sanzione_old := a_sanzione_min;
    end if;
  end if;
  if w_sanzione_new > 0 then
    if(w_sanzione_new < a_sanzione_min) then
      w_sanzione_new := a_sanzione_min;
    end if;
  end if;
  --
  w_result := a_importo - f_round(w_sanzione_old,0) + f_round(w_sanzione_new,0);
  --
  return w_result;
  --
END APPLICA_DELTA_SANZIONE;
--
BEGIN
  --
  -- Legge dati base della pratica
  --
  BEGIN
    select nvl(importo_totale,0),nvl(importo_ridotto,0),nvl(importo_ridotto_2,0),
           tipo_tributo,tipo_pratica,data,nvl(flag_sanz_min_rid,'N')
      into w_importo_totale,w_importo_ridotto,w_importo_ridotto_2,w_tipo_tributo,
           w_tipo_pratica,w_data_pratica,w_sanz_min_rid_prat
      from pratiche_tributo
     where pratica = nvl(a_pratica_new,a_pratica_old)
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore ricerca Pratiche Tributo: '||nvl(a_pratica_new,a_pratica_old));
  END;
  --
  -- Senza sanzioni ? Aggiorna flag_sanz_min_rid della pratica
  --
  if w_importo_totale = 0 then
    if w_tipo_pratica in ('A', 'L') then
      --
      -- Leggo configurazione sanzione minima (Solo 'A' e 'L')
      --
      select
          case when length(inpa.sanz_min_rid) >= 12 then
            to_date(substr(inpa.sanz_min_rid,3,10),'dd/mm/yyyy')
          else
            to_date('01012023','ddmmyyyy')
          end sanz_min_dal
        , case when length(inpa.sanz_min_rid) > 0 then
            nvl(substr(inpa.sanz_min_rid,1,1),'N')
          else
            'N'
          end sanz_min_rid
          into w_sanz_min_dal, w_sanz_min_rid
      from (select f_inpa_valore('SANZ_MIN_R') sanz_min_rid from dual) inpa;
      --
      -- Determina flag per la pratica, quindi aggiorna
      --
      if nvl(w_sanz_min_rid,'N') = 'S' and w_data_pratica >= w_sanz_min_dal then
        w_sanz_min_rid_prat := 'S';
      else
        w_sanz_min_rid_prat := null;
      end if;
    else
      -- Ne 'A' ne 'L', sempre falso
      w_sanz_min_rid_prat := null;
    end if;
    --
    BEGIN
      update pratiche_tributo
         set flag_sanz_min_rid = w_sanz_min_rid_prat
       where pratica = nvl(a_pratica_new,a_pratica_old)
      ;
    EXCEPTION
      WHEN others THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Errore aggiornamento Pratiche Tributo (SANZ_MIN_RID): '||nvl(a_pratica_new,a_pratica_old));
    END;
    --
  end if;
  --
  -- Gestione pratica con sanzione minima
  --
  if nvl(w_sanz_min_rid_prat,'N') = 'S' then
    -- Ricava importo sanzione minima
    BEGIN
      select sanzione_minima
        into w_sanz_imp_min
        from sanzioni
       where tipo_tributo = w_tipo_tributo
         and cod_sanzione = a_cod_sanzione
         and sequenza     = a_sequenza_sanz;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        w_sanz_imp_min := null;
      WHEN others THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Errore ricerca Sanzione: '||w_tipo_tributo||'/'||a_cod_sanzione||'-'||a_sequenza_sanz);
    END;
  else
    w_sanz_imp_min := null;
  end if;
  --
  -- Applica
  --
  w_importo_totale  := w_importo_totale - nvl(a_importo_old,0) + nvl(a_importo_new,0);
  --
  w_sanz_ridotto_old := (nvl(a_importo_old,0) * (100 - nvl(a_riduzione_old,0)) /100);
  w_sanz_ridotto_new := (nvl(a_importo_new,0) * (100 - nvl(a_riduzione_new,0)) /100);
  if w_sanz_min_rid_prat = 'S' and w_sanz_imp_min is not null then
    w_importo_ridotto := APPLICA_DELTA_SANZIONE(w_importo_ridotto,w_sanz_ridotto_old,w_sanz_ridotto_new,w_sanz_imp_min);
  else
    w_importo_ridotto := w_importo_ridotto - f_round(w_sanz_ridotto_old,0) + f_round(w_sanz_ridotto_new,0);
  end if;
  --
  w_sanz_ridotto_old := (nvl(a_importo_old,0) * (100 - nvl(a_riduzione_2_old,0)) /100);
  w_sanz_ridotto_new := (nvl(a_importo_new,0) * (100 - nvl(a_riduzione_2_new,0)) /100);
  if w_sanz_min_rid_prat = 'S' and w_sanz_imp_min is not null then
    w_importo_ridotto_2 := APPLICA_DELTA_SANZIONE(w_importo_ridotto_2,w_sanz_ridotto_old,w_sanz_ridotto_new,w_sanz_imp_min);
  else
    w_importo_ridotto_2 := w_importo_ridotto_2 - f_round(w_sanz_ridotto_old,0) + f_round(w_sanz_ridotto_new,0);
  end if;
  --
  -- Questo serve per bonificare la situazione quando tolgo tutte le
  -- sanzioni dopo il cambio del flag sanzine minima su ridotto
  --
  -- #77116 : non dovrebbe più servire, ma non si sa mai sul pregresso
  --
  if w_importo_totale = 0 then
    w_importo_ridotto := 0;
    w_importo_ridotto_2 := 0;
  end if;
  --
  BEGIN
    update pratiche_tributo
       set importo_totale	= decode(a_cod_sanzione,889,importo_totale,w_importo_totale),
           importo_ridotto = decode(a_cod_sanzione,888,importo_ridotto,w_importo_ridotto),
           importo_ridotto_2 = decode(a_cod_sanzione,888,importo_ridotto_2,w_importo_ridotto_2)
     where pratica = nvl(a_pratica_new,a_pratica_old)
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore aggiornamento Pratiche Tributo (IMPORTI): '||nvl(a_pratica_new,a_pratica_old));
  END;
END;
/* End Procedure: SANZIONI_PRATICA_FI */
/
