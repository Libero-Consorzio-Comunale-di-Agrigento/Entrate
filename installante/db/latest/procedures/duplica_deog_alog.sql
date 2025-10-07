--liquibase formatted sql 
--changeset abrandolini:20250326_152423_duplica_deog_alog stripComments:false runOnChange:true 
 
create or replace procedure DUPLICA_DEOG_ALOG
      ( a_cod_fiscale IN varchar2
      , a_ogpr_old    IN number
      , a_ogpr_new    IN number )
    IS
    w_errore         varchar2(2000);
    errore           exception;
CURSOR sel_deog
     ( p_cod_fiscale varchar2
     , p_ogpr_old    number ) IS
select deog.cod_fiscale
      ,deog.anno
      ,deog.detrazione
      ,deog.detrazione_acconto
      ,deog.motivo_detrazione
      ,deog.note
      ,deog.tipo_tributo
  from detrazioni_ogco deog
 where deog.cod_fiscale     = p_cod_fiscale
   and deog.oggetto_pratica = p_ogpr_old
     ;
CURSOR sel_alog
     ( p_cod_fiscale varchar2
     , p_ogpr_old    number ) IS
select alog.cod_fiscale
      ,alog.dal
      ,alog.al
      ,alog.tipo_aliquota
      ,alog.note
      ,alog.tipo_tributo
  from aliquote_ogco alog
 where alog.cod_fiscale     = p_cod_fiscale
   and alog.oggetto_pratica = p_ogpr_old
     ;
BEGIN
  FOR rec_deog IN sel_deog (a_cod_fiscale, a_ogpr_old)
  LOOP
    BEGIN
      insert into detrazioni_ogco
            ( cod_fiscale, oggetto_pratica
            , anno, motivo_detrazione
            , detrazione, detrazione_acconto
            , note, tipo_tributo )
     values ( rec_deog.cod_fiscale, a_ogpr_new
            , rec_deog.anno, rec_deog.motivo_detrazione
            , rec_deog.detrazione, rec_deog.detrazione_acconto
            , rec_deog.note, rec_deog.tipo_tributo );
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento detrazioni_ogco '||
                    ' per '||rec_deog.cod_fiscale||' - ('||SQLERRM||')';
        RAISE errore;
    END;
  END LOOP;
  FOR rec_alog IN sel_alog (a_cod_fiscale, a_ogpr_old)
  LOOP
    BEGIN
      insert into aliquote_ogco
            (cod_fiscale, oggetto_pratica, dal, al, tipo_aliquota, note, tipo_tributo )
      values (rec_alog.cod_fiscale, a_ogpr_new, rec_alog.dal, rec_alog.al, rec_alog.tipo_aliquota, rec_alog.note
      , rec_alog.tipo_tributo );
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento aliquote_ogco '||
                    ' per '||rec_alog.cod_fiscale||' - ('||SQLERRM||')';
        RAISE errore;
    END;
  END LOOP;
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Duplica Aliquote e Detrazioni Oggetto - ('||SQLERRM||')');
END;
/* End Procedure: DUPLICA_DEOG_ALOG */
/

