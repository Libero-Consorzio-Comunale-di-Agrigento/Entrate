--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiorna_perc_detrazione stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNA_PERC_DETRAZIONE
(a_cod_fiscale  varchar2
,a_tipo_oggetto number
,a_fonte        number)
is
-- 14/10/2014 Betta T. Aggiunti (e gestiti) parametri
cursor sel_ogco is
 select ogco.note
      , ogco.cod_fiscale
      , ogco.oggetto_pratica
      , to_number(substr(ogco.note,instr(ogco.note,'Pratica:') + 9, instr(ogco.note,'Ogpr:') - instr(ogco.note,'Pratica:') - 10))  pratica_prov
      , to_number(substr(ogco.note,instr(ogco.note,'Ogpr:') + 6))     ogpr_prov
   from oggetti_contribuente ogco
      , oggetti_pratica      ogpr
      , pratiche_tributo     prtr
      , oggetti              ogge
  where instr(ogco.note,'Pratica:') >0
    and ogco.utente = 'ITASI'
    and ogco.detrazione is not null
    and ogpr.oggetto_pratica = ogco.oggetto_pratica
    and ogpr.pratica = prtr.pratica
    and prtr.tipo_tributo||'' = 'TASI'
    and prtr.anno = 2014
    and ogco.cod_fiscale      like a_cod_fiscale
    and ogpr.fonte            = a_fonte
    and ogpr.oggetto          = ogge.oggetto
    and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = nvl(a_tipo_oggetto,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto))
    --and ogco.note not like '%Recupero Perc_Detrazione%'
--    and ogco.cod_fiscale = 'BRNDNL69D58G843G'
   ;
   w_conta_oggetti            number := 0;
   w_detrazione_imu           number;
   w_anno_pratica_imu         number;
   w_detrazione_base_imu      number;
   w_perc_detrazione          number;
BEGIN
   FOR rec_ogco IN sel_ogco LOOP
     -- recupero dati della pratica IMU --
      begin
         select prtr.anno
              , round(decode(nvl(ogco.mesi_possesso,12)
                            ,0,0
                            ,nvl(ogco.detrazione,0) / nvl(ogco.mesi_possesso,12) * 12
                            ),2)                     detrazione
           into w_anno_pratica_imu
              , w_detrazione_imu
           from oggetti_contribuente  ogco
              , oggetti_pratica       ogpr
              , pratiche_tributo      prtr
          where ogpr.oggetto_pratica  = ogco.oggetto_pratica
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = 'ICI'
            and ogpr.oggetto_pratica  = rec_ogco.ogpr_prov
            and ogco.cod_fiscale      = rec_ogco.cod_fiscale
              ;
      exception
         when no_data_found then
           w_anno_pratica_imu := 0;
         when others then
           raise_application_error(-20919,'Errore recupero dati della pratica IMU '
                                          ||rec_ogco.pratica_prov||' OGPR '||rec_ogco.ogpr_prov
                                        ||' ('||sqlerrm||')');
      end;
      if w_anno_pratica_imu = 0 then
         w_detrazione_base_imu := 0;
         w_perc_detrazione := 0;
      else
          -- Recupero detrazione base ICI per l'anno della denuncia originale
          begin
             select detrazione_base
               into w_detrazione_base_imu
               from detrazioni
              where anno         = w_anno_pratica_imu
                and tipo_tributo = 'ICI'
              ;
          exception
             when others then
                w_detrazione_base_imu := 0;
--                  raise_application_error(-20919,'Errore recupero detrazione base IMU anno '||to_char(w_anno_pratica_imu)
--                                                 ||' ('||sqlerrm||')');
          end;
          -- Calcolo Percentuale detrazione
          if w_detrazione_base_imu = 0 then
             w_perc_detrazione := 0;
          else
             w_perc_detrazione := round(w_detrazione_imu / w_detrazione_base_imu * 100,2);
          end if;
      end if;
      begin
         update oggetti_contribuente
            set perc_detrazione  = w_perc_detrazione
          where oggetto_pratica  = rec_ogco.oggetto_pratica
            and cod_fiscale      = rec_ogco.cod_fiscale
              ;
      exception
         when others then
           raise_application_error(-20919,'Errore aggiornamento OgCo '||rec_ogco.cod_fiscale||' - '||to_char(rec_ogco.oggetto_pratica)
                                        ||' ('||sqlerrm||')');
      end;
       w_conta_oggetti := w_conta_oggetti + 1;
   end loop;
--  dbms_output.put_line ('Oggetti Modificati: '||to_char(w_conta_oggetti));
EXCEPTION
  WHEN others THEN
    rollback;
    RAISE_APPLICATION_ERROR(-20919,'Errore generico '||
                                   ' ('||sqlerrm||')');
END;
/* End Procedure: AGGIORNA_PERC_DETRAZIONE */
/

