--liquibase formatted sql 
--changeset abrandolini:20250326_152423_tras_tot_riscossioni stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     TRAS_TOT_RISCOSSIONI
(a_inizio_riscossione     in date
,a_fine_riscossione       in date
,a_anno                   in number
) is
nNum_Vers_Spontanei       number(8);
nNUm_Vers_Acconto         number(8);
nNum_Vers_Saldo           number(8);
nNum_Vers_Unico           number(8);
nImp_Vers_Spontanei       number(15);
nImp_Terreni              number(15);
nImp_Aree                 number(15);
nImp_Ab_Principale        number(15);
nImp_Altri_Fabbricati     number(15);
nImp_Detrazione           number(15);
nNum_Vers_Violazioni      number(8);
nImp_Vers_Violazioni      number(15);
nImposta                  number(15);
nSoprattassa              number(15);
nPena_Pecuniaria          number(15);
nInteressi                number(15);
nAnno                     number(4);
nCoeff                    number(3);
sComune                   varchar2(40);
sProvincia                varchar2(2);
sIstat                    varchar2(4);
nProgr                    number(4);
sDati                     varchar2(2000);
cursor sel_vers (p_inizio_riscossione in date
                ,p_fine_riscossione   in date
                ,p_anno               in number
                ,p_coeff              in number
                ) is
select nvl(sum(decode(vers.pratica,null,1
	                              ,decode(prtr.tipo_pratica
								         ,'V',1
										 ,0
										 )
					 )),0)                                                     num_vers_spontanei
      ,nvl(sum(decode(vers.pratica,null,decode(vers.tipo_versamento
	                                          ,'A',1
											  ,0
											  )
	                              ,decode(prtr.tipo_pratica
								          ,'V',decode(vers.tipo_versamento
										             ,'A',1
													 ,0
													 )
										  ,0
										  )
					 )),0)                                                     num_vers_acconto
      ,nvl(sum(decode(vers.pratica,null,decode(vers.tipo_versamento
	                                          ,'S',1
											  ,0
											  )
	                              ,decode(prtr.tipo_pratica
								          ,'V',decode(vers.tipo_versamento
										             ,'S',1
													 ,0
													 )
										  ,0
										  )
					 )),0)                                                     num_vers_saldo
      ,nvl(sum(decode(vers.pratica,null,decode(vers.tipo_versamento
	                                          ,'U',1
											  ,0
											  )
	                              ,decode(prtr.tipo_pratica
								          ,'V',decode(vers.tipo_versamento
										             ,'U',1
													 ,0
													 )
										  ,0
										  )
					 )),0)                                                     num_vers_unico
      ,nvl(sum(decode(vers.pratica,null,nvl(vers.importo_versato,0)
	                              ,decode(prtr.tipo_pratica
								         ,'V',nvl(vers.importo_versato,0)
										 ,0
										 )
			  )),0)                              * p_coeff                     imp_vers_spontanei
      ,nvl(sum(nvl(vers.terreni_agricoli,0)),0)  * p_coeff                     imp_terreni
      ,nvl(sum(nvl(vers.aree_fabbricabili,0)),0) * p_coeff                     imp_aree
      ,nvl(sum(nvl(vers.ab_principale,0)),0)     * p_coeff                     imp_ab_principale
      ,nvl(sum(nvl(vers.altri_fabbricati,0)),0)  * p_coeff                     imp_altri_fabbricati
      ,nvl(sum(nvl(vers.detrazione,0)),0)        * p_coeff                     imp_detrazione
      ,nvl(sum(decode(vers.pratica,null,0
	                              ,decode(prtr.tipo_pratica
								         ,'V',0
										 ,1
										 )
			         )),0)                                                     num_vers_violazioni
      ,nvl(sum(decode(vers.pratica,null,0
	                              ,decode(prtr.tipo_pratica
								         ,'V',0
										 ,nvl(vers.importo_versato,0)
										 )
					 )),0)                       * p_coeff                     imp_vers_violazioni
      ,vers.anno
  from versamenti           vers
     , pratiche_tributo     prtr
 where vers.pratica           = prtr.pratica (+)
   and vers.anno              = p_anno
 and nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                         between nvl(p_inizio_riscossione,to_date('01011900','ddmmyyyy'))
                             and nvl(p_fine_riscossione  ,to_date('31122999','ddmmyyyy'))
   and vers.tipo_tributo       = 'ICI'
 group by vers.anno
;
cursor sel_sapr (p_inizio_riscossione in date
                ,p_fine_riscossione   in date
                ,p_anno               in number
                ,p_coeff              in number
                ) is
