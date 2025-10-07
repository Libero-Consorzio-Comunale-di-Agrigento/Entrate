--liquibase formatted sql 
--changeset abrandolini:20250326_152423_contribuenti_chk_del stripComments:false runOnChange:true 
 
--	DATA	: 20/09/1998
--	Modificata il 27/07/2000: Sistemato il problema dell'IntegrityPackage.NextLevel

create or replace procedure CONTRIBUENTI_CHK_DEL
(a_cod_fiscale   IN varchar2,
 a_pratica   IN number)
IS
w_cod_fiscale   varchar2(16);
w_controllo   varchar2(1);
w_found      boolean;
sql_errm   varchar2(100);
CURSOR sel_cf IS
       select cod_fiscale
         from rapporti_tributo
        where pratica = a_pratica
       ;
CURSOR sel_chk IS
       select 'x'
    from dual
   where not exists (select 'x'
             from rapporti_tributo ratr
            where ratr.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from ruoli_contribuente ruco
            where ruco.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from maggiori_detrazioni made
            where made.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from versamenti vers
            where vers.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from contatti_contribuente coco
            where coco.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from rate_imposta raim
            where raim.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from documenti_contribuente doco
            where doco.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from conferimenti conf
            where conf.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from conferimenti_cer coce
            where coce.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from stati_contribuente stco
            where stco.cod_fiscale = w_cod_fiscale)
     and not exists (select 'x'
             from codici_rfid corf
            where corf.cod_fiscale = w_cod_fiscale)
       ;
BEGIN
  IF a_cod_fiscale is null THEN
    FOR rec_cf IN sel_cf LOOP
      BEGIN
        delete rapporti_tributo
         where pratica     = a_pratica
           and cod_fiscale = rec_cf.cod_fiscale
        ;
      EXCEPTION
        WHEN others THEN
        sql_errm := substr(SQLERRM,1,100);
        RAISE_APPLICATION_ERROR
          (-20999,'Errore in eliminazione Rapporti Tributo '||
           '('||sqlerrm||')');
      END;
      BEGIN
        delete sto_rapporti_tributo
         where pratica     = a_pratica
           and cod_fiscale = rec_cf.cod_fiscale
        ;
      EXCEPTION
        WHEN others THEN
        sql_errm := substr(SQLERRM,1,100);
        RAISE_APPLICATION_ERROR
          (-20999,'Errore in eliminazione Storico Rapporti Tributo '||
           '('||sqlerrm||')');
      END;
      w_cod_fiscale := rec_cf.cod_fiscale;
      OPEN  sel_chk;
      FETCH sel_chk INTO w_controllo;
      w_found := sel_chk%FOUND;
      CLOSE sel_chk;
      IF w_found THEN
         BEGIN
          IntegrityPackage.NextNestLevel;
           delete contribuenti
            where cod_fiscale = w_cod_fiscale
           ;
          IntegrityPackage.PreviousNestLevel;
         EXCEPTION
           WHEN others THEN
               IntegrityPackage.PreviousNestLevel;
            sql_errm := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in eliminazione Contribuenti '||
              '('||sqlerrm||')');
         END;
      END IF;
    END LOOP;
  ELSE
    w_cod_fiscale := a_cod_fiscale;
    OPEN  sel_chk;
    FETCH sel_chk INTO w_controllo;
    w_found := sel_chk%FOUND;
    CLOSE sel_chk;
    IF w_found THEN
       BEGIN
        IntegrityPackage.NextNestLevel;
         delete contribuenti
          where cod_fiscale = w_cod_fiscale
         ;
        IntegrityPackage.PreviousNestLevel;
       EXCEPTION
         WHEN others THEN
             IntegrityPackage.PreviousNestLevel;
          sql_errm := substr(SQLERRM,1,100);
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in eliminazione Contribuenti '||
              '('||sqlerrm||')');
       END;
    END IF;
  END IF;
END;
/* End Procedure: CONTRIBUENTI_CHK_DEL */
/
