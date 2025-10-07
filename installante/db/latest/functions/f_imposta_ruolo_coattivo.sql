--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruolo_coattivo stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPOSTA_RUOLO_COATTIVO
/*************************************************************************
 NOME:        F_IMPOSTA_RUOLO_COATTIVO
 DESCRIZIONE: Dati ruolo coattivo, pratica e tributo, la funzione estrae
              la somma degli importi da SANZIONI_PRATICA
 PARAMETRI:   Pratica             Numero pratica
              Ruolo               Numero ruolo coattivo
              Tributo             Codice tributo da trattare
 RITORNA:     number              Totale imposta
 NOTE:
 Rev.    Date         Author      Note
 002     10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con sequenza
 001     14/10/2021   VD          Funzione utilizzata solo nella procedure
                                  TRASMISSIONE_RUOLO. Modificata selezione
                                  importi: occorre selezionare l'importo
                                  effettivamente andato a ruolo (e non
                                  l'importo calcolato).
 001     XX/XX/XXXX   XX          Prima emissione.
*************************************************************************/
(a_pratica   number
,a_ruolo     number
,a_tributo   number)
RETURN number
IS
   w_return number;
BEGIN
  BEGIN
   -- (VD - 14/10/2021): sostituito importo con importo_ruolo
   --                    perche' nel file 290 ci deve andare l'importo
   --                    effettivamente andato a ruolo (?)
   --select sum(importo)
   select sum(importo_ruolo)
     into w_return
     from pratiche_tributo    prtr,
          sanzioni_pratica    sapr,
          sanzioni            sanz
    where prtr.pratica          = a_pratica
      and sapr.pratica          = prtr.pratica
      and sapr.ruolo            = a_ruolo
      and sapr.tipo_tributo     = sanz.tipo_tributo
      and sapr.cod_sanzione     = sanz.cod_sanzione
      and sapr.sequenza_sanz    = sanz.sequenza
      and sanz.tributo          = a_tributo
   ;
  EXCEPTION
    WHEN others THEN
         w_return := 0;
  END;
  RETURN w_return;
END;
/* End Function: F_IMPOSTA_RUOLO_COATTIVO */
/
