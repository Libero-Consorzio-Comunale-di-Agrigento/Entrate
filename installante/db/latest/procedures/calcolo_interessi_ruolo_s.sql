--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_interessi_ruolo_s stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_INTERESSI_RUOLO_S
(a_ruolo          in number
,a_utente         in varchar2
,a_cod_fiscale    in varchar2
,a_dal            in date
,a_al             in date
) is
w_errore             varchar2(2000);
errore               exception;
CURSOR sel_ogpr_acce (p_tipo_tributo    varchar2
                     ,p_anno_ruolo      number
                     ,p_cod_istat       varchar2
                     ,p_addizionale_pro number
                     )
IS
select prtr.cod_fiscale
      ,prtr.pratica
      ,ogpr.oggetto_pratica
      ,sapr.cod_sanzione
      ,f_round(sum(sapr.importo * decode(sanz.cod_sanzione
                                        ,'1'  ,1
                                        ,'101',1
                                        ,'99' ,1
                                        ,'199',1
                                              ,decode(p_cod_istat
                                                     ,'036040',(100 + p_addizionale_pro) / 100
                                                              ,1
                                                     )
                                        )
                                * decode(prtr.flag_adesione
                                        ,null,1
                                             ,(100 - nvl(sanz.riduzione,0)) / 100
                                        )
                  ) , 1
               ) importo
  from codici_tributo      cotr
      ,sanzioni            sanz
      ,sanzioni_pratica    sapr
      ,oggetti_pratica     ogpr
      ,pratiche_tributo    prtr
 where cotr.tributo           = ogpr.tributo
   and cotr.flag_ruolo       is not null
   and sanz.cod_sanzione      = sapr.cod_sanzione
   and sanz.sequenza          = sapr.sequenza_sanz
   and sanz.tipo_tributo      = sapr.tipo_tributo
   and sapr.ruolo            is null
   and sapr.pratica           = prtr.pratica
   and ogpr.flag_contenzioso is null
   and ogpr.pratica           = prtr.pratica
   and (prtr.flag_adesione   is not null              or
        (sysdate - nvl(prtr.data_notifica,sysdate))
                              > 60
       )
   and prtr.tipo_tributo||''  = p_tipo_tributo
   and prtr.tipo_pratica||''  = 'A'
   and prtr.anno              = p_anno_ruolo
   and prtr.cod_fiscale    like a_cod_fiscale
   and sapr.cod_sanzione     in (101,100,1)
 group by
       prtr.cod_fiscale
      ,prtr.pratica
      ,ogpr.oggetto_pratica
      ,sapr.cod_sanzione
;
w_tipo_tributo           varchar2(5);
w_anno_ruolo             number(4);
w_invio_consorzio        date;
w_cod_istat              varchar2(6);
w_addizionale_pro        number(4,2);
BEGIN
   BEGIN
      select ruol.tipo_tributo
            ,ruol.anno_ruolo
            ,ruol.invio_consorzio
            ,lpad(to_char(dage.pro_cliente),3,'0')||
             lpad(to_char(dage.com_cliente),3,'0')
        into w_tipo_tributo
            ,w_anno_ruolo
            ,w_invio_consorzio
            ,w_cod_istat
        from ruoli         ruol
            ,dati_generali dage
       where ruol.ruolo    = a_ruolo
      ;
      if w_invio_consorzio is not null then
         w_errore := 'Ruolo '||to_char(a_ruolo)||' gia` inviato al consorzio in data '||
                     to_char(w_invio_consorzio,'dd/mm/yyyy');
         raise errore;
      end if;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Ruolo '||to_char(a_ruolo)||' non previsto nel dizionario RUOLI '||
                     'o Dati Generali non inseriti.';
         raise errore;
   END;
   BEGIN
      select nvl(cata.addizionale_pro,0)
        into w_addizionale_pro
        from carichi_tarsu      cata
       where cata.anno          = w_anno_ruolo
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_addizionale_pro := 0;
   END;
   FOR rec_ogpr_acce IN sel_ogpr_acce(w_tipo_tributo
                                     ,w_anno_ruolo
                                     ,w_cod_istat
                                     ,w_addizionale_pro
                                     )
   LOOP
      INSERIMENTO_INTERESSI_RUOLO_S(rec_ogpr_acce.pratica
                        ,rec_ogpr_acce.oggetto_pratica
                        ,rec_ogpr_acce.cod_sanzione
                        ,a_dal
                        ,a_al
                        ,rec_ogpr_acce.importo
                        ,w_tipo_tributo
                        ,'S'
                        ,a_utente
                        );
   END LOOP;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      raise_application_error(-20999,w_errore);
   WHEN OTHERS THEN
      rollback;
      raise_application_error(SQLCODE,SQLERRM);
END;
/* End Procedure: CALCOLO_INTERESSI_RUOLO_S */
/
