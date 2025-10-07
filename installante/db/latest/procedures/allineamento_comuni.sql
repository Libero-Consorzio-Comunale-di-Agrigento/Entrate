--liquibase formatted sql 
--changeset abrandolini:20250326_152423_allineamento_comuni stripComments:false runOnChange:true context:"TRG2 or TRV2"
 
create or replace procedure ALLINEAMENTO_COMUNI
IS
errore             exception;
w_errore           varchar2(4000);
nTestParametro     number := 0;
BEGIN
   BEGIN
      insert into ad4_stati_territori
           ( STATO_TERRITORIO
           , DENOMINAZIONE
           , SIGLA
           )
      select cod_provincia
           , descrizione
           , sigla_provincia
        from arccom com
       where com.cod_provincia > 199
         and com.cod_comune    = 0
         and not exists (select 'x'
                           from ad4_stati_territori ad4
                          where ad4.stato_territorio = com.cod_provincia
                        )
        ;
   EXCEPTION
      WHEN others THEN
         w_errore := SQLERRM||'Errore in allineamento ad4_stati_territori';
         RAISE errore;
   END;
   BEGIN
      insert into ad4_province
           ( PROVINCIA
           , DENOMINAZIONE
           )
      select COD_PROVINCIA
           , DESCRIZIONE
        from arcpro pro
       where pro.cod_provincia < 200
         and not exists (select 'x'
                           from ad4_province ad4
                          where ad4.provincia = pro.cod_provincia
                        )
        ;
   EXCEPTION
      WHEN others THEN
         w_errore := SQLERRM||'Errore in allineamento ad4_province';
         RAISE errore;
   END;
   BEGIN
      insert into ad4_comuni
           ( PROVINCIA_STATO
           , COMUNE
           , DENOMINAZIONE
           , DENOMINAZIONE_AL1
           , DENOMINAZIONE_AL2
           , DENOMINAZIONE_BREVE
           , DENOMINAZIONE_BREVE_AL1
           , DENOMINAZIONE_BREVE_AL2
           , CAP
           , PROVINCIA_TRIBUNALE
           , COMUNE_TRIBUNALE
           , SIGLA_CFIS
           , CONSOLATO
           , TIPO_CONSOLATO
           , DATA_SOPPRESSIONE
           , PROVINCIA_FUSIONE
           , COMUNE_FUSIONE
           )
      select COD_PROVINCIA
           , COD_COMUNE
           , DESCRIZIONE
           , substr(DESCRIZIONE_AL1,1,40)
           , substr(DESCRIZIONE_AL2,1,40)
           , substr(DESCRIZIONE,1,16)
           , substr(DESCRIZIONE_AL1,1,16)
           , substr(DESCRIZIONE_AL2,1,16)
           , CAP
           , substr(lpad(TRIBUNALE,6,0),1,3)
           , substr(lpad(TRIBUNALE,6,0),4,3)
           , CODICE_CATASTO
           , null                     --      COD_CONSOLATO
           , null                     --      TIPO_CONSOLATO
           , to_date(DATA_SOPPRESSIONE,'j')   -- DATA_SOPPRESSIONE
           , COD_PRO_FUSIONE                  -- COD_PRO_FUSIONE
           , COD_COM_FUSIONE                  -- COD_COM_FUSIONE
        from arccom com
       where not exists (select 'x'
                           from ad4_comuni ad4
                          where ad4.provincia_stato   = com.cod_provincia
                            and ad4.comune      = com.cod_comune
                        )
         and (  exists (select 'x'
                          from ad4_province ad4
                         where ad4.provincia = com.cod_provincia
                       )
             or
                exists (select 'x'
                          from ad4_stati_territori ad4
                         where ad4.stato_territorio = com.cod_provincia
                       )
             )
         and cod_provincia != 199
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := SQLERRM||'Errore in allineamento ad4_comuni';
           RAISE errore;
   END;
   BEGIN
      select count(1)
        into nTestParametro
        from installazione_parametri
       where parametro   = 'COMU_INS'
        ;
   EXCEPTION
      WHEN others THEN
         nTestParametro := 0;
   END;
   if nTestParametro > 0 then
      BEGIN
         update installazione_parametri
            set valore      = to_char(sysdate,'dd/mm/yyyy hh24:mi')
          where parametro   = 'COMU_INS'
           ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore aggiornamento Data Ultimo Allineamento';
            RAISE errore;
      END;
   else
      BEGIN
         insert into installazione_parametri
                 ( parametro
                 , valore
                 , descrizione
                 )
          values ( 'COMU_INS'
                 , to_char(sysdate,'dd/mm/yyyy hh24:mi')
                 , 'Data Ultimo Allineamento Comuni'
                 );
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore inserimento Data Ultimo Allineamento';
            RAISE errore;
      END;
   end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       w_errore := substr(w_errore,1,200);
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ALLINEAMENTO_COMUNI */
/