select nvl(sum(decode(nvl(sanz.flag_imposta        ,'N')||
                      nvl(sanz.flag_interessi      ,'N')||
                      nvl(sanz.flag_pena_pecuniaria,'N')
                     ,'SNN',nvl(sapr.importo,0)
                           ,0
                     )
              ),0
          ) * p_coeff                                   imposta
      ,nvl(sum(decode(nvl(sanz.flag_imposta        ,'N')||
                      nvl(sanz.flag_interessi      ,'N')||
                      nvl(sanz.flag_pena_pecuniaria,'N')
                     ,'NNN',nvl(sapr.importo,0)
                           ,0
                     )
              ),0
          ) * p_coeff                                   soprattassa
      ,nvl(sum(decode(nvl(sanz.flag_imposta        ,'N')||
                      nvl(sanz.flag_interessi      ,'N')||
                      nvl(sanz.flag_pena_pecuniaria,'N')
                     ,'NNS',nvl(sapr.importo,0)
                           ,0
                     )
              ),0
          ) * p_coeff                                   pena_pecuniaria
      ,nvl(sum(decode(nvl(sanz.flag_imposta        ,'N')||
                      nvl(sanz.flag_interessi      ,'N')||
                      nvl(sanz.flag_pena_pecuniaria,'N')
                     ,'NSN',nvl(sapr.importo,0)
                           ,0
                     )
              ),0
          ) * p_coeff                                   interessi
  from sanzioni          sanz
      ,sanzioni_pratica  sapr
 where sapr.cod_sanzione                 = sanz.cod_sanzione
   and sapr.sequenza_sanz                = sanz.sequenza
   and sapr.tipo_tributo||''             = 'ICI'
   and sanz.tipo_tributo                 = sapr.tipo_tributo
   and exists
      (select 1
         from versamenti vers
        where vers.anno+0             = p_anno
          and nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                                between nvl(p_inizio_riscossione,to_date('01011900','ddmmyyyy'))
                                    and nvl(p_fine_riscossione  ,to_date('31122999','ddmmyyyy'))
          and vers.tipo_tributo||''   = sapr.tipo_tributo
          and vers.pratica            = sapr.pratica
      )
;
begin
   delete from wrk_tras_anci;
   nProgr := 0;
   begin
      select comu.denominazione
            ,prov.sigla
            ,comu.sigla_cfis
            ,decode(dage.fase_euro,1,1,100)
        into sComune
            ,sProvincia
            ,sIstat
            ,nCoeff
        from dati_generali dage
            ,ad4_comuni    comu
            ,ad4_provincie prov
       where prov.provincia       = dage.pro_cliente
         and comu.provincia_stato = dage.pro_cliente
         and comu.comune          = dage.com_cliente
      ;
   exception
      when no_data_found then
         rollback;
         raise_application_error(-20999,'Dati Generali o Dati Ente Non Presenti !!!');
   end;
   for rec_vers in sel_vers(a_inizio_riscossione,a_fine_riscossione,a_anno,nCoeff)
   loop
      nNum_Vers_Spontanei   := rec_vers.num_vers_spontanei;
      nNum_Vers_Acconto     := rec_vers.num_vers_acconto;
      nNum_Vers_Saldo       := rec_vers.num_vers_saldo;
      nNum_Vers_Unico       := rec_vers.num_vers_unico;
      nImp_Vers_Spontanei   := rec_vers.imp_vers_spontanei;
      nImp_Terreni          := rec_vers.imp_terreni;
      nImp_Aree             := rec_vers.imp_aree;
      nImp_Ab_Principale    := rec_vers.imp_ab_principale;
      nImp_Altri_Fabbricati := rec_vers.imp_altri_fabbricati;
      nImp_Detrazione       := rec_vers.imp_detrazione;
      nNum_Vers_Violazioni  := rec_vers.num_vers_violazioni;
      nImp_Vers_Violazioni  := rec_vers.imp_vers_violazioni;
      nAnno                 := rec_vers.anno;
      for rec_sapr in sel_sapr(a_inizio_riscossione,a_fine_riscossione,nAnno,nCoeff)
      loop
         nImposta           := rec_sapr.imposta;
         nSoprattassa       := rec_sapr.soprattassa;
         nPena_Pecuniaria   := rec_sapr.pena_pecuniaria;
         nInteressi         := rec_sapr.interessi;
         nProgr             := nProgr + 1;
         sDati := sComune||'|'||sProvincia||'|'||sIstat||'|'||
                  to_char(a_inizio_riscossione,'ddmmyyyy')||'|'||
                  to_char(a_fine_riscossione,'ddmmyyyy')||'|'||to_char(nAnno)||'|'||
                  to_char(nNum_Vers_Spontanei)||'|'||to_char(nNum_Vers_Acconto)||'|'||
                  to_char(nNum_Vers_Saldo)||'|'||to_char(nNum_Vers_Unico)||'|'||
                  to_char(nImp_Vers_Spontanei)||'|'||to_char(nImp_Terreni)||'|'||
                  to_char(nImp_Aree)||'|'||to_char(nImp_Ab_Principale)||'|'||
                  to_char(nImp_Altri_Fabbricati)||'|'||to_char(nImp_Detrazione)||'|'||
                  to_char(nNum_Vers_Violazioni)||'|'||to_char(nImp_Vers_Violazioni)||'|'||
                  to_char(nImposta)||'|'||to_char(nSoprattassa)||'|'||
                  to_char(nPena_Pecuniaria)||'|'||to_char(nInteressi);
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(a_anno,nProgr,sDati)
         ;
      end loop;
   end loop;
   commit;
exception
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||to_char(nProgr)||' - '||SQLERRM);
end;
/* End Procedure: TRAS_TOT_RISCOSSIONI */
/
