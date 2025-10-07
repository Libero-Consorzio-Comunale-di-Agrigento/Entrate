--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_icp_f24 stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_ICP_F24
/*************************************************************************
 NOME:        ESTRAZIONE_ICP_F24
 DESCRIZIONE: Estrazione dati ICP comprensivi di F24 per invio massivo
              comunicazioni
 NOTE:        Personalizzazioni:
              048033 - Pontassieve (* se cod. abi = 07601)
              048010 - Castelfiorentino (tratta solo il codice tributo 453)
 Rev.    Date         Author      Note
 000     15/03/2018   VD          Prima emissione.
*************************************************************************/
( a_anno                          in number
, a_scelta_anno                   in varchar2
, a_tipo_contribuente             in varchar2
, a_num_righe                     out number
, a_num_contribuenti              out number
, a_totale_imposta                out number
) is
w_tipo_tributo               varchar2(5) := 'ICP';
w_intestazione               varchar2(4000);
w_intest_prima               varchar2(2000);
w_intest_terza               varchar2(2000);
i                            number;
r                            number;
w_max_rate                   number;
w_num_max_utenze             number;
w_importo_contr              number;
w_importo_totale_complessivo number;
w_numero_rate                number;
w_importo_rata_0             number;
w_importo_rata_1             number;
w_importo_rata_2             number;
w_importo_rata_3             number;
w_importo_rata_4             number;
w_scadenza_rata_0            varchar2(10);
w_scadenza_rata_1            varchar2(10);
w_scadenza_rata_2            varchar2(10);
w_scadenza_rata_3            varchar2(10);
w_scadenza_rata_4            varchar2(10);
w_vcampot                    varchar2(17);
w_vcampo1                    varchar2(17);
w_vcampo2                    varchar2(17);
w_vcampo3                    varchar2(17);
w_vcampo4                    varchar2(17);
w_progr_wrk                  number;
w_riga_wrk                   varchar2(32767);
w_flag_canone                varchar2(1);
w_istat                      varchar2(6);
w_comune                     varchar2(100);
w_cod_belfiore               varchar2(4);
w_tributo                    number;
w_conto_corrente             number;
--Gestione delle eccezioni
w_errore                     varchar2(2000);
w_err_par                    varchar2(50);
errore                       exception;
w_cont_da_trattare           number;
w_max_utenze                 number;
w_conta_utenze               number;
w_conta_rate                 number;
w_riga_rata                  varchar2(2000);
w_riga_causale               varchar2(2000);
w_riga_rateaz                varchar2(2000);
w_riga_f24                   varchar2(32767);
w_riga_var                   varchar2(32767);
w_dati                       varchar2(4000);
w_dati2                      varchar2(4000);
w_dati3                      varchar2(4000);
w_dati4                      varchar2(4000);
w_dati5                      varchar2(4000);
w_dati6                      varchar2(4000);
w_dati7                      varchar2(4000);
w_dati8                      varchar2(4000);
--
-- Selezione dei contribuenti da trattare
--
cursor sel_cont (c_anno number, c_istat varchar2, c_tributo number, c_scelta_anno varchar2) is
select max(substr(
             decode(sogg.ni_presso
                   ,null,
                   decode(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR')
                         ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                         ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                          ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                          )
                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario1
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR')
                            ,replace(replace(sogg.cognome_nome,'/',' '),';',','))
                   ,'c/o '||replace(replace(sogP.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario2
           decode(sogg.ni_presso
                 ,null,substr(nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate))
                                 ,decode(sogg.cod_via
                                        ,to_number(null),sogg.denominazione_via
                                        ,arvi.denom_uff
                                        )
                                  ||' '||to_char(sogg.num_civ)
                                  ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                                  ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                                  ||decode(sogg.piano,'','',' P.'||sogg.piano)
                                  ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                 )
                             ,1,44)||';'
                 ,substr(decode(sogP.cod_via
                               ,to_number(null),sogP.denominazione_via
                               ,arvP.denom_uff
                               )
                          ||' '||to_char(sogP.num_civ)
                          ||decode(sogP.suffisso,'','','/'||sogP.suffisso)
                          ||decode(sogP.scala,'','',' Sc.'||sogP.scala)
                          ||decode(sogP.piano,'','',' P.'||sogP.piano)
                          ||decode(sogP.interno,'','',' Int.'||sogP.interno)
                        ,1,44)||';'
                 )||                                                                              -- Rigadestinatario3
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'CC')
                            ,lpad(to_char(nvl(sogg.cap,comR.cap)),5,'0')||' '
                             ||substr(comR.denominazione,1,30)||' '
                             ||substr(proR.sigla,1,2)
                            )
                   ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
                    ||substr(comP.denominazione,1,30)||' '
                    ||substr(proP.sigla,1,2)
                   )
                  ,1,44)||';'||                                                                  -- Rigadestinatario4
         decode(sogg.ni_presso
               ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'SE')
                        ,sttR.denominazione
                        )
               ,sttP.denominazione
               )||';'||                                                                          -- Estero
         substr(replace(replace(sogg.cognome_nome,'/',' '),';',','),1,37)||
         ';'||                                                                                   -- NOME1
         substr(decode(sogg.cod_via,
                        to_number(null),sogg.denominazione_via,
                        arvi.denom_uff)
                ||' '||to_char(sogg.num_civ)
                     ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                     ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                     ||decode(sogg.piano,'','',' P.'||sogg.piano)
                     ||decode(sogg.interno,'','',' Int.'||sogg.interno),1,44)||';'||             -- INDIR
         lpad(nvl(to_char(nvl(sogg.cap,nvl(comR.cap,0))),''),5,'0')|| ';'||                      -- CAP
         nvl(substr(comR.denominazione,1,30),'') || ';'||                                        -- DEST (città del versante)
         nvl(substr(proR.sigla,1,2),'') || ';'||                                                 -- PROVincia
         'N;'||                                                                                  -- IBAN
         decode(c_istat
               ,'048033',decode(nvl(deba.cod_abi,0)    -- Pontassieve
                               ,07601, '*'
                               ,''
                               )
               ,''
               )  || ';'||                                                                        -- Domiciliazione bancaria postale
          'COD.UT.: '||to_char(sogg.ni)||' C.F. P.IVA: '||cont.cod_fiscale||';'||                 -- VAR01D
          'C.F. P.IVA: '||cont.cod_fiscale||';'                                                   -- VAR02S
          )                                              prima_parte
     , max(sogg.ni)                              ni
     , max(replace(sogg.cognome_nome,'/',' '))   cognome_nome
     , cont.cod_fiscale                          cod_fiscale
  from ad4_provincie        proR
     , ad4_comuni           comR
     , ad4_stati_territori  sttR
     , ad4_provincie        proP
     , ad4_comuni           comP
     , ad4_stati_territori  sttP
     , archivio_vie         arvi
     , archivio_vie         arvP
     , soggetti             sogg
     , soggetti             sogP
     , contribuenti         cont
     , deleghe_bancarie     deba
     , oggetti_imposta      ogim
     , oggetti_pratica      ogpr
     , pratiche_tributo     prtr
 where proR.provincia            (+)   = sogg.cod_pro_res
   and comR.provincia_stato      (+)   = sogg.cod_pro_res
   and comR.comune               (+)   = sogg.cod_com_res
   and sttR.stato_territorio     (+)   = sogg.cod_pro_res
   and proP.provincia            (+)   = sogP.cod_pro_res
   and comP.provincia_stato      (+)   = sogP.cod_pro_res
   and comP.comune               (+)   = sogP.cod_com_res
   and sttP.stato_territorio     (+)   = sogP.cod_pro_res
   and arvi.cod_via              (+)   = sogg.cod_via
   and arvP.cod_via              (+)   = sogP.cod_via
   and sogP.ni                   (+)   = sogg.ni_presso
   and sogg.ni                         = cont.ni
   and deba.cod_fiscale          (+)   = cont.cod_fiscale
   and deba.tipo_tributo         (+)   = w_tipo_tributo
   and ogpr.oggetto_pratica            = ogim.oggetto_pratica
   and ogim.anno                       = c_anno
   and ogim.flag_calcolo               = 'S'
   and prtr.tipo_tributo||''           = w_tipo_tributo
   and ((prtr.tipo_pratica    in ('D','C')) or
        (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S')
       )
   and prtr.pratica                    = ogpr.pratica
   and ogim.cod_fiscale                = cont.cod_fiscale
   and ogpr.tributo                    = nvl(c_tributo,ogpr.tributo)
   and (    c_scelta_anno               = 'T'
        or (c_scelta_anno               = 'P'
        and ogim.anno                   > f_min_anno_prat(prtr.pratica,ogim.cod_fiscale))
        or (c_scelta_anno               = 'A'
        and ogim.anno                   = f_min_anno_prat(prtr.pratica,ogim.cod_fiscale))
       )
   and a_tipo_contribuente in ('T','N')
 group by cont.cod_fiscale
union
select max(substr(
             decode(sogg.ni_presso
                   ,null,
                   decode(f_recapito(sogg.ni, ogva.tipo_tributo, 1, trunc(sysdate),'PR')
                         ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                         ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                          ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                          )
                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario1
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, ogva.tipo_tributo, 1, trunc(sysdate),'PR')
                            ,replace(replace(sogg.cognome_nome,'/',' '),';',','))
                   ,'c/o '||replace(replace(sogP.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario2
           decode(sogg.ni_presso
                 ,null,substr(nvl(f_recapito(sogg.ni, ogva.tipo_tributo, 1, trunc(sysdate))
                                 ,decode(sogg.cod_via
                                        ,to_number(null),sogg.denominazione_via
                                        ,arvi.denom_uff
                                        )
                                  ||' '||to_char(sogg.num_civ)
                                  ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                                  ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                                  ||decode(sogg.piano,'','',' P.'||sogg.piano)
                                  ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                 )
                             ,1,44)||';'
                 ,substr(decode(sogP.cod_via
                               ,to_number(null),sogP.denominazione_via
                               ,arvP.denom_uff
                               )
                          ||' '||to_char(sogP.num_civ)
                          ||decode(sogP.suffisso,'','','/'||sogP.suffisso)
                          ||decode(sogP.scala,'','',' Sc.'||sogP.scala)
                          ||decode(sogP.piano,'','',' P.'||sogP.piano)
                          ||decode(sogP.interno,'','',' Int.'||sogP.interno)
                        ,1,44)||';'
                 )||                                                                              -- Rigadestinatario3
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, ogva.tipo_tributo, 1, trunc(sysdate),'CC')
                            ,lpad(to_char(nvl(sogg.cap,comR.cap)),5,'0')||' '
                             ||substr(comR.denominazione,1,30)||' '
                             ||substr(proR.sigla,1,2)
                            )
                   ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
                    ||substr(comP.denominazione,1,30)||' '
                    ||substr(proP.sigla,1,2)
                   )
                  ,1,44)||';'||                                                                  -- Rigadestinatario4
         decode(sogg.ni_presso
               ,null,nvl(f_recapito(sogg.ni, ogva.tipo_tributo, 1, trunc(sysdate),'SE')
                        ,sttR.denominazione
                        )
               ,sttP.denominazione
               )||';'||                                                                          -- Estero
         substr(replace(replace(sogg.cognome_nome,'/',' '),';',','),1,37)||
         ';'||                                                                                   -- NOME1
         substr(decode(sogg.cod_via,
                        to_number(null),sogg.denominazione_via,
                        arvi.denom_uff)
                ||' '||to_char(sogg.num_civ)
                     ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                     ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                     ||decode(sogg.piano,'','',' P.'||sogg.piano)
                     ||decode(sogg.interno,'','',' Int.'||sogg.interno),1,44)||';'||             -- INDIR
         lpad(nvl(to_char(nvl(sogg.cap,nvl(comR.cap,0))),''),5,'0')|| ';'||                      -- CAP
         nvl(substr(comR.denominazione,1,30),'') || ';'||                                        -- DEST (città del versante)
         nvl(substr(proR.sigla,1,2),'') || ';'||                                                 -- PROVincia
         'N;'||                                                                                  -- IBAN
         decode(c_istat
               ,'048033',decode(nvl(deba.cod_abi,0)    -- Pontassieve
                               ,07601, '*'
                               ,''
                               )
               ,''
               )  || ';'||                                                                        -- Domiciliazione bancaria postale
          'COD.UT.: '||to_char(sogg.ni)||' C.F. P.IVA: '||cont.cod_fiscale||';'||                 -- VAR01D
          'C.F. P.IVA: '||cont.cod_fiscale||';'                                                   -- VAR02S
          )                                              prima_parte
     , max(sogg.ni)                              ni
     , max(replace(sogg.cognome_nome,'/',' '))   cognome_nome
     , cont.cod_fiscale                          cod_fiscale
  from ad4_provincie        proR
     , ad4_comuni           comR
     , ad4_stati_territori  sttR
     , ad4_provincie        proP
     , ad4_comuni           comP
     , ad4_stati_territori  sttP
     , archivio_vie         arvi
     , archivio_vie         arvP
     , soggetti             sogg
     , soggetti             sogP
     , contribuenti         cont
     , deleghe_bancarie     deba
     , oggetti_validita     ogva
     , oggetti_pratica      ogpr
 where proR.provincia            (+)   = sogg.cod_pro_res
   and comR.provincia_stato      (+)   = sogg.cod_pro_res
   and comR.comune               (+)   = sogg.cod_com_res
   and sttR.stato_territorio     (+)   = sogg.cod_pro_res
   and proP.provincia            (+)   = sogP.cod_pro_res
   and comP.provincia_stato      (+)   = sogP.cod_pro_res
   and comP.comune               (+)   = sogP.cod_com_res
   and sttP.stato_territorio     (+)   = sogP.cod_pro_res
   and arvi.cod_via              (+)   = sogg.cod_via
   and arvP.cod_via              (+)   = sogP.cod_via
   and sogP.ni                   (+)   = sogg.ni_presso
   and sogg.ni                         = cont.ni
   and deba.cod_fiscale          (+)   = cont.cod_fiscale
   and deba.tipo_tributo         (+)   = w_tipo_tributo
   and ogpr.oggetto_pratica            = ogva.oggetto_pratica
   and ogva.tipo_tributo||''           = w_tipo_tributo
   and c_anno between nvl(to_number(to_char(ogva.dal,'yyyy')),1900)
                  and nvl(to_number(to_char(ogva.al,'yyyy')),2999)
   and ogva.cod_fiscale                = cont.cod_fiscale
   and ogpr.tributo                    = nvl(c_tributo,ogpr.tributo)
   and not exists (select 'x'
                     from oggetti_imposta  ogim
                    WHERE ogim.tipo_tributo      = w_tipo_tributo
                      and ogim.cod_fiscale       = cont.cod_fiscale
                      and ogim.anno              = c_anno
                      and ogim.flag_calcolo      = 'S' )
   and (    c_scelta_anno               = 'T'
        or (c_scelta_anno               = 'P'
        and ogva.anno                   < c_anno)
        or (c_scelta_anno               = 'A'
        and ogva.anno                   = c_anno)
       )
   and a_tipo_contribuente in ('T','E')
