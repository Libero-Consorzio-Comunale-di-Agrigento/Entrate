--liquibase formatted sql 
--changeset abrandolini:20250326_152423_duplica_faso_cont stripComments:false runOnChange:true 
 
create or replace procedure DUPLICA_FASO_CONT
(a_anno           IN NUMBER,
 a_dal            IN DATE,
 a_anno_dup       IN NUMBER
) IS
 w_dal             DATE;
 w_errno           NUMBER;
 impossibile_agg   EXCEPTION;
 no_residente      EXCEPTION;
 no_familiari      EXCEPTION;
  CURSOR sel_faso IS
  select faso1.ni ni
      , decode(to_number(to_char(sysdate,'yyyy')),a_anno , null
                 ,to_date('31/12/'||to_char(a_anno),'dd/mm/yyyy')
            ) al
      , faso1.numero_familiari num_fam
   from familiari_soggetto faso1
      , soggetti sogg
  where faso1.ni = sogg.ni
    and sogg.tipo_residente = 1
   and faso1.anno = a_anno_dup
   and not exists ( select faso2.ni
                      from familiari_soggetto faso2
                 where faso2.ni   = faso1.ni
                   and faso2.anno = a_anno )
   and faso1.dal = (select max(faso3.dal)
                      from familiari_soggetto faso3
                 where faso3.ni   = faso1.ni
                   and faso3.anno = a_anno_dup)
   ;
BEGIN
   FOR rec_faso IN sel_faso LOOP
       BEGIN
          INSERT INTO FAMILIARI_SOGGETTO
                (NI, ANNO, DAL,
             AL, NUMERO_FAMILIARI,
             DATA_VARIAZIONE,NOTE)
          VALUES (rec_faso.ni, a_anno, a_dal,
                rec_faso.al, rec_faso.num_fam,
              trunc(sysdate), 'INSERIMENTO AUTOMATICO DA DUPLICA PER ANNO')
          ;
       EXCEPTION
          WHEN others THEN
             RAISE_APPLICATION_ERROR
             (-20999,'Errore in Inserimento Familiari Soggetto: ni = '||to_char(rec_faso.ni)||
             ' ('||SQLERRM||')');
       END;
    END LOOP;
END;
/* End Procedure: DUPLICA_FASO_CONT */
/

