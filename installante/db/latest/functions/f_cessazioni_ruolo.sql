--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cessazioni_ruolo stripComments:false runOnChange:true 
 
create or replace function F_CESSAZIONI_RUOLO
(A_COD_FISCALE          IN VARCHAR2
,A_OGGETTO_PRATICA      IN NUMBER
,A_ANNO                 IN NUMBER
) RETURN NUMBER
IS
nRisultato          number(6);
dInizio_Anno        date;
dFine_Anno          date;
nOgpr_Rif           number;
nMesi               number;
nMesi_R             number;
nTot_Mesi           number;
nTot_Mesi_R         number;
nSgravi             number;
nTot_Sgravi         number;
--
-- Selezione di tutto gli oggetti validi del contribuente indicato
-- aventi oggetto pratica di riferimento = quello relativo all''
-- oggetto pratica indicato e inerenti all'' anno indicato.
--
cursor sel_ogva (p_cod_fiscale     varchar2
                ,p_ogpr_rif        number
                ,p_inizio_anno     date
                ,p_fine_anno       date
                ) is
select ogva.oggetto_pratica                                       oggetto_pratica
      ,greatest(ogva.dal,p_inizio_anno)                           dal
      ,least(nvl(ogva.al,to_date('3333333','j')),p_fine_anno) + 1 al
  from oggetti_validita ogva
 where nvl(ogva.al,to_date('3333333','j')) >= p_inizio_anno
   and ogva.dal                            <= p_fine_anno
   and ogva.oggetto_pratica_rif             = p_ogpr_rif
   and ogva.cod_fiscale                     = p_cod_fiscale
;
BEGIN
   nRisultato   := 0;
   dInizio_Anno := to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   dFine_Anno   := to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   nTot_Mesi    := 0;
   nTot_Mesi_R  := 0;
   nTot_Sgravi  := 0;
--
-- Selezione oggetto pratica di riferimento
--
   BEGIN
      select distinct(ogpr.oggetto_pratica_rif)
        into nOgpr_Rif
        from oggetti_pratica ogpr
       where ogpr.oggetto_pratica  = a_oggetto_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20999,'Oggetto Pratica Non Valido.');
   END;
   FOR rec_ogva IN sel_ogva(a_cod_fiscale,nOgpr_Rif,dInizio_anno,dFine_anno) LOOP
--
-- Calcolo Mesi di Validità e Calcolo Mesi a Ruolo (solo se inviato) e Sgravi
--
       nMesi        := months_between(rec_ogva.al,rec_ogva.dal);
       nTot_Mesi    := nTot_Mesi + nMesi;
       BEGIN
          select nvl(sum(nvl(ruco.mesi_ruolo,0)),0)
                ,nvl(sum(decode(sgra.ruolo,null,0,1)),0)
            into nMesi_R
                ,nSgravi
            from oggetti_imposta     ogim
                ,sgravi              sgra
                ,ruoli               ruol
                ,ruoli_contribuente  ruco
           where ogim.cod_fiscale       = a_cod_fiscale
             and ogim.anno              = a_anno
             and ogim.oggetto_pratica   = rec_ogva.oggetto_pratica
             and ruco.cod_fiscale       = ogim.cod_fiscale
             and ruco.oggetto_imposta   = ogim.oggetto_imposta
             and ruco.ruolo             = ogim.ruolo
             and ruol.ruolo             = ruco.ruolo
             and ruol.invio_consorzio  is not null
             and sgra.cod_fiscale   (+) = ruco.cod_fiscale
             and sgra.ruolo         (+) = ruco.ruolo
             and sgra.sequenza      (+) = ruco.sequenza
             and (nvl(ruol.tipo_emissione,'X') != 'T' or
                  nvl(ruol.tipo_emissione,'X')  = 'T' and
                  ruol.ruolo = f_get_ultimo_ruolo (a_cod_fiscale,a_anno,ruol.tipo_tributo,ruol.tipo_emissione))
          ;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             nMesi_R := 0;
             nSgravi := 0;
       END;
       nTot_Mesi_R  := nTot_Mesi_R + nMesi_R;
       nTot_Sgravi  := nTot_Sgravi + nSgravi;
   END LOOP;
--
-- nRisultato che viene restituito dalla funzione contiene nelle ultime
-- 2 cifre il numero di mesi a Ruolo, le penultime 2 cifre i Mesi di validita''
-- mentre nelle cifre piu'' significative contiene il numero di sgravi.
--
   nRisultato := nTot_Sgravi * 10000 + nTot_Mesi * 100 + nTot_Mesi_R;
   RETURN nRisultato;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(SQLCODE,SQLERRM);
END;
/* End Function: F_CESSAZIONI_RUOLO */
/