group by cont.cod_fiscale
order by 3 -- cognome/nome
;
--
-- Selezione oggetti imposta da trattare per contribuente
--
cursor sel_ogim (c_anno number, c_cod_fiscale varchar2, c_istat varchar2, c_tributo number, c_scelta_anno varchar2) is
select ogge.oggetto
     , decode(ogge.descrizione,'','','Descrizione: '||ogge.descrizione) descrizione
     , 'Ubicazione occupazione: '
       ||rpad(nvl(decode( ogge.cod_via, null,ogge.indirizzo_localita, arvi.denom_uff
       ||decode( ogge.num_civ, null, '',  ', '||ogge.num_civ )
       ||decode( ogge.suffisso, null, '', '/'||ogge.suffisso )),' '),50,' ') ubicazione
     , rpad(decode(tari.descrizione,null,' ',substr('Tipo Tariffa: '||tari.descrizione,1,70)),70)
       ||lpad(ltrim(translate(to_char(tari.tariffa,'999,990.00000'),',.','.,')),17)   desc_tariffa
     , rpad(decode(cate.descrizione,null,' ',substr('Categoria: '||cate.descrizione,1,50)),50)||'  '
       ||lpad('Sup/Nr: '||ogpr.consistenza,15)
       ||decode(ogpr.quantita,'','',lpad('Quantità: '||ogpr.quantita,20)) desc_categoria
     , ''     esenzione
     , rpad('IMPORTO DOVUTO ',70)||lpad(translate(to_char(ogim.imposta,'9,999,999,990.00'), ',.', '.,'),17) importo_dovuto
     , ogim.imposta
     , lpad('_',87,'_') riga
  from oggetti_imposta      ogim
     , oggetti_pratica      ogpr
     , oggetti_contribuente ogco
     , pratiche_tributo     prtr
     , oggetti              ogge
     , tariffe              tari
     , archivio_vie         arvi
     , categorie            cate
 where ogim.oggetto_pratica   = ogpr.oggetto_pratica
   and prtr.pratica           = ogpr.pratica
   and ogge.oggetto           = ogpr.oggetto
   and ogco.oggetto_pratica   = ogpr.oggetto_pratica
   and ogco.cod_fiscale       = c_cod_fiscale
   and tari.tipo_tariffa (+)  = ogpr.tipo_tariffa
   and tari.categoria    (+)  = ogpr.categoria
   and tari.anno         (+)  = c_anno
   and tari.tributo      (+)  = ogpr.tributo
   and cate.tributo      (+)  = ogpr.tributo
   and cate.categoria    (+)  = ogpr.categoria
   and arvi.cod_via      (+)  = ogge.cod_via
   and prtr.tipo_tributo      = w_tipo_tributo
   and ogim.cod_fiscale       = c_cod_fiscale
   and ogim.anno              = c_anno
   and ogim.flag_calcolo      = 'S'
   and ogpr.tipo_occupazione  = 'P'
   and (    c_scelta_anno           = 'T'
        or  c_scelta_anno           = 'P'
        and ogim.anno               > f_min_anno_prat(prtr.pratica,ogim.cod_fiscale)
        or  c_scelta_anno           = 'A'
        and ogim.anno               = f_min_anno_prat(prtr.pratica,ogim.cod_fiscale)
       )
