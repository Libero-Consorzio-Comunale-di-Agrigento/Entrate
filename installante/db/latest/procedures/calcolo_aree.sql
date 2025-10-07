--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_aree stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_AREE
(
a_anno_rif              IN number,
a_cod_fiscale           IN varchar2,
a_oggetto_pratica       IN number,
a_valore                IN number,
a_valore_1s             IN number,
a_valore_d              IN number,
a_mesi_possesso         IN number,
a_mesi_possesso_1s      IN number,
a_perc_possesso         IN number,
a_tipo_aliquota         IN number,
a_aliquota_base         IN number,
a_aliquota_base_prec    IN number,
a_aliquota_base_erar    IN number,
a_utente                IN varchar2,
a_tipo_tributo          in varchar2
)
IS
w_errore               varchar2(200);
w_oggetto              number;
w_tipo_pratica         varchar2(1);
w_flag_calcolo         varchar2(1);
w_perc_acconto         number;
w_aree                 number;
w_aree_1s              number;
wd_aree                number;
wd_aree_1s             number;
w_aree_erar            number;
w_aree_erar_1s         number;
wd_aree_erar           number;
wd_aree_erar_1s        number;
w_perc_saldo                   number;
w_imposta_saldo                number;
w_imposta_saldo_erar           number;
w_note_saldo                   varchar2(200);
BEGIN
    if a_anno_rif > 2000 then
       w_perc_acconto := 100;
    else
       w_perc_acconto := 90;
    end if;
    BEGIN
       select ogpr.oggetto
             ,prtr.tipo_pratica
         into w_Oggetto
             ,w_tipo_pratica
         from oggetti_pratica  ogpr
             ,pratiche_tributo prtr
        where ogpr.oggetto_pratica = a_oggetto_pratica
          and prtr.pratica         = ogpr.pratica
       ;
    EXCEPTION
       WHEN OTHERS THEN
          rollback;
      RAISE_APPLICATION_ERROR (-20999,w_errore);
    END;
    if w_tipo_pratica = 'V' then
       w_flag_calcolo := null;
    else
       w_flag_calcolo := 'S';
    end if;
    w_aree := f_round(((((((a_valore
          * a_aliquota_base) / 1000)
          * a_perc_possesso) / 100)
          * a_mesi_possesso)  / 12),0);
    if a_anno_rif <= 2000 then
       w_aree_1s := f_round((((((((a_valore_1s
             * a_aliquota_base) / 1000)
             * a_perc_possesso) / 100)
             * a_mesi_possesso_1s)  / 12) * 0.9),0);
    else
       w_aree_1s := f_round(((((((a_valore_1s
             * a_aliquota_base_prec) / 1000)
             * a_perc_possesso) / 100)
             * a_mesi_possesso_1s)  / 12),0);
    end if;
    wd_aree := f_round(((((((a_valore_d
          * a_aliquota_base) / 1000)
          * a_perc_possesso) / 100)
          * a_mesi_possesso)  / 12),0);
    if a_anno_rif <= 2000 then
       wd_aree_1s := f_round((((((((a_valore_d
             * a_aliquota_base) / 1000)
             * a_perc_possesso) / 100)
             * a_mesi_possesso_1s)  / 12) * 0.9),0);
    else
       wd_aree_1s := f_round(((((((a_valore_d
             * a_aliquota_base_prec) / 1000)
             * a_perc_possesso) / 100)
             * a_mesi_possesso_1s)  / 12),0);
    end if;
    w_aree_erar := f_round(((((((a_valore
                               * a_aliquota_base_erar) / 1000)
                               * a_perc_possesso) / 100)
                               * a_mesi_possesso)  / 12),0);
    w_aree_erar_1s := f_round(((((((a_valore
                                  * a_aliquota_base_erar) / 1000)
                                  * a_perc_possesso) / 100)
                                  * a_mesi_possesso_1s)  / 12),0);
    wd_aree_erar := f_round(((((((a_valore_d
                               * a_aliquota_base_erar) / 1000)
                               * a_perc_possesso) / 100)
                               * a_mesi_possesso)  / 12),0);
    wd_aree_erar_1s := f_round(((((((a_valore_d
                                  * a_aliquota_base_erar) / 1000)
                                  * a_perc_possesso) / 100)
                                  * a_mesi_possesso_1s)  / 12),0);
    -- (VD - 23/10/2020): calcolo imposta a saldo (D.L. 14 agosto 2020)
    if a_tipo_tributo = 'ICI' then
       calcolo_imu_saldo ( a_tipo_tributo
                         , a_anno_rif
                         , a_tipo_aliquota
                         , nvl(w_aree,0)
                         , nvl(w_aree_1s,0)
                         , nvl(w_aree_erar,0)
                         , nvl(w_aree_erar_1s,0)
                         , w_perc_saldo
                         , w_imposta_saldo
                         , w_imposta_saldo_erar
                         , w_note_saldo
                         );
       if w_perc_saldo is not null then
          w_aree      := w_imposta_saldo;
          w_aree_erar := w_imposta_saldo_erar;
       end if;
    end if;
    BEGIN
       insert into oggetti_imposta
             (cod_fiscale,anno,oggetto_pratica
             ,imposta,imposta_acconto
             ,imposta_dovuta,imposta_dovuta_acconto
             ,imposta_erariale,imposta_erariale_acconto
             ,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
             ,tipo_aliquota,aliquota
             ,aliquota_erariale
             ,flag_calcolo,utente
             ,tipo_tributo,note)
       values(a_cod_fiscale,a_anno_rif,a_oggetto_pratica
             ,nvl(w_aree,0),nvl(w_aree_1s,0)
             ,nvl(wd_aree,0),nvl(wd_aree_1s,0)
             ,nvl(w_aree_erar,0),nvl(w_aree_erar_1s,0)
             ,nvl(wd_aree_erar,0),nvl(wd_aree_erar_1s,0)
             ,a_tipo_aliquota,a_aliquota_base
             ,a_aliquota_base_erar
             ,w_flag_calcolo,a_utente
             ,a_tipo_tributo,w_note_saldo)
      ;
    EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in inserimento Oggetti Imposta (Ar)';
         ROLLBACK;
      RAISE_APPLICATION_ERROR (-20999,w_errore);
    END;
END;
/* End Procedure: CALCOLO_AREE */
/

