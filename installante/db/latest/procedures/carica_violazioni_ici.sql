--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_violazioni_ici stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VIOLAZIONI_ICI
(a_cf          IN varchar2
,a_nome        IN varchar2
) is
sAzione          varchar2(50);
sCod_Fiscale     varchar2(16);
w_100            number;
w_vers_presente  number;
cursor sel_violazioni (p_cf varchar2,p_nome varchar2) is
select anve.progr_record
      ,ltrim(anve.cod_fiscale) cod_fiscale
      ,anve.data_versamento data_versamento
      ,ltrim(anve.importo_versato,0) importo_versato
      ,ltrim(anve.imposta,0) imposta
      ,ltrim(anve.sanzioni_1,0) sanzioni_1
      ,ltrim(anve.sanzioni_2,0) sanzioni_2
      ,ltrim(anve.interessi,0) interessi
      ,anve.flag_quadratura
      ,anve.flag_squadratura
-- MODIFICATO A SEGUITO DELLA SEGNALAZIONE DI MEDICINA IN MODO DA GESTIRE LE VIOLAZIONI
-- CON ANNO_FISCALE ZERO
      ,decode(sign(nvl(ltrim(anve.anno_fiscale,0),prtr.anno) - 1998),-1,
         decode(anve.tipo_versamento,1,'A',2,'S',3,'U'),
           decode(anve.tipo_versamento,1,'A',2,'S',3,'U',
             decode(sign(anve.data_versamento -
                         nvl(scad.data_scadenza,to_date('01011900','ddmmyyyy'))
                        )
                   ,1,'S','A'))) tipo_versamento
      ,decode(anve.data_reg
             ,0,trunc(sysdate)
             ,nvl(to_date(to_char(anve.data_reg),'yyyymmdd'),trunc(sysdate))
             )                   data_reg
      ,anve.flag_competenza_ver
      ,ltrim(anve.comune,' ') comune
      ,anve.cap
      ,anve.flag_identificazione
      ,nvl(ltrim(anve.anno_fiscale,0),prtr.anno) anno_fiscale
      ,ltrim(anve.num_provvedimento,'0') num_provvedimento
      ,anve.data_provvedimento           data_provvedimento
      ,ltrim(anve.flag_zero,' ') flag_zero
      ,decode(cont.cod_fiscale,null,52,decode(prtr.pratica,null,53,null)) anomalia
      ,prtr.pratica
      ,scad.data_scadenza
      ,nvl(anve.fonte,2)                   fonte
  from pratiche_tributo    prtr
      ,contribuenti        cont
      ,scadenze            scad
      ,anci_ver            anve
 where anve.tipo_record           = 6
-- MODIFICATO A SEGUITO DELLA SEGNALAZIONE DI MEDICINA IN MODO DA GESTIRE LE VIOLAZIONI
-- CON ANNO_FISCALE ZERO
   and nvl(prtr.anno  ,-1)        = nvl(nvl(ltrim(to_char(anve.anno_fiscale),'0'),prtr.anno),-1)
   and nvl(prtr.numero (+),' ')   = ltrim(anve.num_provvedimento,'0')
   and nvl(prtr.stato_accertamento, 'D')  = 'D'
   and prtr.data              (+) = anve.data_provvedimento
   and cont.cod_fiscale       (+) = ltrim(anve.cod_fiscale)
   and scad.tipo_scadenza     (+) = 'V'
   and scad.tipo_versamento   (+) = 'A'
   and scad.anno              (+) = ltrim(anve.anno_fiscale,0)
;
cursor sel_anan is
select distinct
       anve.tipo_anomalia tipo_anomalia
      ,anve.anno_fiscale  anno
      ,anan.anno          anno_diz
  from anci_ver       anve
      ,anomalie_anno  anan
 where anan.anno           (+) = ltrim(anve.anno_fiscale,'0')
   and anan.tipo_anomalia  (+) = anve.tipo_anomalia
   and anve.tipo_record        = 6
   and ltrim(anve.anno_fiscale,'0') is not null
   and anve.tipo_anomalia     is not null
;
begin
   begin
      select decode(fase_euro,1,1,100)
        into w_100
        from dati_generali
      ;
   exception
      when no_data_found then
         w_100 := 1;
   end;
   for rec_v in sel_violazioni (a_cf,a_nome)
   loop
      begin
         select count(1)
           into w_vers_presente
           from versamenti vers
          where vers.cod_fiscale     = rec_v.cod_fiscale
            and nvl(vers.pratica,0)  = nvl(rec_v.pratica,0)
            and vers.anno + 0        = rec_v.anno_fiscale
            and vers.tipo_versamento = rec_v.tipo_versamento
            and vers.data_pagamento  = rec_v.data_versamento
            and vers.importo_versato = rec_v.importo_versato / w_100
            ;
      exception
         when others then
            w_vers_presente := 1;
      end;
      if w_vers_presente = 0 then  -- versamento non presente
         sCod_Fiscale := rec_v.cod_fiscale;
         begin
            if rec_v.anomalia is null then
               sAzione := 'Ins. '||to_char(rec_v.pratica);
               insert into versamenti
                     (cod_fiscale,anno,tipo_tributo,pratica,
                      tipo_versamento,data_pagamento,
                      progr_anci,fonte,utente,data_variazione,
                      data_reg,importo_versato,
                      imposta,sanzioni_1,sanzioni_2,interessi
                     )
               values(rec_v.cod_fiscale,rec_v.anno_fiscale,'ICI',rec_v.pratica,
                      rec_v.tipo_versamento,rec_v.data_versamento,
                      rec_v.progr_record,rec_v.fonte,'TR4',rec_v.data_reg,
                      rec_v.data_reg,rec_v.importo_versato / w_100,
                      rec_v.imposta / w_100,rec_v.sanzioni_1 / w_100,
                      rec_v.sanzioni_2 / w_100,rec_v.interessi / w_100
                     )
               ;
               sAzione := 'Del.';
               delete from anci_ver
                where ( anno_fiscale           = nvl(rec_v.anno_fiscale,0)
                        or   ltrim(anno_fiscale,0) is null )
                  and nvl(progr_record,0)    = nvl(rec_v.progr_record,0)
                  and tipo_record            = 6
               ;
            else
               sAzione := 'Upd.';
               update anci_ver
                  set tipo_anomalia          = rec_v.anomalia
                where ( anno_fiscale           = nvl(rec_v.anno_fiscale,0)
                       or   ltrim(anno_fiscale,0) is null )
                  and nvl(progr_record,0)    = nvl(rec_v.progr_record,0)
                  and tipo_record            = 6
               ;
            end if;
         --      exception
         --         when others then
         --            dbms_output.put_line(sCod_Fiscale||' '||sAzione||' '||SQLERRM);
         end;
      end if;
   end loop;
   for rec_anan in sel_anan
   loop
      if rec_anan.anno_diz is null then
         sAzione := 'Anan ';
         insert into anomalie_anno
               (tipo_anomalia,anno,data_elaborazione)
         values(rec_anan.tipo_anomalia,rec_anan.anno,sysdate)
         ;
      else
         update anomalie_anno
            set data_elaborazione = sysdate
          where tipo_anomalia     = rec_anan.tipo_anomalia
            and anno              = rec_anan.anno
         ;
      end if;
   end loop;
exception
   when others then
      rollback;
      raise_application_error(-20999,'fine: '||sAzione||' '||sCod_Fiscale||' '||
                                     to_char(SQLCODE)||' - '||
                                     SQLERRM);
end;
/* End Procedure: CARICA_VIOLAZIONI_ICI */
/