union all
select ogge.oggetto
     , decode(ogge.descrizione,'','','Descrizione: '||ogge.descrizione) descrizione
     , 'Ubicazione occupazione: '
       ||rpad(nvl(decode( ogge.cod_via, null,ogge.indirizzo_localita, arvi.denom_uff
       ||decode( ogge.num_civ, null, '',  ', '||ogge.num_civ )
       ||decode( ogge.suffisso, null, '', '/'||ogge.suffisso )),' '),50,' ') ubicazione
     , rpad(decode(tari.descrizione,null,' ',substr('Tipo Tariffa: '||tari.descrizione,1,70)),70)
       ||lpad(ltrim(translate(to_char(tari.tariffa,'999,990.00000'),',.','.,')),17)   desc_tariffa
     , rpad(decode(cate.descrizione,null,' ',substr('Categoria: '||cate.descrizione,1,50)),50)||'  '
       ||lpad('Sup/Nr: '||ogpr.consistenza,15)
       ||decode(ogpr.quantita,'','',lpad('Quantità: '||ogpr.quantita,20)) desc_categoria
     , lpad('ESENTE',12)     esenzione
     , rpad('IMPORTO DOVUTO ',70)||lpad('0,00',17) imposta
     , 0
     , lpad('_',87,'_') riga
  from oggetti_validita ogva
     , oggetti_pratica  ogpr
     , oggetti          ogge
     , tariffe          tari
     , archivio_vie     arvi
     , categorie        cate
 where ogpr.oggetto_pratica   = ogva.oggetto_pratica
   and ogge.oggetto           = ogva.oggetto
   and not exists ( select 'x'
                      from oggetti_imposta  ogim
                     where ogim.oggetto_pratica   = ogva.oggetto_pratica
                       and ogim.tipo_tributo      = w_tipo_tributo
                       and ogim.cod_fiscale       = c_cod_fiscale
                       and ogim.anno              = c_anno
                       and ogim.flag_calcolo      = 'S'  )
   and tari.tipo_tariffa (+)  = ogpr.tipo_tariffa
   and tari.categoria    (+)  = ogpr.categoria
   and tari.anno         (+)  = c_anno
   and tari.tributo      (+)  = ogpr.tributo
   and cate.tributo      (+)  = ogpr.tributo
   and cate.categoria    (+)  = ogpr.categoria
   and arvi.cod_via      (+)  = ogge.cod_via
   and ogva.tipo_tributo      = w_tipo_tributo
   and ogva.cod_fiscale       = c_cod_fiscale
   and nvl(to_number(to_char(ogva.dal,'yyyy')),1900)    <= c_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),2999)     >= c_anno
   and ogpr.tipo_occupazione = 'P'
   and (    c_scelta_anno            = 'T'
        or  c_scelta_anno            = 'P'
        and ogva.anno                < c_anno
        or  c_scelta_anno            = 'A'
        and ogva.anno                = c_anno
       )
   ;
--
-- Selezione rate imposta
--
cursor sel_raim (c_cod_fiscale varchar2, c_anno number, c_conto_corrente number) is
select raim.rata                                                                     numero_rata
     , sum(nvl(raim.imposta_round,raim.imposta))                                     importo_rata_num
  from rate_imposta      raim
 where raim.cod_fiscale                = c_cod_fiscale
   and raim.tipo_tributo               = w_tipo_tributo
   and raim.anno                       = c_anno
   and nvl(raim.conto_corrente,0)      = nvl(c_conto_corrente,nvl(raim.conto_corrente,0))
group by raim.rata
order by raim.rata
;
BEGIN
   --
   -- Controllo parametri inseriti
   --
   if nvl(a_scelta_anno,'*') not in ('A','P','T') then
      w_errore := 'Indicare anno delle dichiarazioni: A - Dichiarazioni dell''anno, P - Dichiarazioni di anni precedenti, T - Tutte';
      raise ERRORE;
   end if;
   --
   if nvl(a_tipo_contribuente,'*') not in ('E','N','T') then
      w_errore := 'Indicare tipologia contribuenti: E - Solo esenti, N - Solo non esenti, T - Tutti';
      raise ERRORE;
   end if;
   --
   w_importo_totale_complessivo := 0;
   w_progr_wrk := 0;
   w_cont_da_trattare := 0;
   w_conta_utenze     := 0;
   w_max_utenze       := 0;
   --Recupero il Flag Canone e, se null, inserisco nel file gli importi arrotondati
   BEGIN
      select decode(titr.flag_canone
                   , null, 'N'
                   , titr.flag_canone)
        into w_flag_canone
        from tipi_tributo titr
       where titr.tipo_tributo = w_tipo_tributo
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca del flag Canone' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   --Recupero codice Istat del Comune
   BEGIN
      select lpad(to_char(dage.pro_cliente), 3, '0') ||
             lpad(to_char(dage.com_cliente), 3, '0')e
           , comu.denominazione
           , comu.sigla_cfis
        into w_istat
           , w_comune
           , w_cod_belfiore
        from dati_generali dage
           , ad4_comuni    comu
       where dage.pro_cliente = comu.provincia_stato
         and dage.com_cliente = comu.comune
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nel recupero codice istat' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   -- Codice Tributo da trattare, viene settata la variabile p_tributo,
   -- se null tratta tutti i codici tributo
   if w_istat = '048010' then  -- Castelfiorentino
      w_tributo := 453;
   else
      w_tributo := null;
   end if;
   -- Recupero del conto corrente, serve per estrarre le rate imposta corrette
   if w_tributo is not null then
   BEGIN
      select cotr.conto_corrente
        into w_conto_corrente
        from codici_tributo  cotr
       where cotr.tipo_tributo = w_tipo_tributo
         and cotr.tributo      = w_tributo
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nel recupero conto corrente' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   else
      w_conto_corrente := null;
   end if;
   BEGIN
      select to_char(scade.data_scadenza,'dd/mm/yyyy')
        into w_scadenza_rata_0
        from scadenze scade
       where scade.tipo_tributo = w_tipo_tributo
         and scade.anno = a_anno
         and scade.rata = 0
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca della scadenza della rata zero' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   BEGIN
      delete wrk_trasmissioni
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella delete della tabella wrk_trasmissioni' || ' (' || SQLERRM || ')' );
            raise errore;
   END;
   BEGIN
    select max(rata)
      into w_max_rate
      from scadenze scad
     where scad.anno = a_anno
       and scad.tipo_tributo = w_tipo_tributo
       and scad.tipo_scadenza = 'V'
         ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max rata'||
                ' ('||SQLERRM||')');
   END;
   w_errore := ' Inizio ';
   w_progr_wrk := 1;
   FOR rec_cont IN sel_cont(a_anno, w_istat, w_tributo, a_scelta_anno) --Contribuenti
   LOOP
      w_cont_da_trattare := w_cont_da_trattare + 1;
      --
      -- Estrazione dati anagrafici per F24
      --
      begin
        select sogg.cognome                        ||';'||
               sogg.nome                           ||';'||
               rec_cont.cod_fiscale                ||';'||
               to_char(sogg.data_nas,'dd/mm/yyyy') ||';'||
               sogg.sesso                          ||';'||
               comN.denominazione                  ||';'||
               proN.sigla                          ||';'||
               f_primo_erede_cod_fiscale (sogg.ni) ||';'||
               'EL;'                               ||
               '3931;'                             ||
               w_cod_belfiore                      ||';'||
               a_anno                              ||';'
          into w_riga_f24
          from soggetti sogg
             , ad4_comuni         comN
             , ad4_provincie      proN
         where sogg.ni = rec_cont.ni
           and proN.provincia            (+)   = sogg.cod_pro_nas
           and comN.provincia_stato      (+)   = sogg.cod_pro_nas
           and comN.comune               (+)   = sogg.cod_com_nas;
      exception
        WHEN others THEN
          RAISE_APPLICATION_ERROR
            (-20919,'Errore in ricerca dati anagrafici '||rec_cont.ni||
                    ' ('||SQLERRM||')');
      END;
      --
      -- Si trattano prima le utenze del contribuente per verificare se
      -- e' totalmente esente. In questo caso infatti alcune colonne
      -- vanno lasciate vuote (rate, dati per F24, ecc.)
      --
      w_conta_utenze  := 0;
      w_importo_contr := 0;
      w_riga_var := '';
      FOR rec_ogim in sel_ogim(a_anno, rec_cont.cod_fiscale, w_istat, w_tributo, a_scelta_anno) --OGIM
      LOOP
        if rec_ogim.descrizione is not null then
           w_conta_utenze := w_conta_utenze + 1;
           w_riga_var := w_riga_var||rec_ogim.descrizione||';';
        end if;
        --
        w_conta_utenze := w_conta_utenze + 1;
        w_riga_var := w_riga_var||rec_ogim.ubicazione||' '||rec_ogim.esenzione||';';
        w_conta_utenze := w_conta_utenze + 1;
        w_riga_var := w_riga_var||rec_ogim.desc_categoria||';';
        w_conta_utenze := w_conta_utenze + 1;
        w_riga_var := w_riga_var||rec_ogim.desc_tariffa||';';
        w_conta_utenze := w_conta_utenze + 1;
        w_riga_var := w_riga_var||rec_ogim.importo_dovuto||';';
        w_conta_utenze := w_conta_utenze + 1;
        w_riga_var := w_riga_var||rec_ogim.riga||';';
        w_importo_contr := w_importo_contr + rec_ogim.imposta;
      END LOOP; --sel_ogim
      --
      -- Si memorizza il numero massimo di utenze per contribuente
      -- (per determinare il numero di "VAR" da intestare)
      --
      if w_conta_utenze > w_max_utenze then
         w_max_utenze := w_conta_utenze;
      end if;
      --dbms_output.put_line(rec_cont.cod_fiscale || ' ' || rec_cont.cognome_nome || ' ' || rec_cont.ni);
      w_riga_wrk := rec_cont.prima_parte;
      w_errore := to_char(length(w_riga_wrk))||'  1 '||rec_cont.cod_fiscale;
      if w_importo_contr = 0 then
         w_riga_f24 := rpad(';',12,';');
         w_riga_causale := ';';
         -- Allineamento Causale rate
         r := 0;
         WHILE r < w_max_rate
         loop
           w_riga_causale := w_riga_causale||';';
           r := r + 1;
         end loop;
         -- Allineamento rate
         w_riga_rata := ';0;';
         r := 0;
         WHILE r < w_max_rate
         loop
            w_riga_rata := w_riga_rata||';;;';
            r := r + 1;
         end loop;
         -- Allineamento rateazione
         w_riga_rateaz := ';';
         r := 0;
         WHILE r < w_max_rate
         loop
            w_riga_rateaz := w_riga_rateaz||';';
            r := r + 1;
         end loop;
      else
         w_importo_rata_1 := 0;
         w_importo_rata_2 := 0;
         w_importo_rata_3 := 0;
         w_importo_rata_4 := 0;
         w_conta_rate     := 0;
         --
         -- Valorizzazione stringhe con dati per pagamento unico
         --
         w_riga_causale := f_descrizione_titr(w_tipo_tributo,a_anno)||' - ANNO '||
                           a_anno||' UNICA SOLUZIONE;';
         w_riga_rateaz  := '0101;';
         --Importo e scadenza rata 0
         w_importo_rata_0 := w_importo_contr;
         --Inserimento dei dati sull'imposta totale (o rata 0)
         w_vcampot := to_char(a_anno) || '0' || lpad(rec_cont.ni,8,'0') || '001;';
         IF w_flag_canone = 'N' THEN
            w_riga_rata := w_vcampot || round(w_importo_rata_0,0) || ';' || w_scadenza_rata_0;
         ELSE
            w_riga_rata := w_vcampot || w_importo_rata_0 || ';' || w_scadenza_rata_0;
         END IF;
         --Determinazione degli Importi Rateizzati a livello di Contribuente
         FOR rec_raim in sel_raim(rec_cont.cod_fiscale, a_anno, w_conto_corrente) --Rate
         LOOP
           w_conta_rate   := w_conta_rate + 1;
           w_riga_causale := w_riga_causale || f_descrizione_titr(w_tipo_tributo,a_anno)||
                             ' - ANNO '||to_char(a_anno)||' - RATA '||to_char(rec_raim.numero_rata)||';';
           w_riga_rateaz  := w_riga_rateaz  || lpad(rec_raim.numero_rata,2,'0') || lpad(w_max_rate,2,'0')||';';
           if rec_raim.numero_rata = 1 then
              w_importo_rata_1 := rec_raim.importo_rata_num;
              BEGIN
                 select to_char(scade.data_scadenza,'dd/mm/yyyy')
                   into w_scadenza_rata_1
                   from scadenze scade
                  where scade.tipo_tributo = w_tipo_tributo
                    and scade.anno = a_anno
                    and scade.rata = 1
                      ;
              EXCEPTION
              WHEN others THEN
                 w_errore := ('Errore nella ricerca della scadenza della prima rata' || ' (' || SQLERRM || ')' );
                 raise errore;
              END;
              --Inserimento dei dati sulla rata 1
              w_vcampo1 := to_char(a_anno) || '1' || lpad(rec_cont.ni,8,'0') || '001;';
              w_riga_rata := w_riga_rata || ';' || w_vcampo1 || w_importo_rata_1 || ';' || w_scadenza_rata_1;
           end if;
           if rec_raim.numero_rata = 2 then
              w_importo_rata_2 := rec_raim.importo_rata_num;
              BEGIN
                select to_char(scade.data_scadenza,'dd/mm/yyyy')
                  into w_scadenza_rata_2
                  from scadenze scade
                 where scade.tipo_tributo = w_tipo_tributo
                   and scade.anno = a_anno
                   and scade.rata = 2
                     ;
              EXCEPTION
              WHEN others THEN
                 w_errore := ('Errore nella ricerca della scadenza della seconda rata' || ' (' || SQLERRM || ')' );
                 raise errore;
              END;
              --Inserimento dei dati sulla rata 2
              w_vcampo2 := to_char(a_anno) || '2' || lpad(rec_cont.ni,8,'0') || '001;';
              w_riga_rata := w_riga_rata || ';' || w_vcampo2 || w_importo_rata_2 || ';' || w_scadenza_rata_2;
           end if;
           if rec_raim.numero_rata = 3 then
              w_importo_rata_3 := rec_raim.importo_rata_num;
              BEGIN
                 select to_char(scade.data_scadenza,'dd/mm/yyyy')
                   into w_scadenza_rata_3
                   from scadenze scade
                  where scade.tipo_tributo = w_tipo_tributo
                    and scade.anno = a_anno
                    and scade.rata = 3
                      ;
              EXCEPTION
              WHEN others THEN
                 w_errore := ('Errore nella ricerca della scadenza della terza rata' || ' (' || SQLERRM || ')' );
                 raise errore;
              END;
              --Inserimento dei dati sulla rata 3
              w_vcampo3 := to_char(a_anno) || '3' || lpad(rec_cont.ni,8,'0') || '001;';
              w_riga_rata := w_riga_rata || ';' || w_vcampo3 || w_importo_rata_3 || ';' || w_scadenza_rata_3;
           end if;
           if rec_raim.numero_rata = 4 then
              w_importo_rata_4 := rec_raim.importo_rata_num;
              BEGIN
                 select to_char(scade.data_scadenza,'dd/mm/yyyy')
                   into w_scadenza_rata_4
                   from scadenze scade
                  where scade.tipo_tributo = w_tipo_tributo
                    and scade.anno = a_anno
                    and scade.rata = 4
                      ;
              EXCEPTION
              WHEN others THEN
                 w_errore := ('Errore nella ricerca della scadenza della quarta rata' || ' (' || SQLERRM || ')' );
                 raise errore;
              END;
              --Inserimento dei dati sulla rata 4
              w_vcampo4 := to_char(a_anno) || '4' || lpad(rec_cont.ni,8,'0') || '001;';
              w_riga_rata := w_riga_rata || ';' || w_vcampo4 || w_importo_rata_4 || ';' || w_scadenza_rata_4;
           end if;
         END LOOP; --rec_raim
         --
         if w_conta_rate < w_max_rate then
            -- Allineamento Causale rate
            r := w_conta_rate;
            WHILE r < w_max_rate
            loop
              w_riga_causale := w_riga_causale||';';
              r := r + 1;
            end loop;
            -- Allineamento rate
            r := w_conta_rate;
            WHILE r < w_max_rate
            loop
              w_riga_rata := w_riga_rata||';;;';
              r := r + 1;
            end loop;
            -- Allineamento rateazione
            r := w_conta_rate;
            WHILE r < w_max_rate
            loop
              w_riga_rateaz := w_riga_rateaz||';';
              r := r + 1;
            end loop;
         end if;
      end if;
      --
      w_riga_wrk := w_riga_wrk||w_riga_causale;
      --
      -- Inserimento note
      --
      w_riga_wrk := w_riga_wrk||'Importo Dovuto Euro '||translate(to_char(w_importo_contr,'99,999,990.00'),',.','.,')||';';
      w_riga_wrk := w_riga_wrk||'AVVISO DI PAGAMENTO '||f_descrizione_titr(w_tipo_tributo,a_anno)||';';
      w_riga_wrk := w_riga_wrk||'COMUNE DI '||w_comune||' - UFFICIO TRIBUTI'||';';
      --
      w_riga_wrk := w_riga_wrk || w_riga_rata;
      --
      w_riga_wrk := w_riga_wrk || ';' || w_riga_f24 || w_riga_rateaz || w_riga_var;
      --
      w_progr_wrk := w_progr_wrk + 1; --Conta anche il numero dei contribuenti trattati +1
      --
      -- (VD  - 28/08/2017): si suddivide la riga in parti di 4000 crt,
      --                     per consentire la gestione delle righe più'
      --                     lunghe di 4000
      --
      w_dati := substr(w_riga_wrk,1,4000);
      w_dati2 := substr(w_riga_wrk,4001,4000);
      w_dati3 := substr(w_riga_wrk,8001,4000);
      w_dati4 := substr(w_riga_wrk,12001,4000);
      w_dati5 := substr(w_riga_wrk,16001,4000);
      w_dati6 := substr(w_riga_wrk,20001,4000);
      w_dati7 := substr(w_riga_wrk,24001,4000);
      w_dati8 := substr(w_riga_wrk,28001,4000);
      BEGIN
         insert into wrk_trasmissioni(numero
                                    , dati
                                    , dati2
                                    , dati3
                                    , dati4
                                    , dati5
                                    , dati6
                                    , dati7
                                    , dati8)
         values (lpad(w_progr_wrk,15,'0')
               , w_dati
               , w_dati2
               , w_dati3
               , w_dati4
               , w_dati5
               , w_dati6
               , w_dati7
               , w_dati8);
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento wrk_trasmissione' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      w_importo_totale_complessivo := w_importo_totale_complessivo + w_importo_contr;
   END LOOP; --sel_cont
   -- Intestazione
   w_intest_prima   := 'Rigadestinatario1;Rigadestinatario2;Rigadestinatario3;Rigadestinatario4;Estero;NOME1;INDIRIZZO;CAP;DEST;PROV;IBAN;DOM;VAR01D;VAR01S;';
   w_intest_terza   := 'VCAMPOT;XRATAT;SCADET';
   w_intestazione   := w_intest_prima||'CST;';
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||'CS'||to_char(r+1)||';';
     r:= r +1;
   END LOOP;
   i := 0;
   WHILE i < 3
   LOOP
     w_intestazione := w_intestazione||'NOTE'||lpad( to_char(i+1),2,'0')||';';
     i:= i +1;
   END LOOP;
   w_intestazione := w_intestazione||w_intest_terza;
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||';VCAMPO'||to_char(r+1)||';XRATA'||to_char(r+1)||';SCADE'||to_char(r+1);
     r:= r +1;
   END LOOP;
   w_intestazione := w_intestazione
                     ||';COGNOME;NOME;COD_FISCALE;DATA_NASCITA;SESSO;COMUNE_NASCITA;'
                     ||'PROVINCIA_NASCITA;COD_FISCALE_EREDE_COOBBLIGATO;SEZIONE;'
                     ||'CODICE_TRIBUTO;CODICE_ENTE;ANNO;RATEAZIONET';
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||';RATEAZIONE'||(r+1);
     r:= r +1;
   END LOOP;
   i:=0;
   WHILE i < w_max_utenze
   LOOP
     if w_max_utenze < 100 then
        w_intestazione := w_intestazione||';'||'VAR'||lpad( to_char(i+1),2,'0')||'A';
     else
        w_intestazione := w_intestazione||';'||'VAR'||lpad( to_char(i+1),3,'0')||'A';
     end if;
     i:= i +1;
   END LOOP;
   --
   w_dati := substr(w_intestazione,1,4000);
   w_dati2 := substr(w_intestazione,4001,4000);
   w_dati3 := substr(w_intestazione,8001,4000);
   w_dati4 := substr(w_intestazione,12001,4000);
   w_dati5 := substr(w_intestazione,16001,4000);
   w_dati6 := substr(w_intestazione,20001,4000);
   w_dati7 := substr(w_intestazione,24001,4000);
   w_dati8 := substr(w_intestazione,28001,4000);
   BEGIN
     insert into wrk_trasmissioni(numero
                                 , dati
                                 , dati2
                                 , dati3
                                 , dati4
                                 , dati5
                                 , dati6
                                 , dati7
                                 , dati8)
      values (lpad(1,15,'0')
             , w_dati
             , w_dati2
             , w_dati3
             , w_dati4
             , w_dati5
             , w_dati6
             , w_dati7
             , w_dati8);
   EXCEPTION
     WHEN others THEN
       w_errore := ('Errore in inserimento wrk_trasmissione' || ' (' || SQLERRM || ')' );
       raise errore;
   END;
   w_errore := ' Fine ';
   a_num_righe := w_progr_wrk;
   a_num_contribuenti := w_cont_da_trattare;
   a_totale_imposta := round(w_importo_totale_complessivo);
/*   dbms_output.put_line('Totale contribuenti trattati: ' || w_progr_wrk);
   dbms_output.put_line('Importo totale: ' || w_importo_totale_complessivo); */
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999, w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999, 'Errore in estrazione_cosap_poste ' || '('||SQLERRM||')');
END;
/* End Procedure: ESTRAZIONE_ICP_F24 */
/

