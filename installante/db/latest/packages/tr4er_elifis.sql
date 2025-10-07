--liquibase formatted sql 
--changeset abrandolini:20250326_152429_tr4er_elifis stripComments:false runOnChange:true context:ER
 
create or replace package TR4ER_ELIFIS
AS
 s_versione  varchar2(20) := 'V1.0';
 s_revisione varchar2(30) := '05   10/04/2012';
   function versione return varchar2;
   function estrai_numerico
   (nStringa varchar2
   ) return number;
   function f_valore_ogge
   ( p_oggetto  IN number
   ) RETURN varchar2;
   function f_numerico
   ( p_dato     IN varchar2
   ) RETURN number;
   function f_ulteriore_detrazione
   ( p_anno            in number
   , p_cod_fiscale    in varchar2
   , p_made           in number
   ) RETURN number;
   function f_importi_ravvedimento_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number;
   function f_importi_violazioni_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number;
   function f_importi_liquidazioni_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   , p_rata               IN varchar2
   ) RETURN number;
   function f_rata_sanzione_ici
   ( p_cod_sanz            IN number
   ) RETURN number;
   function f_tipo_carico_ici
   ( p_pratica            IN number
   , p_tipo_pratica       IN varchar2
   , p_rata               IN varchar2
   ) RETURN varchar2;
   function f_tipo_accertamento
   ( p_pratica            IN number
   ) RETURN varchar2;
   function f_importi_violazioni_rsu
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number;
   function f_pratica_a_ruolo
   ( p_pratica            IN number
   ) RETURN varchar2;
   function f_max_ogge_pratica_rsu
   ( p_pratica            IN number
   ) RETURN number;
   function f_tipo_carico_rsu
   ( p_pratica            IN number
   ) RETURN varchar2;
   procedure tracciato_comuni;
   procedure tracciato_nazioni;
   procedure sit_strade;
   procedure sit_civici;
   procedure anagrafiche_soggetti;
   procedure anagrafiche_oggetti;
   procedure denunce_ici;
   procedure aliquote_speciali_ici;
   procedure detrazioni_ici;
   procedure versamenti_ici;
   procedure provvedimenti_ici;
   procedure dovuti_ici;
   procedure aliquote_ici;
   procedure agevolazioni_ici;
   procedure denunce_rsu;
   procedure provvedimenti_rsu;
   procedure classe_tariffa_rsu;
   procedure tipi_oggetto_rsu;
END TR4ER_ELIFIS;
/

create or replace package body TR4ER_ELIFIS is
   function versione return varchar2
   is
   begin
      return s_versione||'.'||s_revisione;
   end versione;
function estrai_numerico (nStringa varchar2)
return number
is
-- LA FUNZIONE RESTITUISCE IL PRIMO GRUPPO NUMERICO CONTENUTO IN UNA STRINGA
w_valore_numerico  number;
BEGIN
 select
    decode(sign(instr(translate(nStringa||'X'
                         ,'0123456789','9999999999'),'9',1)
               - decode(instr(nstringa,'-'),0,rpad('9',length(nStringa),'9'),instr(nStringa,'-'))
               ),1,'-'
                ,''
          )
  ||substr(nStringa||'X',
          instr(translate(nStringa||'X'
                         ,'0123456789','9999999999'),'9',1),
          instr(translate(nStringa||'X',
                      replace(translate(nStringa||'X'
                                       ,'0123456789','9999999999'),'9',''),
                      rpad('X',
                       length(replace(translate(
                                     nStringa||'X'
                                  ,'0123456789','9999999999'),'9','')
                             ),'X')
                        ),'X'
                       ,instr(translate(nStringa||'X'
                                ,'0123456789','9999999999'),'9',1)
                       )
          -instr(translate(nStringa||'X'
                  ,'0123456789','9999999999'),'9',1)
          )
    into w_valore_numerico
    from dual
   ;
   RETURN w_valore_numerico;
END;
   function f_valore_ogge
   (p_oggetto            IN number
   ) RETURN varchar2 IS
   w_return      varchar2(15);
   BEGIN
      begin
         select '1  '||lpad(to_char(riog.rendita * 100),12,'0')
           into w_return
           from riferimenti_oggetto riog
          where riog.oggetto = p_oggetto
            and sysdate between riog.inizio_validita
                            and riog.fine_validita
              ;
      EXCEPTION
         WHEN OTHERS THEN
              w_return := null;
      end;
      if w_return is not null then
         return w_return;
      end if;
      begin
         select '3  '||lpad(to_char(f_valore( ogpr.valore
                                            , nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                            , prtr.anno
                                            , to_number(to_char(sysdate,'yyyy'))
                                            , nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                            , prtr.tipo_pratica
                                            , ogpr.flag_valore_rivalutato
                                            )
                                    * 100),12,'0')
           into w_return
           from oggetti_pratica  ogpr
              , oggetti          ogge
              , pratiche_tributo prtr
          where ogpr.oggetto = p_oggetto
            and ogge.oggetto = p_oggetto
            and ogpr.oggetto_pratica =
                            ( select to_number(substr(
                                         max(nvl(to_char(prt2.data,'yyyymmdd'),rpad(' ',8))
                                           ||lpad(to_char(ogp2.oggetto_pratica),10,'0')
                                            )
                                                     ,9,10)
                                              )
                                from oggetti_pratica  ogp2
                                   , pratiche_tributo prt2
                               where ogp2.oggetto = p_oggetto
                                 and ogp2.pratica = prt2.pratica
                                 and ogp2.valore is not null
                             )
              ;
      EXCEPTION
         WHEN OTHERS THEN
              w_return := null;
      end;
      if w_return is not null then
         return w_return;
      else
         RETURN rpad('3',3)||lpad('0',12,'0');
      end if;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN rpad(' ',3)||lpad('0',12,'0');
   END;
   function f_numerico
   (p_dato            IN varchar2
   ) RETURN number IS
   w_test      number;
   BEGIN
      w_test := length(translate(p_dato, 'A1234567890', 'A'));
      if w_test = 0 then
         return to_number(p_dato);
      else
         return null;
      end if;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_ulteriore_detrazione
   ( p_anno            in number
   , p_cod_fiscale     in varchar2
   , p_made            in number
   ) RETURN number IS
   w_detrazione_den            number;
   w_mesi_pos_den              number;
   w_anno_den                  number;
   w_detrazione_base           number;
   w_detrazione_base_anno_den  number;
   w_detrazione                number;
   BEGIN
      begin
         select ogco.detrazione
              , nvl(ogco.mesi_possesso,12)
              , nvl(prtr.anno,1992)
           into w_detrazione_den
              , w_mesi_pos_den
              , w_anno_den
           from oggetti_pratica       ogpr
              , oggetti_contribuente  ogco
              , pratiche_tributo      prtr
          where ogpr.pratica         = prtr.pratica
            and ogpr.oggetto_pratica = ogco.oggetto_pratica
            and ogco.cod_fiscale     = p_cod_fiscale
            and ogco.detrazione is not null
            and ogpr.oggetto_pratica =
                 (select to_number(substr(max(to_char(prt2.anno)||lpad(to_char(ogp2.oggetto_pratica),8,'0'))
                                         ,5,8))
                    from oggetti_pratica       ogp2
                       , pratiche_tributo      prt2
                       , oggetti_contribuente  ogc2
                   where ogp2.pratica          = prt2.pratica
                     and ogp2.oggetto_pratica  = ogc2.oggetto_pratica
                     and ogc2.cod_fiscale      = p_cod_fiscale
                     and prt2.anno            <= p_anno
                     and prt2.tipo_tributo||'' = 'ICI'
                     and ogc2.detrazione       is not null
                     and (  prt2.tipo_pratica||''    = 'D'
                         or
                           (  prt2.tipo_pratica||''            = 'A'
                          and prt2.data_notifica               is not null
                          and nvl(prt2.stato_accertamento,'D') = 'D'
                          and nvl(prt2.flag_denuncia,' ')      = 'S'
                          and prt2.anno                        < p_anno
                           )
                          )
                 )
              ;
      EXCEPTION
         WHEN OTHERS THEN
              w_detrazione_den := 0;
              w_mesi_pos_den   := 12;
              w_anno_den       := 1992;
      end;
      begin
         select dete.detrazione_base
           into w_detrazione_base
           from detrazioni   dete
          where dete.anno = p_anno
              ;
      EXCEPTION
         WHEN OTHERS THEN
              w_detrazione_base := 0;
      end;
      begin
         select dete.detrazione_base
           into w_detrazione_base_anno_den
           from detrazioni   dete
          where dete.anno = w_anno_den
              ;
      EXCEPTION
         WHEN OTHERS THEN
              w_detrazione_base_anno_den := 0;
      end;
      if w_detrazione_base_anno_den = 0 then
         return p_made;
      end if;
      if w_mesi_pos_den = 0 then
         return p_made - w_detrazione_base_anno_den;
      end if;
      if w_anno_den = p_anno then
         w_detrazione := w_detrazione_den;
      else
         w_detrazione := round(w_detrazione_den
                                / 12 * w_mesi_pos_den
                                / w_detrazione_base_anno_den * w_detrazione_base
                              ,2);
      end if;
      if p_made - w_detrazione < 0 then
         return 0;
      else
         return p_made - w_detrazione;
      end if;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN 0;
   END;
   function f_importi_ravvedimento_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number IS
   w_importo      number;
   BEGIN
      begin
         select sum(decode(p_tipo_importo
                          ,'INT',decode(sapr.cod_sanzione
                                       ,198,nvl(sapr.importo,0)
                                       ,199,nvl(sapr.importo,0)
                                       ,0
                                       )
                          ,'SAN',decode(sapr.cod_sanzione
                                       ,101,0
                                       ,121,0
                                       ,198,0
                                       ,199,0
                                       ,nvl(sapr.importo,0)
                                       )
                          ,0
                          )
                   )
           into w_importo
           from pratiche_tributo prtr
              , sanzioni_pratica sapr
          where sapr.pratica = prtr.pratica
            and prtr.tipo_pratica||'' = 'V'
            and prtr.pratica  = p_pratica
              ;
      exception
         when others then
            w_importo := 0;
      end;
      return nvl(w_importo,0);
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_importi_violazioni_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number IS
   w_importo      number;
   BEGIN
      begin
         select sum(decode(p_tipo_importo
                          ,'IMP',decode(sapr.cod_sanzione
                                       ,1,sapr.importo
                                       ,21,sapr.importo
                                       ,31,sapr.importo
                                       ,101,sapr.importo
                                       ,121,sapr.importo
                                       ,131,sapr.importo
                                       ,0
                                       )
                          ,'INT',decode(sapr.cod_sanzione
                                       ,98,sapr.importo
                                       ,99,sapr.importo
                                       ,198,sapr.importo
                                       ,199,sapr.importo
                                       ,0
                                       )
                          ,'SAN',decode(sapr.cod_sanzione
                                       ,1,0
                                       ,11,0
                                       ,12,0
                                       ,21,0
                                       ,31,0
                                       ,96,0
                                       ,97,0
                                       ,98,0
                                       ,99,0
                                       ,101,0
                                       ,111,0
                                       ,112,0
                                       ,121,0
                                       ,131,0
                                       ,196,0
                                       ,197,0
                                       ,198,0
                                       ,199,0
                                       ,sapr.importo
                                       )
                          ,'SANRID',decode(sapr.cod_sanzione
                                       ,1,0
                                       ,11,0
                                       ,12,0
                                       ,21,0
                                       ,31,0
                                       ,96,0
                                       ,97,0
                                       ,98,0
                                       ,99,0
                                       ,101,0
                                       ,111,0
                                       ,112,0
                                       ,121,0
                                       ,131,0
                                       ,196,0
                                       ,197,0
                                       ,198,0
                                       ,199,0
                                       ,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       )
                          ,'SPE',decode(sapr.cod_sanzione
                                       ,97,sapr.importo
                                       ,197,sapr.importo
                                       ,0
                                       )
                          ,'PEP',decode(sapr.cod_sanzione
                                       ,11,sapr.importo
                                       ,12,sapr.importo
                                       ,96,sapr.importo
                                       ,111,sapr.importo
                                       ,112,sapr.importo
                                       ,196,sapr.importo
                                       ,0
                                       )
                          ,0
                          )
                   )
           into w_importo
           from pratiche_tributo prtr
              , sanzioni_pratica sapr
          where sapr.pratica = prtr.pratica
            and prtr.tipo_pratica  in ('A','L','I')
            and prtr.pratica  = p_pratica
              ;
      exception
         when others then
            w_importo := 0;
      end;
      return nvl(w_importo,0);
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_importi_liquidazioni_ici
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   , p_rata               IN varchar2
   ) RETURN number IS
   w_importo      number;
   BEGIN
      begin
         select sum(decode(p_rata||p_tipo_importo
                          ,'AIMP',decode(sapr.cod_sanzione
                                       ,1,sapr.importo
                                       ,101,sapr.importo
                                       ,0
                                       )
                          ,'SIMP',decode(sapr.cod_sanzione
                                       ,21,sapr.importo
                                       ,121,sapr.importo
                                       ,0
                                       )
                          ,'AINT',decode(sapr.cod_sanzione
                                       ,98,sapr.importo
                                       ,198,sapr.importo
                                       ,0
                                       )
                          ,'SINT',decode(sapr.cod_sanzione
                                       ,99,sapr.importo
                                       ,199,sapr.importo
                                       ,0
                                       )
                          ,'ASAN',decode(sapr.cod_sanzione
                                       ,4,sapr.importo
                                       ,5,sapr.importo
                                       ,6,sapr.importo
                                       ,7,sapr.importo
                                       ,104,sapr.importo
                                       ,105,sapr.importo
                                       ,106,sapr.importo
                                       ,107,sapr.importo
                                       ,136,sapr.importo
                                       ,151,sapr.importo
                                       ,152,sapr.importo
                                       ,155,sapr.importo
                                       ,157,sapr.importo
                                       ,158,sapr.importo
                                       ,161,sapr.importo
                                       ,162,sapr.importo
                                       ,206,sapr.importo
                                       ,207,sapr.importo
                                       ,0
                                       )
                          ,'SSAN',decode(sapr.cod_sanzione
                                       ,8,sapr.importo
                                       ,9,sapr.importo
                                       ,22,sapr.importo
                                       ,23,sapr.importo
                                       ,108,sapr.importo
                                       ,109,sapr.importo
                                       ,122,sapr.importo
                                       ,123,sapr.importo
                                       ,137,sapr.importo
                                       ,153,sapr.importo
                                       ,154,sapr.importo
                                       ,156,sapr.importo
                                       ,159,sapr.importo
                                       ,160,sapr.importo
                                       ,163,sapr.importo
                                       ,164,sapr.importo
                                       ,208,sapr.importo
                                       ,209,sapr.importo
                                       ,0
                                       )
                          ,'ASANRID',decode(sapr.cod_sanzione
                                       ,4,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,5,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,6,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,7,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,104,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,105,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,106,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,107,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,136,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,151,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,152,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,155,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,157,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,158,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,161,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,162,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,206,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,207,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,0
                                       )
                          ,'SSANRID',decode(sapr.cod_sanzione
                                       ,8,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,9,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,22,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,23,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,108,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,109,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,122,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,123,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,137,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,153,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,154,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,156,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,159,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,160,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,163,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,164,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,208,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,209,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       ,0
                                       )
                          ,0
                          )
                   )
           into w_importo
           from pratiche_tributo prtr
              , sanzioni_pratica sapr
          where sapr.pratica = prtr.pratica
            and prtr.tipo_pratica  in ('A','L','I')
            and prtr.pratica  = p_pratica
              ;
      exception
         when others then
            w_importo := 0;
      end;
      return nvl(w_importo,0);
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_rata_sanzione_ici
   ( p_cod_sanz            IN number
   ) RETURN number IS
   w_rata      number;
   BEGIN
      if p_cod_sanz in (1,4,5,6,7,10,98,101,104,105,106,107,110,136,151,152,155,157,158,161,162,198,206,207) then
         w_rata := 1;
      elsif p_cod_sanz in (8,9,20,21,21,23,99,108,109,120,121,122,123,137,153,154,156,159,160,163,164,199,208,209) then
         w_rata := 2;
      else
         w_rata := 3;
      end if;
      return w_rata;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_tipo_carico_ici
   ( p_pratica            IN number
   , p_tipo_pratica       IN varchar2
   , p_rata               IN varchar2
   ) RETURN varchar2 IS
   w_tipo_carico      varchar2(16);
   BEGIN
      if p_tipo_pratica = 'L' then
         if p_rata = 'A' then
            begin
               select max(decode(cod_sanzione
                            ,4,'VO'
                            ,104,'VO'
                            ,5,'VP'
                            ,105,'VP'
                            ,161,'VP'
                            ,162,'VP'
                            ,6,'VT'
                            ,7,'VT'
                            ,106,'VT'
                            ,107,'VT'
                            ,136,'VT'
                            ,151,'VT'
                            ,152,'VT'
                            ,155,'VT'
                            ,157,'VT'
                            ,158,'VT'
                            ))
                 into w_tipo_carico
                 from sanzioni_pratica sapr
                where sapr.pratica = p_pratica
                  and sapr.cod_sanzione in (4,104,5,105,161,162,6,7,106,107,136,151,152,155,157,158)
                  ;
            EXCEPTION
               WHEN OTHERS THEN
                    w_tipo_carico := 'ID';
            end;
         else -- Saldo
            begin
               select max(decode(cod_sanzione
                            ,22,'VO'
                            ,122,'VO'
                            ,23,'VP'
                            ,123,'VP'
                            ,163,'VP'
                            ,164,'VP'
                            ,8,'VT'
                            ,9,'VT'
                            ,108,'VT'
                            ,109,'VT'
                            ,137,'VT'
                            ,153,'VT'
                            ,154,'VT'
                            ,156,'VT'
                            ,159,'VT'
                            ,160,'VT'
                            ))
                 into w_tipo_carico
                 from sanzioni_pratica sapr
                where sapr.pratica = p_pratica
                  and sapr.cod_sanzione in (22,122,23,123,163,164,8,9,108,109,137,153,154,156,159,160)
                  ;
            EXCEPTION
               WHEN OTHERS THEN
                    w_tipo_carico := 'ID';
            end;
         end if;
      else  -- Accertamento
         begin
            select decode(cod_sanzione
                         ,32,'DO'
                         ,132,'DO'
                         ,34,'DO'
                         ,134,'DI'
                         )
              into w_tipo_carico
              from sanzioni_pratica sapr
             where sapr.pratica = p_pratica
               and sapr.cod_sanzione in (32,132,34,134)
               ;
         EXCEPTION
            WHEN OTHERS THEN
                 w_tipo_carico := 'ID';
         end;
      end if;
      return nvl(w_tipo_carico,'ID');
   EXCEPTION
      WHEN OTHERS THEN
           RETURN ' ';
   END;
   function f_tipo_accertamento
   ( p_pratica            IN number
   ) RETURN varchar2 IS
   w_ogpr_rif  number;
   BEGIN
      begin
         select max(nvl(ogpr.oggetto_pratica_rif,0))
           into w_ogpr_rif
           from pratiche_tributo prtr
              , oggetti_pratica  ogpr
          where ogpr.pratica  = prtr.pratica
            and prtr.pratica  = p_pratica
              ;
      exception
         when others then
            w_ogpr_rif := 0;
      end;
      if w_ogpr_rif = 0 then  -- Accertamento d'Ufficio
         return 'AU';
      else  -- Accertamento in Rettifica
         return 'AR';
      end if;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_importi_violazioni_rsu
   ( p_pratica            IN number
   , p_tipo_importo       IN varchar2
   ) RETURN number IS
   w_importo      number;
   BEGIN
      begin
         select sum(decode(p_tipo_importo
                          ,'IMP',decode(sapr.cod_sanzione
                                       ,1,sapr.importo
                                       ,100,sapr.importo
                                       ,101,sapr.importo
                                       ,111,sapr.importo
                                       ,121,sapr.importo
                                       ,131,sapr.importo
                                       ,141,sapr.importo
                                       ,0
                                       )
                          ,'INT',decode(sapr.cod_sanzione
                                       ,98,sapr.importo
                                       ,99,sapr.importo
                                       ,191,sapr.importo
                                       ,192,sapr.importo
                                       ,193,sapr.importo
                                       ,194,sapr.importo
                                       ,199,sapr.importo
                                       ,0
                                       )
                          ,'SAN',decode(sapr.cod_sanzione
                                       ,1,0
                                       ,15,0
                                       ,98,0
                                       ,99,0
                                       ,100,0
                                       ,101,0
                                       ,111,0
                                       ,121,0
                                       ,131,0
                                       ,141,0
                                       ,191,0
                                       ,192,0
                                       ,193,0
                                       ,194,0
                                       ,198,0
                                       ,199,0
                                       ,sapr.importo
                                       )
                          ,'SANRID',decode(sapr.cod_sanzione
                                       ,1,0
                                       ,15,0
                                       ,98,0
                                       ,99,0
                                       ,100,0
                                       ,101,0
                                       ,111,0
                                       ,121,0
                                       ,131,0
                                       ,141,0
                                       ,191,0
                                       ,192,0
                                       ,193,0
                                       ,194,0
                                       ,198,0
                                       ,199,0
                                       ,round(sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100 ,2)
                                       )
                          ,'SPE',decode(sapr.cod_sanzione
                                       ,15,sapr.importo
                                       ,198,sapr.importo
                                       ,0
                                       )
--                          ,'PEP',decode(sapr.cod_sanzione
--                                       ,11,sapr.importo
--                                       ,12,sapr.importo
--                                       ,96,sapr.importo
--                                       ,111,sapr.importo
--                                       ,112,sapr.importo
--                                       ,196,sapr.importo
--                                       ,0
--                                       )
                          ,'ADDPRO',decode(sapr.cod_sanzione
                                       ,1,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,100,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,101,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,111,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,121,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,131,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,141,round(sapr.importo * nvl(cata.addizionale_pro,0) / 100 ,2)
                                       ,0
                                       )
                          ,'ADDCOM',decode(sapr.cod_sanzione
                                       ,1,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,100,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,101,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,111,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,121,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,131,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,141,round(sapr.importo * (nvl(cata.addizionale_eca ,0) + nvl(cata.maggiorazione_eca,0)) / 100 , 2)
                                       ,0
                                       )
                          ,0
                          )
                   )
           into w_importo
           from pratiche_tributo prtr
              , sanzioni_pratica sapr
              , carichi_tarsu    cata
          where sapr.pratica = prtr.pratica
            and prtr.tipo_pratica  in ('A','L','I')
            and prtr.pratica  = p_pratica
            and cata.anno     = prtr.anno
              ;
      exception
         when others then
            w_importo := 0;
      end;
      return nvl(w_importo,0);
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_pratica_a_ruolo
   ( p_pratica            IN number
   ) RETURN varchar2 IS
   w_a_ruolo  number;
   BEGIN
      begin
         select count(1)
           into w_a_ruolo
           from sanzioni_pratica sapr
          where sapr.pratica  = p_pratica
            and sapr.ruolo    is not null
              ;
      exception
         when others then
            w_a_ruolo := 0;
      end;
      if w_a_ruolo > 0 then
         return 'S';
      else
         return 'N';
      end if;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN 'N';
   END;
   function f_max_ogge_pratica_rsu
   ( p_pratica            IN number
   ) RETURN number IS
   w_oggetto  number;
   BEGIN
      begin
         select max(ogpr.oggetto)
           into w_oggetto
           from oggetti_pratica ogpr
          where ogpr.pratica  = p_pratica
              ;
      exception
         when others then
            w_oggetto := 0;
      end;
      return w_oggetto;
   EXCEPTION
      WHEN OTHERS THEN
           RETURN null;
   END;
   function f_tipo_carico_rsu
   ( p_pratica            IN number
   ) RETURN varchar2 IS
   w_tipo_carico      varchar2(16);
   BEGIN
      begin
         select max(decode(cod_sanzione
                      ,2,'AU'
                      ,102,'AU'
                      ,3,'AR'
                      ,4,'AR'
                      ,103,'AR'
                      ,104,'AR'
                      ,116,'RO'
                      ,117,'RO'
                      ,126,'RO'
                      ,127,'RO'
                      ,136,'RO'
                      ,137,'RO'
                      ,146,'RO'
                      ,147,'RO'
                      ,118,'RT'
                      ,119,'RT'
                      ,128,'ROT'
                      ,129,'RT'
                      ,138,'RT'
                      ,139,'RT'
                      ,148,'RT'
                      ,149,'RT'
                      ))
           into w_tipo_carico
           from sanzioni_pratica sapr
          where sapr.pratica = p_pratica
            and sapr.cod_sanzione in (2,3,4,102,103,104,116,117,118,119,126,127,128,129,136,137,138,139,146,147,148,149)
            ;
      EXCEPTION
         WHEN OTHERS THEN
              w_tipo_carico := 'RO';
      end;
      return nvl(w_tipo_carico,'RO');
   EXCEPTION
      WHEN OTHERS THEN
           RETURN ' ';
   END;
   procedure tracciato_comuni is
   CURSOR sel_comu IS
      select lpad(comu.provincia_stato,3,'0')||lpad(comu.comune,3,'0')          COD_CMN
           , rpad(comu.denominazione,200)                                       DES_CMN
           , rpad(nvl(prov.sigla,' '),3)                                        SGL_PRV
           , lpad(nvl(comu.cap,'0'),5,'0')                                               CAP_GEN
           , rpad(' ',2)                                                        COD_ISTAT_RGN
           , lpad(comu.provincia_stato,3,'0')||lpad(comu.comune,3,'0')          COD_ISTAT_CMN
           , decode(sign(comu.provincia_stato - 200)
                   ,1,'S'
                   ,'N'
                   )                                                            FLG_ESTERO
           , lpad(decode(sign(comu.provincia_stato - 200)
                        ,-1,'100'
                        ,to_char(comu.provincia_stato)
                        )
                  ,24,'0')                                                      IDR_STA_NAZ
           , rpad(nvl(comu.sigla_cfis,' '),4)                                   COD_CAT_CMN
       from  ad4_comuni          comu
           , ad4_province        prov
       where comu.provincia_stato  (+) = prov.provincia
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Comuni
      for rec_comu in sel_comu loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Comuni '||rec_comu.COD_CMN;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , w_cod_belfiore                      -- COD_ENTE
                  ||rec_comu.COD_CMN
                  ||rec_comu.DES_CMN
                  ||rec_comu.SGL_PRV
                  ||rec_comu.CAP_GEN
                  ||rec_comu.COD_ISTAT_RGN
                  ||rec_comu.COD_ISTAT_CMN
                  ||rec_comu.FLG_ESTERO
                  ||rec_comu.IDR_STA_NAZ
                  ||rec_comu.COD_CAT_CMN
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Comuni '||
                                              ' comune '||rec_comu.COD_CMN||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure tracciato_nazioni is
   CURSOR sel_nazi IS
      select lpad(stte.stato_territorio,24,'0')                                 IDR_STA_NAZ
           , rpad(nvl(stte.sigla,'EE'),3)                                        SGL_NAZ
           , rpad(' ',4)                                                        COD_BLF
           , rpad(stte.denominazione,200)                                       DEN_NAZ
           , rpad(nvl(stte.desc_cittadinanza,' '),200)                          DEN_CIT
           , rpad(' ',3)                                                        COD_NAZ_ISTAT
           , rpad(nvl(stte.sigla,' '),3)                                        COD_NAZ_MCTC
       from  ad4_stati_territori stte
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Comuni
      for rec_nazi in sel_nazi loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Nazioni '||substr(rec_nazi.IDR_STA_NAZ,22,3);
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , w_cod_belfiore                  -- COD_ENTE
                  ||rec_nazi.IDR_STA_NAZ
                  ||rec_nazi.SGL_NAZ
                  ||rec_nazi.COD_BLF
                  ||rec_nazi.DEN_NAZ
                  ||rec_nazi.DEN_CIT
                  ||rec_nazi.COD_NAZ_ISTAT
                  ||rec_nazi.COD_NAZ_MCTC
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Nazioni '||
                                              ' stato '||substr(rec_nazi.IDR_STA_NAZ,22,3)||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure sit_strade is
   CURSOR sel_stra IS
      select rpad(nvl(com.sigla_cfis,' '),4)                                    COD_ENTE
           , lpad(to_char(arvi.cod_via),9,'0')                                  COD_STRADA
           , rpad(arvi.denom_uff,170)                                           DESCR_VIA
           , '19000101'                                                         DATA_INI_VAL
           , '99991231'                                                         DATA_FINE_VAL
       from  dati_generali       dage
           , ad4_comuni          com
           , archivio_vie        arvi
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Strade
      for rec_stra in sel_stra loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'SIT Strade '||rec_stra.COD_STRADA;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_stra.COD_ENTE
                  ||rec_stra.COD_STRADA
                  ||rec_stra.DESCR_VIA
                  ||rec_stra.DATA_INI_VAL
                  ||rec_stra.DATA_FINE_VAL
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in SIT Strade '||
                                              ' cod_strada '||rec_stra.COD_STRADA||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure sit_civici is
   CURSOR sel_civ IS
      select lpad(min(ciog.oggetto),9,'0')                                      COD_CIVICO
           , lpad(to_char(ciog.cod_via),9,'0')                                  COD_STRADA
           , lpad('0',9,'0')                                                    COD_EDIFICIO
           , lpad(to_char(ciog.num_civ),9,'0')                                  NUMERO
           , rpad(substr(nvl(ciog.suffisso,' '),1,4),4)                         ESPONENTE
           , rpad(' ',100)                                                      TIPO_CIVICO
           , ' '                                                                FLG_PRINCIPALE
           , rpad(' ',100)                                                      TIPO_INGRESSO
           , lpad('0',9,'0')                                                    COD_LOTTO
           , '19000101'                                                         DATA_INI_VAL
           , '99991231'                                                         DATA_FINE_VAL
       from  civici_oggetto      ciog
       where ciog.cod_via          is not null
         and ciog.num_civ          is not null
    group by ciog.cod_via
           , ciog.num_civ
           , ciog.suffisso
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Strade
      for rec_civ in sel_civ loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'SIT Civici '||rec_civ.COD_CIVICO;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , w_cod_belfiore           -- COD_ENTE
                  ||rec_civ.COD_CIVICO
                  ||rec_civ.COD_STRADA
                  ||rec_civ.COD_EDIFICIO
                  ||rec_civ.NUMERO
                  ||rec_civ.ESPONENTE
                  ||rec_civ.TIPO_CIVICO
                  ||rec_civ.FLG_PRINCIPALE
                  ||rec_civ.TIPO_INGRESSO
                  ||rec_civ.COD_LOTTO
                  ||rec_civ.DATA_INI_VAL
                  ||rec_civ.DATA_FINE_VAL
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in SIT Civici '||
                                              ' key '||rec_civ.COD_CIVICO||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure anagrafiche_soggetti is
   CURSOR sel_sogg IS
      select rpad('CFSOGG',10)                                                  TIP_RECORD
           , rpad(sogg.ni,30)                                                   ID_ORI_CFSOGG
           , decode(sogg.tipo
                   ,0,'P'
                   ,1,'D'
                   ,2,'P'
                   )                                                            TIP_SOG
           , rpad(cont.cod_fiscale,16)                                          COD_FIS
           , rpad(nvl(sogg.partita_iva,' '),11)                                 PAR_IVA
           , rpad(sogg.cognome,80)                                              COG_DENOM
           , substr(rpad(nvl(sogg.nome,' '),25),1,25)                           NOME
           , nvl(to_char(sogg.data_nas,'yyyymmdd'),rpad(' ',8))                 DAT_NSC_CST
           , nvl(sogg.sesso,' ')                                                SEX
           , rpad(nvl(comn.denominazione,' '),50)                               DES_LUO_NSC
           , rpad(nvl(pron.sigla,' '),3)                                        PRV_NSC
           , rpad(' ',8)                                                        DAT_INI_RES_SED
           , rpad(nvl(nvl(arvi.denom_uff,sogg.denominazione_via)
                     ,'INDIRIZZO ASSENTE')
                  ||decode(sogg.num_civ
                          ,null,''
                          ,' ,'||sogg.num_civ
                          )
                  ||decode(sogg.suffisso
                          ,null,''
                          ,'/'||sogg.suffisso
                          )
                  ||decode(sogg.interno
                          ,null,''
                          ,' Int. '||sogg.interno
                          )
                 , 200)                                                         DES_IND_RES_SED
           , lpad(nvl(to_char(nvl(sogg.cap,comR.cap)),' '),5)                   CAP_RES_SED
           , rpad(nvl(comR.denominazione,' '),50)                               DES_LUO_RES_SED
           , rpad(nvl(proR.sigla,' '),3)                                        PRV_RES_SED
           , rpad(nvl(lpad(comN.provincia_stato,3,'0')
                    ||lpad(comN.comune,3,'0')
                     ,' '),16)                                                  COD_LUO_NSC
           , rpad(nvl(lpad(comR.provincia_stato,3,'0')
                    ||lpad(comR.comune,3,'0')
                     ,'000000'),16)                                             COD_LUO_RES_SED
           , lpad(nvl(to_char(sogg.cod_via),'0'),9,'0')                         COD_VIA_RES_SED
           , lpad(nvl(to_char(sogg.num_civ),'0'),9,'0')                         NUM_CIV_RES_SED
           , rpad(nvl(to_char(sogg.suffisso),' '),4)                            ESP_CIV_RES_SED
           , rpad(' ',100)                                                      TIPO_CIV_RES_SED
           , lpad(nvl(substr(to_char(sogg.interno),1,3),'0'),3,'0')||'  '       NUM_INT_RES_SED
           , rpad(nvl(sogg.scala,' '),10)                                       NUM_SCA_RES_SED
           , rpad(nvl(sogg.piano,' '),10)                                       NUM_PIA_RES_SED
           , rpad(' ',10)                                                       NUM_LOT_RES_SED
           , rpad(' ',10)                                                       NUM_ISO_RES_SED
           , rpad(nvl(arvi.denom_uff,' '),200)                                  DES_VIA_RES_SED
           , rpad(' ',3)                                                        SGL_CIZ
           , rpad(' ',20)                                                       CIZ
           , decode(sogg.stato
                   ,50,'S'
                   ,' '
                   )                                                            FLAG_DEC
           , decode(sogg.stato
                   ,50,nvl(to_char(sogg.data_ult_eve,'yyyymmdd')
                          ,rpad(' ',8)
                          )
                   ,rpad(' ',8)
                   )                                                            DAT_CES
           , substr(rpad(nvl(sogg.note,' '),256),1,256)                         NOTE
           , rpad(' ',46)                                                       FILLER
       from  soggetti            sogg
           , contribuenti        cont
           , ad4_comuni          comN
           , ad4_provincie       proN
           , ad4_comuni          comR
           , ad4_PROVINCIE       proR
           , archivio_vie        arvi
      where cont.ni                   = sogg.ni
        and comN.provincia_stato  (+) = sogg.cod_pro_nas
        and comN.comune           (+) = sogg.cod_com_nas
        and proN.provincia        (+) = sogg.cod_pro_nas
        and comR.provincia_stato  (+) = sogg.cod_pro_res
        and comR.comune           (+) = sogg.cod_com_res
        and proR.provincia        (+) = sogg.cod_pro_res
        and arvi.cod_via          (+) = sogg.cod_via
     union
      select rpad('CFSOGG',10)                                                  TIP_RECORD
           , rpad(sogg.ni,30)                                                   ID_ORI_CFSOGG
           , decode(sogg.tipo
                   ,0,'P'
                   ,1,'D'
                   ,2,'P'
                   )                                                            TIP_SOG
           , rpad(nvl(sogg.cod_fiscale,' '),16)                                 COD_FIS
           , rpad(nvl(sogg.partita_iva,' '),11)                                 PAR_IVA
           , rpad(sogg.cognome,80)                                              COG_DENOM
           , substr(rpad(nvl(sogg.nome,' '),25),1,25)                           NOME
           , nvl(to_char(sogg.data_nas,'yyyymmdd'),rpad(' ',8))                 DAT_NSC_CST
           , nvl(sogg.sesso,' ')                                                SEX
           , rpad(nvl(comn.denominazione,' '),50)                               DES_LUO_NSC
           , rpad(nvl(pron.sigla,' '),3)                                        PRV_NSC
           , rpad(' ',8)                                                        DAT_INI_RES_SED
           , rpad(nvl(nvl(arvi.denom_uff,sogg.denominazione_via),' ')
                  ||decode(sogg.num_civ
                          ,null,''
                          ,' ,'||sogg.num_civ
                          )
                  ||decode(sogg.suffisso
                          ,null,''
                          ,'/'||sogg.suffisso
                          )
                  ||decode(sogg.interno
                          ,null,''
                          ,' Int. '||sogg.interno
                          )
                 , 200)                                                         DES_IND_RES_SED
           , lpad(nvl(to_char(nvl(sogg.cap,comR.cap)),' '),5)                   CAP_RES_SED
           , rpad(nvl(comR.denominazione,' '),50)                               DES_LUO_RES_SED
           , rpad(nvl(proR.sigla,' '),3)                                        PRV_RES_SED
           , rpad(nvl(lpad(comN.provincia_stato,3,'0')
                    ||lpad(comN.comune,3,'0')
                     ,' '),16)                                                  COD_LUO_NSC
           , rpad(nvl(lpad(comR.provincia_stato,3,'0')
                    ||lpad(comR.comune,3,'0')
                     ,' '),16)                                                  COD_LUO_RES_SED
           , lpad(nvl(to_char(sogg.cod_via),'0'),9,'0')                         COD_VIA_RES_SED
           , lpad(nvl(to_char(sogg.num_civ),'0'),9,'0')                         NUM_CIV_RES_SED
           , rpad(nvl(to_char(sogg.suffisso),' '),4)                            ESP_CIV_RES_SED
           , rpad(' ',100)                                                      TIPO_CIV_RES_SED
           , lpad(nvl(substr(to_char(sogg.interno),1,3),'0'),3,'0')||'  '       NUM_INT_RES_SED
           , rpad(nvl(sogg.scala,' '),10)                                       NUM_SCA_RES_SED
           , rpad(nvl(sogg.piano,' '),10)                                       NUM_PIA_RES_SED
           , rpad(' ',10)                                                       NUM_LOT_RES_SED
           , rpad(' ',10)                                                       NUM_ISO_RES_SED
           , rpad(nvl(arvi.denom_uff,' '),200)                                  DES_VIA_RES_SED
           , rpad(' ',3)                                                        SGL_CIZ
           , rpad(' ',20)                                                       CIZ
           , decode(sogg.stato
                   ,50,'S'
                   ,' '
                   )                                                            FLAG_DEC
           , decode(sogg.stato
                   ,50,nvl(to_char(sogg.data_ult_eve,'yyyymmdd')
                          ,rpad(' ',8)
                          )
                   ,rpad(' ',8)
                   )                                                            DAT_CES
           , substr(rpad(nvl(sogg.note,' '),256),1,256)                         NOTE
           , rpad(' ',46)                                                       FILLER
       from  soggetti            sogg
           , ad4_comuni          comN
           , ad4_provincie       proN
           , ad4_comuni          comR
           , ad4_PROVINCIE       proR
           , archivio_vie        arvi
      where comN.provincia_stato  (+) = sogg.cod_pro_nas
        and comN.comune           (+) = sogg.cod_com_nas
        and proN.provincia        (+) = sogg.cod_pro_nas
        and comR.provincia_stato  (+) = sogg.cod_pro_res
        and comR.comune           (+) = sogg.cod_com_res
        and proR.provincia        (+) = sogg.cod_pro_res
        and arvi.cod_via          (+) = sogg.cod_via
        and sogg.ni in (select sog2.ni_presso
                          from soggetti     sog2
                             , contribuenti con2
                         where con2.ni = sog2.ni
                           and sog2.ni_presso is not null
                        union
                        select sog3.ni
                          from soggetti         sog3
                             , pratiche_tributo prt3
                         where prt3.cod_fiscale_den = sog3.cod_fiscale
                           and prt3.tipo_tributo    = 'ICI'
                           and prt3.tipo_pratica    = 'D'
                       )
        and sogg.ni not in (select con3.ni
                              from contribuenti con3
                           )
        and sogg.cod_fiscale is not null
      ;
   CURSOR sel_sind IS
      select rpad('CFSOGGIND',10)                                               TIP_RECORD
           , rpad(sogg.ni,30)                                                   ID_ORI_CFSOGG
           , 'Z'                                                                TIP_IND
           , '19000101'                                                         DAT_INI_IND
           , '99991231'                                                         DAT_FIN_IND
           , rpad(' ',3)                                                        IDR_STA_IND
           , rpad(' ',200)                                                      DEN_STA_IND
           , rpad(nvl(lpad(sogg_ni.cod_pro_res,3,'0')
                    ||lpad(sogg_ni.cod_com_res,3,'0')
                     ,' '),16)                                                  COD_CMN_IND
           , rpad(nvl(comu.denominazione,' '),200)                              DEN_CMN_IND
           , rpad(' ',100)                                                      DEN_FRZ
           , rpad(nvl(prov.sigla,' '),3)                                        SIG_PRV
           , rpad(nvl(nvl(arvi.denom_uff,sogg_ni.denominazione_via),' ')
                  ||decode(sogg_ni.num_civ
                          ,null,''
                          ,' ,'||sogg_ni.num_civ
                          )
                  ||decode(sogg_ni.suffisso
                          ,null,''
                          ,'/'||sogg_ni.suffisso
                          )
                  ||decode(sogg_ni.interno
                          ,null,''
                          ,' Int. '||sogg_ni.interno
                          )
                 , 200)                                                         DEN_VIA_CMP
           , lpad(nvl(to_char(sogg_ni.cod_via),'0'),9,'0')                      COD_VIA
           , rpad(nvl(arvi.denom_uff,' '),200)                                  DEN_VIA
           , lpad(nvl(to_char(sogg_ni.num_civ),'0'),9,'0')                      NUM_CIV
           , rpad(nvl(to_char(sogg_ni.suffisso),' '),4)                         ESP_CIV
           , rpad(' ',100)                                                      TIP_CIV
           , lpad(nvl(substr(to_char(sogg_ni.interno),1,3),'0'),3,'0')||'  '    NUM_CIV_INT
           , rpad(nvl(sogg_ni.piano,' '),10)                                    PIA_IND
           , rpad(nvl(sogg_ni.scala,' '),10)                                    SCA_IND
           , rpad(' ',10)                                                       LOT_IND
           , rpad(' ',10)                                                       EDF_IND
           , nvl(lpad(to_char(sogg.cap),5,'0'),'     ')                         CAP_IND
           , rpad(sogg_ni.ni,30)                                                IDR_SOG_REC
           , rpad(nvl(replace(sogg_ni.cognome_nome,'/',' '),' '),305)           DEN_SOG_REC
       from  contribuenti        cont
           , soggetti            sogg
           , soggetti            sogg_ni
           , contribuenti        cont_ni
           , ad4_comuni          comu
           , ad4_PROVINCIE       prov
           , archivio_vie        arvi
       where cont.ni                   = sogg.ni
         and sogg.ni_presso            = sogg_ni.ni
         and sogg_ni.ni                = cont_ni.ni (+)
         and comu.provincia_stato  (+) = sogg_ni.cod_pro_res
         and comu.comune           (+) = sogg_ni.cod_com_res
         and prov.provincia        (+) = sogg_ni.cod_pro_res
         and arvi.cod_via          (+) = sogg_ni.cod_via
         and ( (    cont_ni.cod_fiscale is null
                and sogg_ni.cod_fiscale is not null
               )
               or
               ( cont_ni.cod_fiscale is not null
               )
             )
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Anagrafica soggetti
      for rec_sogg in sel_sogg loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Soggetti '||rec_sogg.COD_FIS;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_sogg.TIP_RECORD
                  ||w_cod_belfiore                 -- CODICE_ENTE
                  ||rec_sogg.ID_ORI_CFSOGG
                  ||rec_sogg.TIP_SOG
                  ||rec_sogg.COD_FIS
                  ||rec_sogg.PAR_IVA
                  ||rec_sogg.COG_DENOM
                  ||rec_sogg.NOME
                  ||rec_sogg.DAT_NSC_CST
                  ||rec_sogg.SEX
                  ||rec_sogg.DES_LUO_NSC
                  ||rec_sogg.PRV_NSC
                  ||rec_sogg.DAT_INI_RES_SED
                  ||rec_sogg.DES_IND_RES_SED
                  ||rec_sogg.CAP_RES_SED
                  ||rec_sogg.DES_LUO_RES_SED
                  ||rec_sogg.PRV_RES_SED
                  ||rec_sogg.COD_LUO_NSC
                  ||rec_sogg.COD_LUO_RES_SED
                  ||rec_sogg.COD_VIA_RES_SED
                  ||rec_sogg.NUM_CIV_RES_SED
                  ||rec_sogg.ESP_CIV_RES_SED
                  ||rec_sogg.TIPO_CIV_RES_SED
                  ||rec_sogg.NUM_INT_RES_SED
                  ||rec_sogg.NUM_SCA_RES_SED
                  ||rec_sogg.NUM_PIA_RES_SED
                  ||rec_sogg.NUM_LOT_RES_SED
                  ||rec_sogg.NUM_ISO_RES_SED
                  ||rec_sogg.DES_VIA_RES_SED
                  ||rec_sogg.SGL_CIZ
                  ||rec_sogg.CIZ
                  ||rec_sogg.FLAG_DEC
                  ||rec_sogg.DAT_CES
                  ||rec_sogg.NOTE
                  ||rec_sogg.FILLER
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Anagrafica Soggetti '||
                                              ' cf '||rec_sogg.COD_FIS||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
       -- Altri Indirizzi del Soggetto
      for rec_sind in sel_sind loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Soggetti Altri'||substr(rec_sind.ID_ORI_CFSOGG,1,7);
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_sind.TIP_RECORD
                  ||w_cod_belfiore             -- CODICE_ENTE
                  ||rec_sind.ID_ORI_CFSOGG
                  ||rec_sind.TIP_IND
                  ||rec_sind.DAT_INI_IND
                  ||rec_sind.DAT_FIN_IND
                  ||rec_sind.IDR_STA_IND
                  ||rec_sind.DEN_STA_IND
                  ||rec_sind.COD_CMN_IND
                  ||rec_sind.DEN_CMN_IND
                  ||rec_sind.DEN_FRZ
                  ||rec_sind.SIG_PRV
                  ||rec_sind.DEN_VIA_CMP
                  ||rec_sind.COD_VIA
                  ||rec_sind.DEN_VIA
                  ||rec_sind.NUM_CIV
                  ||rec_sind.ESP_CIV
                  ||rec_sind.TIP_CIV
                  ||rec_sind.NUM_CIV_INT
                  ||rec_sind.PIA_IND
                  ||rec_sind.SCA_IND
                  ||rec_sind.LOT_IND
                  ||rec_sind.EDF_IND
                  ||rec_sind.CAP_IND
                  ||rec_sind.IDR_SOG_REC
                  ||rec_sind.DEN_SOG_REC
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Altri Indirizzi Soggetti '||
                                              ' cf '||substr(rec_sind.ID_ORI_CFSOGG,1,7)||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure anagrafiche_oggetti is
   CURSOR sel_ogge IS
      select rpad('CFAOGG',10)                                                  TIP_RECORD
           , rpad(ogge.oggetto,30)                                              ID_ORI_CFAOGG
           , decode(ogge.tipo_oggetto
                   ,1,'T'
                   ,2,'T'
                   ,'F'
                   )                                                            TIP_OGG
           , rpad(nvl(nvl(arvi.denom_uff,ogge.indirizzo_localita)
                     ,'INDIRIZZO ASSENTE')
                  ||decode(ogge.num_civ
                          ,null,''
                          ,' ,'||ogge.num_civ
                          )
                  ||decode(ogge.suffisso
                          ,null,''
                          ,'/'||ogge.suffisso
                          )
                  ||decode(ogge.interno
                          ,null,''
                          ,' Int. '||ogge.interno
                          )
                 , 200)                                                         DES_IND
           , rpad(nvl(ogge.sezione,' '),3)                                      SEZ_CTS
           , rpad(nvl(ogge.foglio,' '),4)                                       FOG_CTS
           , rpad(nvl(ogge.numero,' '),5)                                       MAP_CTS
           , lpad('0',4,'0')                                                    DENOM_CTS
           , rpad(nvl(ogge.subalterno,' '),4)                                   SUB_CTS
           , rpad(nvl(ogge.zona,' '),3)                                         COD_ZON_CNS
           , rpad(nvl(ogge.partita,' '),8)                                      PAR_CNS
           , nvl(lpad(decode(length(to_char(ogge.anno_catasto))
                            ,1,'200'
                            ,2,decode(sign(30 - ogge.anno_catasto)
                                     ,1,'20'
                                     ,'19'
                                     )
                                ||to_char(ogge.anno_catasto)
                            ,to_char(ogge.anno_catasto)
                            )
                      ,4,'0'),'0000')                                           YEA_PRO_CTS
           , rpad(nvl(ogge.protocollo_catasto,' '),8)                           NUM_PRO_CTS
           , rpad(nvl(ogge.categoria_catasto,' '),3)                            CAT_CTS
           , rpad(nvl(ogge.classe_catasto,' '),2)                               CLS_CTS
           , rpad(nvl(ogge.scala,' '),10)                                       SCA
           , rpad(nvl(ogge.piano,' '),10)                                       PIA
           , rpad(' ',10)                                                       LOT_RES_SED
           , rpad(' ',10)                                                       ISO_RES_SED
           , lpad(nvl(ogge.cod_via,'0'),9,'0')                                  COD_VIA
           , lpad(nvl(to_char(ogge.num_civ),'0'),9,'0')                         NUM_CIV
           , rpad(nvl(to_char(ogge.suffisso),' '),4)                            ESP_CIV
           , rpad(' ',100)                                                      TIPO_CIV
           , lpad(nvl(substr(to_char(ogge.interno),1,3),'0'),3,'0')||'  '       NUM_INT
           , F_VALORE_OGGE(ogge.oggetto)                                        VAL_IMM_EU  -- COD_TIP_VAL
           , rpad(' ',50)                                                       PAR_RES_SED
           , rpad(' ',30)                                                       IDR_ORI_CFAOGG_ANA
           , lpad(to_char(
                decode(prat.tipo_tributo
                      ,'TARSU',nvl(ogge.tipo_oggetto,0)
                      ,0
                      )
                         ),9,'0')                                               TIP_OGG_RSU
           , rpad(nvl(ogge.note,' '),250)                                       NOTE
        from oggetti              ogge
           , archivio_vie         arvi
           , ( select ogpr.oggetto        oggetto
                    , max(prtr.tipo_tributo)   tipo_tributo
                 from oggetti_pratica  ogpr
                    , pratiche_tributo prtr
                where ogpr.pratica = prtr.pratica
                  and prtr.tipo_pratica in ('A','D')
                  and prtr.tipo_tributo in ('ICI','TARSU')
             group by ogpr.oggetto
             ) prat
       where arvi.cod_via          (+) = ogge.cod_via
         and prat.oggetto              = ogge.oggetto
        ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Anagrafica oggetti
      for rec_ogge in sel_ogge loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Oggetti '||rec_ogge.ID_ORI_CFAOGG;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_ogge.TIP_RECORD
                  ||w_cod_belfiore                 -- CODICE_ENTE
                  ||rec_ogge.ID_ORI_CFAOGG
                  ||rec_ogge.TIP_OGG
                  ||rec_ogge.DES_IND
                  ||rec_ogge.SEZ_CTS
                  ||rec_ogge.FOG_CTS
                  ||rec_ogge.MAP_CTS
                  ||rec_ogge.DENOM_CTS
                  ||rec_ogge.SUB_CTS
                  ||rec_ogge.COD_ZON_CNS
                  ||rec_ogge.PAR_CNS
                  ||rec_ogge.YEA_PRO_CTS
                  ||rec_ogge.NUM_PRO_CTS
                  ||rec_ogge.CAT_CTS
                  ||rec_ogge.CLS_CTS
                  ||rec_ogge.SCA
                  ||rec_ogge.PIA
                  ||rec_ogge.LOT_RES_SED
                  ||rec_ogge.ISO_RES_SED
                  ||rec_ogge.COD_VIA
                  ||rec_ogge.NUM_CIV
                  ||rec_ogge.ESP_CIV
                  ||rec_ogge.TIPO_CIV
                  ||rec_ogge.NUM_INT
                  ||rec_ogge.VAL_IMM_EU
                  ||rec_ogge.PAR_RES_SED
                  ||rec_ogge.IDR_ORI_CFAOGG_ANA
                  ||rec_ogge.TIP_OGG_RSU
                  ||rec_ogge.NOTE
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Anagrafica Oggetti '||
                                              ' ogg '||rec_ogge.ID_ORI_CFAOGG||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure denunce_ici is
   CURSOR sel_tdi IS
      select rpad('CFDENT',10)                                                  TIP_RECORD
           , '01001'                                                            SUB_TIP_DOC
           , lpad(prtr.pratica,18,'0')                                          ID_ORI_CFDENT
           , lpad(nvl(to_char(prtr.anno),'0'),4,'0')                            YEA_RIF
           , nvl(to_char(prtr.data,'yyyymmdd'),'19000101')                      DAT_DOC
           , rpad(to_char(cont.ni),30)                                          ID_ORI_CFSOGG_CNT
           , rpad(nvl(to_char(sogg_den.ni),' '),30)                             ID_ORI_CFSOGG_DEN
           , decode(sogg_den.ni
                   ,null,rpad(' ',50)
                   ,substr(rpad(nvl(tica.descrizione,' '),50),1,50)
                   )                                                            CRC_DEN
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , rpad(' ',20)                                                       REG_PRO
           , lpad('0',9,'0')                                                    PRG_PRO
           , rpad(' ',8)                                                        DATA_SYS_INS
           , rpad(' ',8)                                                        DATA_STM
           , lpad(nvl(to_char(prtr.anno),'0'),4,'0')                            YEA_DOC
           , substr(lpad(nvl(to_char(F_NUMERICO(prtr.numero)),'0'),9,'0'),1,9)  NUM_DOC
           , 'N'                                                                FLG_RIL
           , lpad('0',18,'0')                                                   COD_VRB
           , rpad(' ',20)                                                       NUM_VRB
           , '8'                                                                COD_TRB
           , rpad(' ',104)                                                      FILLER
           , prtr.pratica
        from pratiche_tributo     prtr
           , contribuenti         cont
           , tipi_carica          tica
           , soggetti             sogg_den
       where prtr.tipo_carica          = tica.tipo_carica (+)
         and prtr.tipo_tributo||''     = 'ICI'
         and prtr.tipo_pratica||''     = 'D'
         and prtr.cod_fiscale          = cont.cod_fiscale
         and prtr.cod_fiscale_den      = sogg_den.cod_fiscale (+)
         and nvl(prtr.anno,1900)      <= to_number(to_char(sysdate,'yyyy'))
         and exists (select 1
                       from oggetti_pratica ogpr
                      where ogpr.pratica = prtr.pratica
                    )
        ;
   CURSOR sel_deic(p_pratica number) IS
      select rpad('CFICDADE',10)                                                TIP_RECORD
           , lpad(ogpr.oggetto_pratica,18,'0')                                  ID_ORI_CFICDADE
           , lpad(ogpr.pratica,18,'0')                                          ID_ORI_CFDENT
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad('I',16)
                   ,rpad('C',16)
                   )                                                            TIP_QUADRO
           , rpad(ogpr.oggetto,30)                                              ID_ORI_CFAOGG
           , '00001'                                                            NUM_MOD
           , lpad(nvl(to_char(estrai_numerico(ogpr.num_ordine)),'0'),5,'0')     PRG_NUM_ORD
           , lpad(nvl(to_char(estrai_numerico(
                   substr(ogpr.num_ordine
                         ,length(to_char(estrai_numerico(ogpr.num_ordine))) +1
                         )
                                             )),'0'),5,'0')                     SOT_PRG_NUM_ORD
           , lpad(to_char(nvl(ogco.mesi_possesso,12)),2,'0')                    MESI_POS
           , decode(ogco.flag_possesso
                   ,'S','0'
                   ,'1'
                   )                                                            FLG_POS_3112
           , lpad(to_char(nvl(ogco.perc_possesso * 100, 0)),5,'0')              PRC_POS
           , decode(ogpr.tipo_oggetto
                   ,1,'1'
                   ,2,'2'
                   ,3,'3'
                   ,4,'4'
                   ,55,'3'
                   ,'4'
                   )                                                            CRT_IMM
           , rpad('3',16)                                                       COD_TIP_VAL
           , lpad(to_char(nvl(ogpr.valore * 100, 0)),12,'0')                    VAL_IMM_EU
           , decode(ogpr.imm_storico
                   ,'S','1'
                   ,'0'
                   )                                                            FLG_IMM_STO
           , lpad(to_char(nvl(ogco.detrazione * 100, 0)),12,'0')                IMM_DET_ABT_PRI_EU
           , decode(ogco.flag_ab_principale
                   ,'S','0'
                   ,'1'
                   )                                                            FLG_ABT_PRI_3112
           , lpad(to_char(nvl(ogco.mesi_esclusione, 0)),2,'0')                  MESI_ESE
           , decode(ogco.flag_esclusione
                   ,'S','0'
                   ,'1'
                   )                                                            FLG_ESE_3112
           , lpad(to_char(nvl(ogco.mesi_riduzione, 0)),2,'0')                   MESI_RID
           , decode(ogco.flag_riduzione
                   ,'S','0'
                   ,'1'
                   )                                                            FLG_RID_3112
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(' ',30)
                   ,rpad(to_char(cont_con.ni),30)
                   )                                                            ID_ORI_CFSOGG_RIF
           , '2'                                                                FLG_FRM
           , '00000'                                                            NUM_TOT_MOD
           , '2'                                                                FLG_TIT_ACQ
           , '2'                                                                FLG_TIT_CES
           , rpad(' ',200)                                                      DESC_UFF_REG
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale
                   ,rpad(nvl(nvl(arvi.denom_uff,ogge.indirizzo_localita),' ')
                        ||decode(ogge.num_civ
                                ,null,''
                                ,' ,'||ogge.num_civ
                                )
                        ||decode(ogge.suffisso
                                ,null,''
                                ,'/'||ogge.suffisso
                                )
                        ||decode(ogge.interno
                                ,null,''
                                ,' Int. '||ogge.interno
                                )
                        ,200
                        )
                   ,rpad(' ',200)
                   )                                                            OGG_DES_IND_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.sezione,' '),3)
                   ,rpad(' ',3)
                   )                                                            OGG_SEZ_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.foglio,' '),4)
                   ,rpad(' ',4)
                   )                                                            OGG_FOG_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.numero,' '),5)
                   ,rpad(' ',5)
                   )                                                            OGG_MAP_DIC
           , lpad('0',4,'0')                                                    OGG_DENOM_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.subalterno,' '),4)
                   ,rpad(' ',4)
                   )                                                            OGG_SUB_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.categoria_catasto,' '),3)
                   ,rpad(' ',3)
                   )                                                            OGG_CAT_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.classe_catasto,' '),2)
                   ,rpad(' ',2)
                   )                                                            OGG_CLS_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale
                   ,nvl(lpad(
                          decode(length(to_char(ogge.anno_catasto))
                                ,1,'200'||to_char(ogge.anno_catasto)
                                ,2,decode(sign(30 - ogge.anno_catasto)
                                         ,1,'20'
                                         ,'19'
                                         )
                                    ||to_char(ogge.anno_catasto)
                                ,to_char(ogge.anno_catasto)
                                )
                          ,4,'0'),'0000')
                   ,lpad('0',4,'0')
                   )                                                            OGG_YEA_PRO_DIC
           , decode(prtr.cod_fiscale
                   ,ogco.cod_fiscale,rpad(nvl(ogge.protocollo_catasto,' '),8)
                   ,rpad(' ',8)
                   )                                                            OGG_NUM_PRO_DIC
           , rpad(' ',105)                                                      FILLER
        from oggetti_pratica      ogpr
           , oggetti_contribuente ogco
           , pratiche_tributo     prtr
           , oggetti              ogge
           , archivio_vie         arvi
           , contribuenti         cont_con
       where ogpr.pratica              = p_pratica
         and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and ogpr.pratica              = prtr.pratica
         and ogpr.oggetto              = ogge.oggetto
         and arvi.cod_via          (+) = ogge.cod_via
         and ogco.cod_fiscale          = cont_con.cod_fiscale
        ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Testata Denunce ICI
      for rec_tdi in sel_tdi loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Testata DEnunce ICI '||rec_tdi.ID_ORI_CFDENT;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_tdi.TIP_RECORD
                  ||w_cod_belfiore                   -- CODICE_ENTE
                  ||rec_tdi.SUB_TIP_DOC
                  ||rec_tdi.ID_ORI_CFDENT
                  ||rec_tdi.YEA_RIF
                  ||rec_tdi.DAT_DOC
                  ||rec_tdi.ID_ORI_CFSOGG_CNT
                  ||rec_tdi.ID_ORI_CFSOGG_DEN
                  ||rec_tdi.CRC_DEN
                  ||rec_tdi.NUM_PRO
                  ||rec_tdi.YEA_PRO
                  ||rec_tdi.REG_PRO
                  ||rec_tdi.PRG_PRO
                  ||rec_tdi.DATA_SYS_INS
                  ||rec_tdi.DATA_STM
                  ||rec_tdi.YEA_DOC
                  ||rec_tdi.NUM_DOC
                  ||rec_tdi.FLG_RIL
                  ||rec_tdi.COD_VRB
                  ||rec_tdi.NUM_VRB
                  ||rec_tdi.COD_TRB
                  ||rec_tdi.FILLER
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Testata Denunce ICI '||
                                              ' prat '||rec_tdi.ID_ORI_CFDENT||
                                              ' ('||sqlerrm||')');
         end;
         -- Denunce ICI
         for rec_deic in sel_deic(rec_tdi.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Den. ICI '||rec_deic.ID_ORI_CFICDADE;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_deic.TIP_RECORD
                     ||w_cod_belfiore                    -- CODICE_ENTE
                     ||rec_deic.ID_ORI_CFICDADE
                     ||rec_deic.ID_ORI_CFDENT
                     ||rec_deic.TIP_QUADRO
                     ||rec_deic.ID_ORI_CFAOGG
                     ||rec_deic.NUM_MOD
                     ||rec_deic.PRG_NUM_ORD
                     ||rec_deic.SOT_PRG_NUM_ORD
                     ||rec_deic.MESI_POS
                     ||rec_deic.FLG_POS_3112
                     ||rec_deic.PRC_POS
                     ||rec_deic.CRT_IMM
                     ||rec_deic.COD_TIP_VAL
                     ||rec_deic.VAL_IMM_EU
                     ||rec_deic.FLG_IMM_STO
                     ||rec_deic.IMM_DET_ABT_PRI_EU
                     ||rec_deic.FLG_ABT_PRI_3112
                     ||rec_deic.MESI_ESE
                     ||rec_deic.FLG_ESE_3112
                     ||rec_deic.MESI_RID
                     ||rec_deic.FLG_RID_3112
                     ||rec_deic.ID_ORI_CFSOGG_RIF
                     ||rec_deic.FLG_FRM
                     ||rec_deic.NUM_TOT_MOD
                     ||rec_deic.FLG_TIT_ACQ
                     ||rec_deic.FLG_TIT_CES
                     ||rec_deic.DESC_UFF_REG
                     ||rec_deic.OGG_DES_IND_DIC
                     ||rec_deic.OGG_SEZ_DIC
                     ||rec_deic.OGG_FOG_DIC
                     ||rec_deic.OGG_MAP_DIC
                     ||rec_deic.OGG_DENOM_DIC
                     ||rec_deic.OGG_SUB_DIC
                     ||rec_deic.OGG_CAT_DIC
                     ||rec_deic.OGG_CLS_DIC
                     ||rec_deic.OGG_YEA_PRO_DIC
                     ||rec_deic.OGG_NUM_PRO_DIC
                     ||rec_deic.FILLER
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Dettaglio Den. ICI '||
                                                 ' ogpr '||rec_deic.ID_ORI_CFICDADE||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
      end loop;
   end;
   procedure aliquote_speciali_ici is
   CURSOR sel_alsp IS
      select rpad('CFDENT',10)                                                  TIP_RECORD_TESTATA
           , '03001'                                                            SUB_TIP_DOC
           , substr(to_char(alog.dal,'yyyymm'),3,4)||lpad(to_char(cont.ni),7,'0')
             ||lpad(to_char(ogpr.oggetto_pratica),7,'0')                        ID_ORI_CFDENT
           , to_char(alog.dal,'yyyy')                                           YEA_RIF
           , to_char(alog.dal,'yyyymmdd')                                       DAT_DOC
           , rpad(to_char(cont.ni),30)                                          ID_ORI_CFSOGG_CNT
           , rpad(' ',30)                                                       ID_ORI_CFSOGG_DEN
           , rpad(' ',50)                                                       CRC_DEN
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , rpad(' ',20)                                                       REG_PRO
           , lpad('0',9,'0')                                                    PRG_PRO
           , rpad(' ',8)                                                        DATA_SYS_INS
           , rpad(' ',8)                                                        DATA_STM
           , to_char(alog.dal,'yyyy')                                           YEA_DOC
           , lpad('0',9)                                                        NUM_DOC
           , 'S'                                                                FLG_RIL
           , lpad('0',18,'0')                                                   COD_VRB
           , rpad(' ',20)                                                       NUM_VRB
           , '8'                                                                COD_TRB
           , rpad(' ',104)                                                       FILLER_TESTATA
           , rpad('CFICDAAS',10)                                                TIP_RECORD
           , substr(to_char(alog.dal,'yyyymm'),3,4)||lpad(to_char(cont.ni),7,'0')
             ||lpad(to_char(ogpr.oggetto_pratica),7,'0')                        ID_ORI_CFICDAAS
           , rpad(ogpr.oggetto,30)                                              ID_ORI_CFAOGG
           , to_char(alog.dal,'yyyymmdd')                                       DAT_INI_VAL
           , lpad('0',15,'0')                                                   NUM_DET_ABT_PRI
           , lpad('0',15,'0')                                                   DEN_DET_ABT_PRI
           , rpad(' ',7)                                                        PERC_DETRAZ
           , decode(alog.tipo_aliquota
                   ,2,rpad('S',16)
                   ,rpad(to_char(alog.tipo_aliquota),16)
                   )                                                            COD_ALIC
           , to_char(alog.al,'yyyymmdd')                                        DAT_FIN_VAL
           , rpad(cont.ni,30)                                                   ID_ORI_CFSOGG
           , rpad(' ',408)                                                      FILLER
        from oggetti_pratica      ogpr
           , contribuenti         cont
           , aliquote_ogco        alog
       where ogpr.oggetto_pratica      = alog.oggetto_pratica
         and alog.cod_fiscale          = cont.cod_fiscale
       union
      select rpad('CFDENT',10)                                                  TIP_RECORD_TESTATA
           , '03001'                                                            SUB_TIP_DOC
           , substr(to_char(deog.anno),3,2)||'00'||lpad(to_char(cont.ni),7,'0')
             ||lpad(to_char(ogpr.oggetto_pratica),7,'0')                        ID_ORI_CFDENT
           , to_char(deog.anno)                                                 YEA_RIF
           , to_char(deog.anno)||'0101'                                         DAT_DOC
           , rpad(to_char(cont.ni),30)                                          ID_ORI_CFSOGG_CNT
           , rpad(' ',30)                                                       ID_ORI_CFSOGG_DEN
           , rpad(' ',50)                                                       CRC_DEN
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , rpad(' ',20)                                                       REG_PRO
           , lpad('0',9,'0')                                                    PRG_PRO
           , rpad(' ',8)                                                        DATA_SYS_INS
           , rpad(' ',8)                                                        DATA_STM
           , to_char(deog.anno)                                                 YEA_DOC
           , lpad('0',9)                                                        NUM_DOC
           , 'S'                                                                FLG_RIL
           , lpad('0',18,'0')                                                   COD_VRB
           , rpad(' ',20)                                                       NUM_VRB
           , '8'                                                                COD_TRB
           , rpad(' ',104)                                                       FILLER_TESTATA
           , rpad('CFICDAAS',10)                                                TIP_RECORD
           , substr(to_char(deog.anno),3,2)||'00'||lpad(to_char(cont.ni),7,'0')
             ||lpad(to_char(ogpr.oggetto_pratica),7,'0')                        ID_ORI_CFICDAAS
           , rpad(ogpr.oggetto,30)                                              ID_ORI_CFAOGG
           , to_char(deog.anno)||'0101'                                         DAT_INI_VAL
           , lpad(to_char(deog.detrazione * 100 ),15,'0')                       NUM_DET_ABT_PRI
           , lpad('100',15,'0')                                                 DEN_DET_ABT_PRI
           , rpad(' ',7)                                                        PERC_DETRAZ
           , rpad('S',16)                                                       COD_ALIC
           , to_char(deog.anno)||'1231'                                         DAT_FIN_VAL
           , rpad(cont.ni,30)                                                   ID_ORI_CFSOGG
           , rpad(' ',408)                                                      FILLER
        from oggetti_pratica      ogpr
           , contribuenti         cont
           , detrazioni_ogco      deog
       where ogpr.oggetto_pratica      = deog.oggetto_pratica
         and deog.cod_fiscale          = cont.cod_fiscale
        ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      for rec_alsp in sel_alsp loop
         -- Testata Aliquote Speciali ICI
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Testata Aliquote Speciali ICI '||rec_alsp.ID_ORI_CFDENT;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_alsp.TIP_RECORD_TESTATA
                  ||w_cod_belfiore                     -- CODICE_ENTE
                  ||rec_alsp.SUB_TIP_DOC
                  ||rec_alsp.ID_ORI_CFDENT
                  ||rec_alsp.YEA_RIF
                  ||rec_alsp.DAT_DOC
                  ||rec_alsp.ID_ORI_CFSOGG_CNT
                  ||rec_alsp.ID_ORI_CFSOGG_DEN
                  ||rec_alsp.CRC_DEN
                  ||rec_alsp.NUM_PRO
                  ||rec_alsp.YEA_PRO
                  ||rec_alsp.REG_PRO
                  ||rec_alsp.PRG_PRO
                  ||rec_alsp.DATA_SYS_INS
                  ||rec_alsp.DATA_STM
                  ||rec_alsp.YEA_DOC
                  ||rec_alsp.NUM_DOC
                  ||rec_alsp.FLG_RIL
                  ||rec_alsp.COD_VRB
                  ||rec_alsp.NUM_VRB
                  ||rec_alsp.COD_TRB
                  ||rec_alsp.FILLER_TESTATA
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Testata Aliquote Speciali ICI '||
                                              ' key '||rec_alsp.ID_ORI_CFICDAAS||
                                              ' ('||sqlerrm||')');
         end;
         -- Aliquote Speciali ICI
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Dettaglio Aliq.Spec.ICI '||rec_alsp.ID_ORI_CFICDAAS;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_alsp.TIP_RECORD
                  ||w_cod_belfiore                   -- CODICE_ENTE
                  ||rec_alsp.ID_ORI_CFICDAAS
                  ||rec_alsp.ID_ORI_CFDENT
                  ||rec_alsp.ID_ORI_CFAOGG
                  ||rec_alsp.DAT_INI_VAL
                  ||rec_alsp.NUM_DET_ABT_PRI
                  ||rec_alsp.DEN_DET_ABT_PRI
                  ||rec_alsp.PERC_DETRAZ
                  ||rec_alsp.COD_ALIC
                  ||rec_alsp.DAT_FIN_VAL
                  ||rec_alsp.ID_ORI_CFSOGG
                  ||rec_alsp.FILLER
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Dettaglio Aliq. Spec. ICI '||
                                              ' key: '||rec_alsp.ID_ORI_CFICDAAS||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure detrazioni_ici is
   CURSOR sel_ulde IS
      select rpad('CFDENT',10)                                                  TIP_RECORD_TESTATA
           , '03101'                                                            SUB_TIP_DOC
           , lpad(to_char(made.anno)
                  ||lpad(to_char(cont.ni),8,'0')
                 ,18,'0')                                                       ID_ORI_CFDENT
           , to_char(made.anno)                                                 YEA_RIF
           , to_char(made.anno)||'0101'                                         DAT_DOC
           , rpad(to_char(cont.ni),30)                                          ID_ORI_CFSOGG_CNT
           , rpad(' ',30)                                                       ID_ORI_CFSOGG_DEN
           , rpad(' ',50)                                                       CRC_DEN
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , rpad(' ',20)                                                       REG_PRO
           , lpad('0',9,'0')                                                    PRG_PRO
           , rpad(' ',8)                                                        DATA_SYS_INS
           , rpad(' ',8)                                                        DATA_STM
           , to_char(made.anno)                                                 YEA_DOC
           , lpad('0',9)                                                        NUM_DOC
           , 'S'                                                                FLG_RIL
           , lpad('0',18,'0')                                                   COD_VRB
           , rpad(' ',20)                                                       NUM_VRB
           , '8'                                                                COD_TRB
           , rpad(' ',104)                                                      FILLER_TESTATA
           , rpad('CFICDAUD',10)                                                TIP_RECORD        -- CFICDAUD
           , lpad(to_char(made.anno)
                  ||lpad(to_char(cont.ni),8,'0')
                 ,18,'0')                                                       ID_ORI_CFICDAUD
           , to_char(made.anno)||'0101'                                         DAT_INI_VAL
           , to_char(made.anno)||'1231'                                         DAT_FIN_VAL
           , rpad(to_char(made.anno)
                  ||lpad(to_char(cont.ni),8,'0')
                 ,16)                                                           COD_TIP_UDETER
           , rpad(' ',16)                                                       COD_TIP_UDETER_2
           , rpad(' ',16)                                                       COD_TIP_UDETER_3
           , rpad(' ',16)                                                       COD_RID
           , lpad(f_ulteriore_detrazione(made.anno
                                        ,made.cod_fiscale
                                        ,made.detrazione
                                        ) * 100
                 ,14,'0')                                                       IMP_DTZ
           , rpad(' ',88)                                                       FILLER
        from contribuenti         cont
           , maggiori_detrazioni  made
       where made.cod_fiscale          = cont.cod_fiscale
         and made.motivo_detrazione not in (97,98,99)
         and nvl(made.detrazione,0) > 0
        ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      for rec_ulde in sel_ulde loop
         -- Solo se l'ulteriore detrazione calcolata è maggiore di 0 inserisco il record
         if to_number(rec_ulde.IMP_DTZ) > 0 then
            -- Testata Ulteriori Detrazioni
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Testata Ulteriori Detrazioni '||rec_ulde.ID_ORI_CFICDAUD;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_ulde.TIP_RECORD_TESTATA
                     ||w_cod_belfiore                     -- CODICE_ENTE
                     ||rec_ulde.SUB_TIP_DOC
                     ||rec_ulde.ID_ORI_CFDENT
                     ||rec_ulde.YEA_RIF
                     ||rec_ulde.DAT_DOC
                     ||rec_ulde.ID_ORI_CFSOGG_CNT
                     ||rec_ulde.ID_ORI_CFSOGG_DEN
                     ||rec_ulde.CRC_DEN
                     ||rec_ulde.NUM_PRO
                     ||rec_ulde.YEA_PRO
                     ||rec_ulde.REG_PRO
                     ||rec_ulde.PRG_PRO
                     ||rec_ulde.DATA_SYS_INS
                     ||rec_ulde.DATA_STM
                     ||rec_ulde.YEA_DOC
                     ||rec_ulde.NUM_DOC
                     ||rec_ulde.FLG_RIL
                     ||rec_ulde.COD_VRB
                     ||rec_ulde.NUM_VRB
                     ||rec_ulde.COD_TRB
                     ||rec_ulde.FILLER_TESTATA
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Testata Ulteriori Detrazioni '||
                                                 ' key '||rec_ulde.ID_ORI_CFICDAUD||
                                                 ' ('||sqlerrm||')');
            end;
            -- Dettaglio Ulteriori Detrazioni
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Ulteriori Detrazioni '||rec_ulde.ID_ORI_CFICDAUD;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_ulde.TIP_RECORD
                     ||w_cod_belfiore                   -- CODICE_ENTE
                     ||rec_ulde.ID_ORI_CFICDAUD
                     ||rec_ulde.ID_ORI_CFDENT
                     ||rec_ulde.DAT_INI_VAL
                     ||rec_ulde.DAT_FIN_VAL
                     ||rec_ulde.COD_TIP_UDETER
                     ||rec_ulde.COD_TIP_UDETER_2
                     ||rec_ulde.COD_TIP_UDETER_3
                     ||rec_ulde.COD_RID
                     ||rec_ulde.IMP_DTZ
                     ||rec_ulde.FILLER
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Dettaglio Ulteriori Detrazioni '||
                                                 ' key: '||rec_ulde.ID_ORI_CFICDAUD||
                                                 ' ('||sqlerrm||')');
            end;
         end if;
      end loop;
   end;
   procedure versamenti_ici is
   CURSOR sel_vers IS
      select rpad('CFVERS',10)                                                  TIP_RECORD
           , decode(vers.pratica
                   ,null,1
                   ,2
                   )                                                            TIP_VRS
           , '00'||lpad(cont.ni,8,'0')
             ||decode(length(to_char(vers.anno))
                     ,1,'200'||to_char(vers.anno)
                     ,2,decode(30 - vers.anno
                              ,1,'20'
                              ,'19'
                              )||to_char(vers.anno)
                      ,to_char(vers.anno)
                      )
             ||lpad(vers.sequenza,4,'0')                                        ID_ORI_CFVERS
           , lpad('0',18,'0')                                                   NUM_REG
           , decode(length(to_char(vers.anno))
                   ,1,'200'||to_char(vers.anno)
                   ,2,decode(30 - vers.anno
                            ,1,'20'
                            ,'19'
                            )||to_char(vers.anno)
                   ,to_char(vers.anno)
                   )                                                            YEA_REG
           , nvl(to_char(vers.data_reg,'yyyymmdd'),rpad(' ',8))                 DAT_REG
           , rpad(cont.ni,30)                                                   ID_ORI_CFSOGG
           , nvl(to_char(vers.data_pagamento,'yyyymmdd'),rpad(' ',8))           DAT_VERS
           , decode(length(to_char(vers.anno))
                   ,1,'200'||to_char(vers.anno)
                   ,2,decode(30 - vers.anno
                            ,1,'20'
                            ,'19'
                            )||to_char(vers.anno)
                   ,to_char(vers.anno)
                   )                                                            YEA_RIF
           , lpad(to_char(nvl(vers.importo_versato,0) * 100),12,'0')            IMP_PAG_EU
           , decode(vers.tipo_versamento
                   ,'A','00001'
                   ,'S','00002'
                   ,'U','00003'
                   ,'00000'
                   )                                                            NUM_RAT
           , lpad(to_char(nvl(vers.terreni_agricoli,0) * 100),12,'0')           IMP_TER_AGR
           , lpad(to_char(nvl(vers.aree_fabbricabili,0) * 100),12,'0')          IMP_ARE_FAB
           , lpad(to_char(nvl(vers.ab_principale,0) * 100),12,'0')              IMP_ABI_PRI
           , lpad(to_char(nvl(vers.altri_fabbricati,0) * 100),12,'0')           IMP_ALT_FAB
           , lpad(to_char(nvl(vers.detrazione,0) * 100),12,'0')                 IMP_DETR
           , lpad(to_char(nvl(vers.fabbricati,0)),4,'0')                        NUM_FAB
           , decode(prtr.tipo_pratica
                   ,'V','1'
                   ,'0'
                   )                                                            FLG_RAV_OPE
           , decode(prtr.tipo_pratica
                   ,'V',lpad(to_char(
                          f_importi_ravvedimento_ici(prtr.pratica,'INT') * 100
                                    ),11,'0')
                   ,lpad('0',11,'0')
                   )                                                            IMP_INT_RAV_OPE
           , decode(prtr.tipo_pratica
                   ,'V',lpad(to_char(
                          f_importi_ravvedimento_ici(prtr.pratica,'SAN') * 100
                                    ),11,'0')
                   ,lpad('0',11,'0')
                   )                                                            IMP_SAN_RAV_OPE
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(prtr.numero,12,'0')
                   )                                                            NUM_DOC
           , decode(prtr.tipo_pratica
                   ,'V',rpad(' ',8)
                   ,null,rpad(' ',8)
                   ,nvl(to_char(prtr.data,'yyyymmdd'),rpad(' ',8))
                   )                                                            DAT_DOC
           , rpad(decode(vers.fonte
                        ,9,'9'     -- F24
                        ,2,'10'    -- Concessionario
                        ,10,'11'   -- Portale
                        ,' '       -- Altro
                        ),16)                                                   TIP_CAN
           , lpad('0',12,'0')                                                   IMP_CMS_CNC
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(to_char(
                           f_importi_violazioni_ici(prtr.pratica,'IMP') * 100
                                ,'00000000000'),12,'0')
                   )                                                            IMP_DOV_VLZ
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(to_char(
                           f_importi_violazioni_ici(prtr.pratica,'INT') * 100
                                ,'00000000000'),12,'0')
                   )                                                            IMP_INT_VLZ
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(to_char(
                           f_importi_violazioni_ici(prtr.pratica,'SAN') * 100
                                ,'00000000000'),12,'0')
                   )                                                            IMP_SNZ_VLZ
           , rpad(' ',30)                                                       CON_COR_CON
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',18,'0')
                   ,null,lpad('0',18,'0')
                   ,lpad(to_char(prtr.pratica),18,'0')
                   )                                                            ID_ORI_CFPRVD
           , rpad(' ',18)                                                       COD_OT
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(to_char(
                            f_importi_violazioni_ici(prtr.pratica,'PEP') * 100
                                ),12,'0')
                   )                                                            IMP_PEC_VLZ
           , decode(prtr.tipo_pratica
                   ,'V',lpad('0',12,'0')
                   ,null,lpad('0',12,'0')
                   ,lpad(to_char(
                            f_importi_violazioni_ici(prtr.pratica,'SPE') * 100
                                ),12,'0')
                   )                                                            IMP_SPS_EU
           , to_char(vers.data_pagamento,'yyyymmdd')                            DAT_ESTR_CONT
           , lpad('0',12,'0')                                                   IMP_CRED_EU
           , lpad('0',18,'0')                                                   ID_ORI_CFDENT
           , rpad(' ',236)                                                      FILLER
        from versamenti        vers
           , contribuenti      cont
           , pratiche_tributo  prtr
       where vers.tipo_tributo||'' = 'ICI'
         and cont.cod_fiscale      = vers.cod_fiscale
         and vers.pratica          = prtr.pratica (+)
         and nvl(vers.importo_versato,0) > 0    -- Non estraggo i versamenti negativi
         and vers.anno       between to_number(to_char(sysdate,'yyyy')) - 5
                                 and to_number(to_char(sysdate,'yyyy'))
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(80);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
              , rpad(nvl(com.denominazione ,' '),80)
           into w_cod_belfiore
              , w_comune_desc
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Versamenti Ici
      for rec_vers in sel_vers loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Versamenti Ici '||rec_vers.ID_ORI_CFVERS;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_vers.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_vers.TIP_VRS
                  ||rec_vers.ID_ORI_CFVERS
                  ||rec_vers.NUM_REG
                  ||rec_vers.YEA_REG
                  ||rec_vers.DAT_REG
                  ||rec_vers.ID_ORI_CFSOGG
                  ||rec_vers.DAT_VERS
                  ||rec_vers.YEA_RIF
                  ||rec_vers.IMP_PAG_EU
                  ||rec_vers.NUM_RAT
                  ||rec_vers.IMP_TER_AGR
                  ||rec_vers.IMP_ARE_FAB
                  ||rec_vers.IMP_ABI_PRI
                  ||rec_vers.IMP_ALT_FAB
                  ||rec_vers.IMP_DETR
                  ||rec_vers.NUM_FAB
                  ||rec_vers.FLG_RAV_OPE
                  ||rec_vers.IMP_INT_RAV_OPE
                  ||rec_vers.IMP_SAN_RAV_OPE
                  ||rec_vers.NUM_DOC
                  ||rec_vers.DAT_DOC
                  ||rec_vers.TIP_CAN
                  ||rec_vers.IMP_CMS_CNC
                  ||rec_vers.IMP_DOV_VLZ
                  ||rec_vers.IMP_INT_VLZ
                  ||rec_vers.IMP_SNZ_VLZ
                  ||rec_vers.CON_COR_CON
                  ||w_comune_desc                   -- DES_CMN_UBI_IMM
                  ||rec_vers.ID_ORI_CFPRVD
                  ||rec_vers.COD_OT
                  ||rec_vers.IMP_PEC_VLZ
                  ||rec_vers.IMP_SPS_EU
                  ||rec_vers.DAT_ESTR_CONT
                  ||rec_vers.IMP_CRED_EU
                  ||rec_vers.ID_ORI_CFDENT
                  ||rec_vers.FILLER
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Versamenti ICI '||
                                              ' key: '||rec_vers.ID_ORI_CFVERS||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure provvedimenti_ici is
   CURSOR sel_prov IS
      select rpad('CFPRVD',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , lpad(to_char(cont.ni),30,'0')                                      ID_ORI_CFSOGG
           , '00008'                                                            COD_TRB
           , decode(prtr.tipo_pratica
                   ,'L',rpad('LI',16)
                   ,rpad(f_tipo_accertamento(prtr.pratica),16)
                   )                                                            TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , lpad(nvl(f_numerico(prtr.numero),0),9,'0')                         NUM_PRV
           , rpad(' ',20)                                                       REG_PRO
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , lpad('0',18,'0')                                                   PRG_PRO
           , rpad(' ',8)                                                        DAT_PRO
           , nvl(to_char(prtr.data,'yyyymmdd'),to_char(prtr.anno)||'0101')      DAT_GEN
           , to_char(prtr.anno)                                                 YEA_RIF
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SPE') * 100
                    ,'S0000000000')                                             IMP_SPS
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'IMP') * 100
                    ,'S0000000000000')                                          IMP_TOT
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'INT') * 100
                    ,'S0000000000000')                                          INT_TOT
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SAN') * 100
                    ,'S0000000000000')                                          SNZ_TOT
           , to_char(
                nvl(prtr.importo_totale,0) * 100
                    ,'S0000000000000')                                          DOV_TOT
           , decode(sign(nvl(prtr.importo_totale,0))
                   ,-1,rpad('N',16)
                   ,rpad('P',16)
                   )                                                            TIP_IMP
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SANRID') * 100
                    ,'S0000000000000')                                          SNZ_RID_TOT
           , to_char(
                nvl(prtr.importo_ridotto,0) * 100
                    ,'S0000000000000')                                          DOV_RID_TOT
           , lpad('0',14,'0')                                                   IMP_ADD_P
           , lpad('0',14,'0')                                                   IMP_ADD_C
           , lpad('1',9,'0')                                                    VRS
           , rpad(' ',8)                                                        DAT_STA
           , decode(prtr.stato_accertamento
                   ,'A',rpad('A',16)
                   ,'D',decode(prtr.data_notifica
                              ,null,rpad('V',16)
                              ,rpad('N',16)
                              )
                   ,null,decode(prtr.data_notifica
                               ,null,rpad('E',16)
                               ,rpad('N',16)
                               )
                   ,rpad(' ',16)
                   )                                                            COD_STA
           , nvl(to_char(prtr.data,'yyyymmdd'),to_char(prtr.anno)||'0101')      DAT_ELA
           , rpad(' ',8)                                                        DAT_VAL
           , rpad(' ',8)                                                        DAT_SOS
           , rpad(' ',8)                                                        DAT_ANN
           , nvl(to_char(prtr.data_notifica,'yyyymmdd'),rpad(' ',8))            DAT_NOT
           , rpad(' ',16)                                                       COD_MOT_EMI
           , rpad(substr(nvl(replace(replace(prtr.note,chr(13)||chr(10),' ')
                                    ,chr(9),' ')
                            ,' '),1,250),250)                                   NOTE
           , rpad(' ',8)                                                        DAT_STM
           , rpad(' ',16)                                                       TIP_EMI_COO
           , rpad(' ',16)                                                       COD_EMI_COO
           , rpad(' ',18)                                                       COD_OT
           , lpad('0',18,'0')                                                   ID_ORI_CFPRVD_CUM
           , lpad('0',18,'0')                                                   ID_ORI_CFDENT_QUIR
           , rpad(' ',16)                                                       COD_STA_PRC_ADS
           , rpad(' ',8)                                                        DAT_RIC_ADS
           , rpad(' ',8)                                                        DAT_CNF_ADS
           , rpad(' ',8)                                                        DAT_PRF_ADS
           , lpad('0',4,'0')                                                    YEA_PRO_RIC_ADS
           , rpad(' ',8)                                                        NUM_PRO_RIC_ADS
           , rpad(' ',20)                                                       REG_PRO_RIC_ADS
           , lpad('0',18,'0')                                                   ID_ORI_ULT_RIC
           , 'N'                                                                FLG_SOS_RUO
           , rpad(' ',16)                                                       COD_MOT_SOS_RUO
           , lpad('0',18,'0')                                                   ID_ORI_ELA_RUO
           , rpad(' ',8)                                                        DAT_PREC_RIC
           , rpad(' ',8)                                                        FLG_ADE_FORM
           , rpad(' ',8)                                                        DAT_ADE_FORM
           , rpad(' ',14)                                                       TMS_TIME_INS
           , rpad(' ',30)                                                       COD_UTE_INS
           , rpad(to_char(prtr.data_variazione,'yyyymmddhh24miss'),14)          TMS_TIME_VAR
           , rpad(prtr.utente,30)                                               COD_UTE_VAR
           , prtr.pratica
        from contribuenti      cont
           , pratiche_tributo  prtr
       where cont.cod_fiscale      = prtr.cod_fiscale
         and prtr.tipo_tributo||'' = 'ICI'
         and prtr.tipo_pratica   = 'A'
         and prtr.tipo_evento   <> 'T'
         and exists (select 1
                       from sanzioni_pratica sapr
                      where sapr.pratica  = prtr.pratica
                    )
    union
      select rpad('CFPRVD',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , lpad(to_char(cont.ni),30,'0')                                      ID_ORI_CFSOGG
           , '00008'                                                            COD_TRB
           , decode(prtr.tipo_pratica
                   ,'L',rpad('LI',16)
                   ,rpad(f_tipo_accertamento(prtr.pratica),16)
                   )                                                            TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , lpad(nvl(f_numerico(prtr.numero),0),9,'0')                         NUM_PRV
           , rpad(' ',20)                                                       REG_PRO
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , lpad('0',18,'0')                                                   PRG_PRO
           , rpad(' ',8)                                                        DAT_PRO
           , nvl(to_char(prtr.data,'yyyymmdd'),to_char(prtr.anno)||'0101')      DAT_GEN
           , to_char(prtr.anno)                                                 YEA_RIF
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SPE') * 100
                    ,'S0000000000')                                             IMP_SPS
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'IMP') * 100
                    ,'S0000000000000')                                          IMP_TOT
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'INT') * 100
                    ,'S0000000000000')                                          INT_TOT
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SAN') * 100
                    ,'S0000000000000')                                          SNZ_TOT
           , to_char(
                nvl(prtr.importo_totale,0) * 100
                    ,'S0000000000000')                                          DOV_TOT
           , decode(sign(nvl(prtr.importo_totale,0))
                   ,-1,rpad('N',16)
                   ,rpad('P',16)
                   )                                                            TIP_IMP
           , to_char(
                f_importi_violazioni_ici(prtr.pratica, 'SANRID') * 100
                    ,'S0000000000000')                                          SNZ_RID_TOT
           , to_char(
                nvl(prtr.importo_ridotto,0) * 100
                    ,'S0000000000000')                                          DOV_RID_TOT
           , lpad('0',14,'0')                                                   IMP_ADD_P
           , lpad('0',14,'0')                                                   IMP_ADD_C
           , lpad('1',9,'0')                                                    VRS
           , rpad(' ',8)                                                        DAT_STA
           , decode(prtr.stato_accertamento
                   ,'A',rpad('A',16)
                   ,'D',decode(prtr.data_notifica
                              ,null,rpad('V',16)
                              ,rpad('N',16)
                              )
                   ,null,decode(prtr.data_notifica
                               ,null,rpad('E',16)
                               ,rpad('N',16)
                               )
                   ,rpad(' ',16)
                   )                                                            COD_STA
           , nvl(to_char(prtr.data,'yyyymmdd'),to_char(prtr.anno)||'0101')      DAT_ELA
           , rpad(' ',8)                                                        DAT_VAL
           , rpad(' ',8)                                                        DAT_SOS
           , rpad(' ',8)                                                        DAT_ANN
           , nvl(to_char(prtr.data_notifica,'yyyymmdd'),rpad(' ',8))            DAT_NOT
           , rpad(' ',16)                                                       COD_MOT_EMI
           , rpad(substr(nvl(prtr.note,' '),1,250),250)                         NOTE
           , rpad(' ',8)                                                        DAT_STM
           , rpad(' ',16)                                                       TIP_EMI_COO
           , rpad(' ',16)                                                       COD_EMI_COO
           , rpad(' ',18)                                                       COD_OT
           , lpad('0',18,'0')                                                   ID_ORI_CFPRVD_CUM
           , lpad('0',18,'0')                                                   ID_ORI_CFDENT_QUIR
           , rpad(' ',16)                                                       COD_STA_PRC_ADS
           , rpad(' ',8)                                                        DAT_RIC_ADS
           , rpad(' ',8)                                                        DAT_CNF_ADS
           , rpad(' ',8)                                                        DAT_PRF_ADS
           , lpad('0',4,'0')                                                    YEA_PRO_RIC_ADS
           , rpad(' ',8)                                                        NUM_PRO_RIC_ADS
           , rpad(' ',20)                                                       REG_PRO_RIC_ADS
           , lpad('0',18,'0')                                                   ID_ORI_ULT_RIC
           , 'N'                                                                FLG_SOS_RUO
           , rpad(' ',16)                                                       COD_MOT_SOS_RUO
           , lpad('0',18,'0')                                                   ID_ORI_ELA_RUO
           , rpad(' ',8)                                                        DAT_PREC_RIC
           , rpad(' ',8)                                                        FLG_ADE_FORM
           , rpad(' ',8)                                                        DAT_ADE_FORM
           , rpad(' ',14)                                                       TMS_TIME_INS
           , rpad(' ',30)                                                       COD_UTE_INS
           , rpad(to_char(prtr.data_variazione,'yyyymmddhh24miss'),14)          TMS_TIME_VAR
           , rpad(prtr.utente,30)                                               COD_UTE_VAR
           , prtr.pratica
        from contribuenti      cont
           , pratiche_tributo  prtr
       where cont.cod_fiscale      = prtr.cod_fiscale
         and prtr.tipo_tributo||'' = 'ICI'
         and prtr.tipo_pratica   = 'L'
         and exists (select 1
                       from sanzioni_pratica sapr
                      where sapr.pratica  = prtr.pratica
                        and sapr.cod_sanzione in (1,101,6,7,106,107,136,151,152,155,157,157,161,162,206,207)
                     )
           ;
   CURSOR sel_cari(p_pratica number) IS
      select rpad('CFIMDI',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),17,'0')
           ||'3'                                                                ID_ORI_CFIMDI
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , rpad(f_tipo_accertamento(prtr.pratica),16)                         TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , rpad(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'')
                 ,16)                                                           COD_MOT
           , rpad(' ',30)                                                       ID_ORI_CF_AOGG
           , lpad('0',9,'0')                                                    ID_ORI_OGG_TRB
           , lpad('3',2,'0')                                                    RATA
           , rpad(' ',16)                                                       FLG_IMP_EMS
           , rpad(' ',16)                                                       FLG_INT_EMS
           , rpad(' ',16)                                                       FLG_SNZ_EMS
           , to_char(f_importi_violazioni_ici(prtr.pratica,'IMP') * 100
                    ,'S0000000000000')                                          IMP_DOV
           , to_char(f_importi_violazioni_ici(prtr.pratica,'SAN') * 100
                    ,'S0000000000')                                             IMP_MAG
           , to_char(f_importi_violazioni_ici(prtr.pratica,'SANRID') * 100
                    ,'S0000000000')                                             IMP_MAG_RID
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'')
                        ,'DO','OMEACCICI'
                        ,'DI','INFACCICI'
                        ,' '
                        )
                 ,16)                                                           TIP_INT
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'')
                        ,'DO','OMEDICICI'
                        ,'DI','INFDICICI'
                        ,' '
                        )
                 ,16)                                                           TIP_SNZ
           , to_char(f_importi_violazioni_ici(prtr.pratica,'INT') * 100
                    ,'S0000000000')                                             IMP_INT
           , rpad(' ',8)                                                        DAT_DEC_INT
           , rpad(' ',8)                                                        DAT_CAL_INT
           , lpad('0',5,'0')                                                    PRD_INT
           , lpad('0',7,'0')                                                    SPC_PRC_SNZ
           , rpad('0',14,'0')                                                   IMP_ADD_P
           , rpad('0',14,'0')                                                   IMP_ADD_C
           , rpad(' ',16)                                                       COD_RAV_APP
           , rpad(' ',18)                                                       ID_ORI_CAL_INT
           , ' '                                                                FLG_APP_SNZ_MIN
           , rpad(' ',18)                                                       ID_ORI_CFDENT_ATT
           , rpad(' ',18)                                                       ID_ORI_CFRSDETT_ATT
        from pratiche_tributo  prtr
       where prtr.pratica          = p_pratica
         and prtr.tipo_pratica     = 'A'
     union
      select rpad('CFIMDI',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),17,'0')
           ||'1'                                                                ID_ORI_CFIMDI
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , rpad('LI',16)                                                      TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , rpad(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'A')
                 ,16)                                                           COD_MOT
           , rpad(' ',30)                                                       ID_ORI_CF_AOGG
           , lpad('0',9,'0')                                                    ID_ORI_OGG_TRB
           , lpad('1',2,'0')                                                    RATA
           , rpad(' ',16)                                                       FLG_IMP_EMS
           , rpad(' ',16)                                                       FLG_INT_EMS
           , rpad(' ',16)                                                       FLG_SNZ_EMS
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'IMP','A') * 100
                    ,'S0000000000000')                                          IMP_DOV
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'SAN','A') * 100
                    ,'S0000000000')                                             IMP_MAG
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'SANRID','A') * 100
                    ,'S0000000000')                                             IMP_MAG_RID
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'A')
                        ,'VO','OMEPAGICI'
                        ,'VP','OMEPAGICI'
                        ,'VT','TARPAGICI'
                        ,' '
                        )
                 ,16)                                                           TIP_INT
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'A')
                        ,'VO','OPTPAGICI'
                        ,'VP','OPTPAGICI'
                        ,'VT','OPTPAGICI'
                        ,' '
                        )
                 ,16)                                                           TIP_SNZ
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'INT','A') * 100
                    ,'S0000000000')                                             IMP_INT
           , rpad(' ',8)                                                        DAT_DEC_INT
           , rpad(' ',8)                                                        DAT_CAL_INT
           , lpad('0',5,'0')                                                    PRD_INT
           , lpad('0',7,'0')                                                    SPC_PRC_SNZ
           , rpad('0',14,'0')                                                   IMP_ADD_P
           , rpad('0',14,'0')                                                   IMP_ADD_C
           , rpad(' ',16)                                                       COD_RAV_APP
           , rpad(' ',18)                                                       ID_ORI_CAL_INT
           , ' '                                                                FLG_APP_SNZ_MIN
           , rpad(' ',18)                                                       ID_ORI_CFDENT_ATT
           , rpad(' ',18)                                                       ID_ORI_CFRSDETT_ATT
        from pratiche_tributo  prtr
       where prtr.pratica          = p_pratica
         and prtr.tipo_pratica     = 'L'
         and exists (select 1
                       from sanzioni_pratica sapr
                      where sapr.pratica = p_pratica
                        and sapr.cod_sanzione in (1,101,6,7,106,107,136,151,152,155,157,157,161,162,206,207
                                                 ,21,121,8,9,108,109,137,153,154,156,159,160,163,164,208,209
                                                 )
                    )
     union
      select rpad('CFIMDI',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),17,'0')
           ||'2'                                                                ID_ORI_CFIMDI
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , rpad('LI',16)                                                      TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , rpad(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'S')
                 ,16)                                                           COD_MOT
           , rpad(' ',30)                                                       ID_ORI_CF_AOGG
           , lpad('0',9,'0')                                                    ID_ORI_OGG_TRB
           , lpad('2',2,'0')                                                    RATA
           , rpad(' ',16)                                                       FLG_IMP_EMS
           , rpad(' ',16)                                                       FLG_INT_EMS
           , rpad(' ',16)                                                       FLG_SNZ_EMS
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'IMP','S') * 100
                    ,'S0000000000000')                                          IMP_DOV
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'SAN','S') * 100
                    ,'S0000000000')                                             IMP_MAG
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'SANRID','S') * 100
                    ,'S0000000000')                                             IMP_MAG_RID
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'S')
                        ,'VO','OMEPAGICI'
                        ,'VP','OMEPAGICI'
                        ,'VT','TARPAGICI'
                        ,' '
                        )
                 ,16)                                                           TIP_INT
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'S')
                        ,'VO','OPTPAGICI'
                        ,'VP','OPTPAGICI'
                        ,'VT','OPTPAGICI'
                        ,' '
                        )
                 ,16)                                                           TIP_SNZ
           , to_char(f_importi_liquidazioni_ici(prtr.pratica,'INT','S') * 100
                    ,'S0000000000')                                             IMP_INT
           , rpad(' ',8)                                                        DAT_DEC_INT
           , rpad(' ',8)                                                        DAT_CAL_INT
           , lpad('0',5,'0')                                                    PRD_INT
           , lpad('0',7,'0')                                                    SPC_PRC_SNZ
           , rpad('0',14,'0')                                                   IMP_ADD_P
           , rpad('0',14,'0')                                                   IMP_ADD_C
           , rpad(' ',16)                                                       COD_RAV_APP
           , rpad(' ',18)                                                       ID_ORI_CAL_INT
           , ' '                                                                FLG_APP_SNZ_MIN
           , rpad(' ',18)                                                       ID_ORI_CFDENT_ATT
           , rpad(' ',18)                                                       ID_ORI_CFRSDETT_ATT
        from pratiche_tributo  prtr
       where prtr.pratica          = p_pratica
         and prtr.tipo_pratica     = 'L'
         and exists (select 1
                       from sanzioni_pratica sapr
                      where sapr.pratica = p_pratica
                        and sapr.cod_sanzione in (21,121,8,9,108,109,137,153,154,156,159,160,163,164,208,209)
                    )
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(80);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
              , rpad(nvl(com.denominazione ,' '),80)
           into w_cod_belfiore
              , w_comune_desc
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Provvedimenti Ici
      for rec_prov in sel_prov loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Provvedimenti Ici '||rec_prov.ID_ORI_CFPRVD;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_prov.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_prov.ID_ORI_CFPRVD
                  ||rec_prov.ID_ORI_CFSOGG
                  ||rec_prov.COD_TRB
                  ||rec_prov.TIP_PRV
                  ||rec_prov.YEA_PRV
                  ||rec_prov.NUM_PRV
                  ||rec_prov.REG_PRO
                  ||rec_prov.NUM_PRO
                  ||rec_prov.YEA_PRO
                  ||rec_prov.PRG_PRO
                  ||rec_prov.DAT_PRO
                  ||rec_prov.DAT_GEN
                  ||rec_prov.YEA_RIF
                  ||rec_prov.IMP_SPS
                  ||rec_prov.IMP_TOT
                  ||rec_prov.INT_TOT
                  ||rec_prov.SNZ_TOT
                  ||rec_prov.DOV_TOT
                  ||rec_prov.TIP_IMP
                  ||rec_prov.SNZ_RID_TOT
                  ||rec_prov.DOV_RID_TOT
                  ||rec_prov.IMP_ADD_P
                  ||rec_prov.IMP_ADD_C
                  ||rec_prov.VRS
                  ||rec_prov.DAT_STA
                  ||rec_prov.COD_STA
                  ||rec_prov.DAT_ELA
                  ||rec_prov.DAT_VAL
                  ||rec_prov.DAT_SOS
                  ||rec_prov.DAT_ANN
                  ||rec_prov.DAT_NOT
                  ||rec_prov.COD_MOT_EMI
                  ||rec_prov.NOTE
                  ||rec_prov.DAT_STM
                  ||rec_prov.TIP_EMI_COO
                  ||rec_prov.COD_EMI_COO
                  ||rec_prov.COD_OT
                  ||rec_prov.ID_ORI_CFPRVD_CUM
                  ||rec_prov.ID_ORI_CFDENT_QUIR
                  ||rec_prov.COD_STA_PRC_ADS
                  ||rec_prov.DAT_RIC_ADS
                  ||rec_prov.DAT_CNF_ADS
                  ||rec_prov.DAT_PRF_ADS
                  ||rec_prov.YEA_PRO_RIC_ADS
                  ||rec_prov.NUM_PRO_RIC_ADS
                  ||rec_prov.REG_PRO_RIC_ADS
                  ||rec_prov.ID_ORI_ULT_RIC
                  ||rec_prov.FLG_SOS_RUO
                  ||rec_prov.COD_MOT_SOS_RUO
                  ||rec_prov.ID_ORI_ELA_RUO
                  ||rec_prov.DAT_PREC_RIC
                  ||rec_prov.FLG_ADE_FORM
                  ||rec_prov.DAT_ADE_FORM
                  ||rec_prov.TMS_TIME_INS
                  ||rec_prov.COD_UTE_INS
                  ||rec_prov.TMS_TIME_VAR
                  ||rec_prov.COD_UTE_VAR
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Provvedimenti ICI '||
                                              ' key: '||rec_prov.ID_ORI_CFPRVD||
                                              ' ('||sqlerrm||')');
         end;
         -- Tracciato Provvedimenti Ici: Carichi
         for rec_cari in sel_cari(rec_prov.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Provvedimenti Ici: Carichi '||rec_cari.ID_ORI_CFIMDI;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_cari.TIP_RECORD
                     ||w_cod_belfiore                  -- COD_ENTE
                     ||rec_cari.ID_ORI_CFIMDI
                     ||rec_cari.ID_ORI_CFPRVD
                     ||rec_cari.TIP_PRV
                     ||rec_cari.YEA_PRV
                     ||rec_cari.COD_MOT
                     ||rec_cari.ID_ORI_CF_AOGG
                     ||rec_cari.ID_ORI_OGG_TRB
                     ||rec_cari.RATA
                     ||rec_cari.FLG_IMP_EMS
                     ||rec_cari.FLG_INT_EMS
                     ||rec_cari.FLG_SNZ_EMS
                     ||rec_cari.IMP_DOV
                     ||rec_cari.IMP_MAG
                     ||rec_cari.IMP_MAG_RID
                     ||rec_cari.TIP_INT
                     ||rec_cari.TIP_SNZ
                     ||rec_cari.IMP_INT
                     ||rec_cari.DAT_DEC_INT
                     ||rec_cari.DAT_CAL_INT
                     ||rec_cari.IMP_INT         -- IMP_INT_ORI
                     ||rec_cari.IMP_MAG         -- IMP_MAG_ORI
                     ||rec_cari.PRD_INT
                     ||rec_cari.IMP_DOV         -- BAS_IMP_CAL_MAG
                     ||rec_cari.SPC_PRC_SNZ
                     ||rec_cari.IMP_DOV         -- BAS_IMP_CAL_INT
                     ||rec_cari.IMP_ADD_P
                     ||rec_cari.IMP_ADD_C
                     ||rec_cari.COD_RAV_APP
                     ||rec_cari.ID_ORI_CAL_INT
                     ||rec_cari.FLG_APP_SNZ_MIN
                     ||rec_cari.ID_ORI_CFDENT_ATT
                     ||rec_cari.ID_ORI_CFRSDETT_ATT
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in Provvedimenti ICI: Carichi '||
                                                 ' key: '||rec_cari.ID_ORI_CFIMDI||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
      end loop;
   end;
   procedure dovuti_ici is
   CURSOR sel_dovu IS
      select rpad('CFICDO',10)                                                  TIP_RECORD
           , lpad(to_char(ogim.oggetto_imposta),18,'0')                         ID_ORI_CFIMDO
           , to_char(ogim.anno)                                                 YEA_RIF
           , '00008'                                                            COD_TRB
           , lpad(to_char(cont.ni),30,'0')                                      ID_ORI_CFSOGG
           , rpad(ogpr.oggetto,30)                                              ID_ORI_CFAOGG
           , rpad('T',16)                                                       TIP_CAL_T   -- Totale
           , rpad('A',16)                                                       TIP_CAL_A   -- Acconto
           , to_char(ogim.anno)||'0101'                                         DAT_INI
           , to_char(ogim.anno)||'1231'                                         DAT_FIN
           , decode(ogim.tipo_aliquota
                   ,2,rpad('S',16)
                   ,rpad(nvl(to_char(ogim.tipo_aliquota),' '),16)
                   )                                                            COD_ALI
            , lpad(to_char(nvl(ogpr.valore,0) * 100),12,'0')                    VAL_IMM_EU
            , lpad(to_char(nvl(ogco.perc_possesso,0) * 100),5,'0')              PRC_POS
            , nvl(ogco.flag_ab_principale,'N')                                  FLG_ABI_PRI
            , lpad(to_char((nvl(ogim.imposta,0)
                            + nvl(ogim.detrazione,0)
                           ) * 100),14,'0')                                     IMP_DOV_LRD_T  -- Totale
            , lpad(to_char((nvl(ogim.imposta_acconto,0)
                            + nvl(ogim.detrazione_acconto,0)
                           ) * 100),14,'0')                                     IMP_DOV_LRD_A  -- Acconto
            , lpad(to_char(nvl(ogim.imposta,0) * 100),14,'0')                   IMP_DOV_T      -- Totale
            , lpad(to_char(nvl(ogim.imposta_acconto,0) * 100),14,'0')           IMP_DOV_A      -- Acconto
            , lpad(to_char(nvl(ogim.detrazione,0) * 100),14,'0')                IMP_AGV_T      -- Totale
            , lpad(to_char(nvl(ogim.detrazione_acconto,0) * 100),14,'0')        IMP_AGV_A      -- Acconto
            , decode(ogim.anno
                    ,prtr.anno,lpad(to_char(nvl(ogco.mesi_possesso,12)),3,'0')
                    ,'012'
                    )                                                           PRD_T
            , decode(ogim.anno
                    ,prtr.anno,lpad(to_char(nvl(ogco.mesi_possesso,6)),3,'0')
                    ,'006'
                    )                                                           PRD_A
        from contribuenti          cont
           , pratiche_tributo      prtr
           , oggetti_pratica       ogpr
           , oggetti_imposta       ogim
           , oggetti_contribuente  ogco
       where ogim.oggetto_pratica  = ogpr.oggetto_pratica
         and ogpr.pratica          = prtr.pratica
         and ogpr.oggetto_pratica  = ogco.oggetto_pratica
         and ogco.cod_fiscale      = ogim.cod_fiscale
         and ogim.cod_fiscale      = cont.cod_fiscale
         and prtr.tipo_tributo||'' = 'ICI'
         and ogim.flag_calcolo     = 'S'
         and ogim.anno       between to_number(to_char(sysdate,'yyyy')) - 3
                                 and to_number(to_char(sysdate,'yyyy')) - 1
         and ogim.tipo_aliquota  is not null  -- Non estraggo gli ogim con aliquota nulla perchè è un dato obbligatorio
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(80);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
              , rpad(nvl(com.denominazione ,' '),80)
           into w_cod_belfiore
              , w_comune_desc
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Dovuti Ici
      for rec_dovu in sel_dovu loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Dovuti Ici '||rec_dovu.ID_ORI_CFIMDO;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_dovu.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_dovu.ID_ORI_CFIMDO
                  ||rec_dovu.YEA_RIF
                  ||rec_dovu.COD_TRB
                  ||rec_dovu.ID_ORI_CFSOGG
                  ||rec_dovu.ID_ORI_CFAOGG
                  ||rec_dovu.TIP_CAL_T
                  ||rec_dovu.DAT_INI
                  ||rec_dovu.DAT_FIN
                  ||rec_dovu.COD_ALI
                  ||rec_dovu.VAL_IMM_EU
                  ||rec_dovu.PRC_POS
                  ||rec_dovu.FLG_ABI_PRI
                  ||rec_dovu.IMP_DOV_LRD_T
                  ||rec_dovu.IMP_DOV_T
                  ||rec_dovu.IMP_AGV_T
                  ||rec_dovu.PRD_T
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Dovuti ICI '||
                                              ' key: '||rec_dovu.ID_ORI_CFIMDO||
                                              ' ('||sqlerrm||')');
         end;
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Dovuti Ici '||rec_dovu.ID_ORI_CFIMDO;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_dovu.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_dovu.ID_ORI_CFIMDO
                  ||rec_dovu.YEA_RIF
                  ||rec_dovu.COD_TRB
                  ||rec_dovu.ID_ORI_CFSOGG
                  ||rec_dovu.ID_ORI_CFAOGG
                  ||rec_dovu.TIP_CAL_A
                  ||rec_dovu.DAT_INI
                  ||rec_dovu.DAT_FIN
                  ||rec_dovu.COD_ALI
                  ||rec_dovu.VAL_IMM_EU
                  ||rec_dovu.PRC_POS
                  ||rec_dovu.FLG_ABI_PRI
                  ||rec_dovu.IMP_DOV_LRD_A
                  ||rec_dovu.IMP_DOV_A
                  ||rec_dovu.IMP_AGV_A
                  ||rec_dovu.PRD_A
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Dovuti ICI '||
                                              ' key: '||rec_dovu.ID_ORI_CFIMDO||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure aliquote_ici is
   CURSOR sel_aliq IS
      select rpad('CFICALIQ',10)                                                TIP_RECORD
           , decode(aliq.tipo_aliquota
                   ,2,rpad('S',16)
                   ,rpad(to_char(aliq.tipo_aliquota),16)
                   )                                                            COD_ALI
           , to_char(aliq.anno)||'0101'                                         DAT_INI
           , to_char(aliq.anno)||'1231'                                         DAT_FIN
           , rpad(to_char(aliq.aliquota * 100),5)                               PRC
           , rpad(tial.descrizione,60)                                          DES_ALI
           , rpad(' ',16)                                                       COD_AGV_DEF
           , nvl(aliq.flag_pertinenze,' ')                                      FLG_PRT
           , rpad(' ',16)                                                       COD_ALL_ASS
           , ' '                                                                FLG_ALL_ORD
       from  aliquote            aliq
           , tipi_aliquota       tial
       where aliq.aliquota          = tial.tipo_aliquota
         and aliq.anno             <= to_number(to_char(sysdate,'yyyy'))
    order by aliq.anno
           , aliq.tipo_aliquota
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Aliquote Ici
      for rec_aliq in sel_aliq loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Aliquote Ici '||rec_aliq.COD_ALI;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_aliq.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_aliq.COD_ALI
                  ||rec_aliq.DAT_INI
                  ||rec_aliq.DAT_FIN
                  ||rec_aliq.PRC
                  ||rec_aliq.DES_ALI
                  ||rec_aliq.COD_AGV_DEF
                  ||rec_aliq.FLG_PRT
                  ||rec_aliq.COD_ALL_ASS
                  ||rec_aliq.FLG_ALL_ORD
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Aliquote ICI '||
                                              ' aliq: '||rec_aliq.COD_ALI||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure agevolazioni_ici is
   CURSOR sel_agev IS
      select rpad('CFTAGV',10)                                                  TIP_RECORD_TESTATA
           , rpad(to_char(made.anno)
                  ||lpad(to_char(cont.ni),8,'0')
                 ,16)                                                           COD_AGV
           , lpad('8',5,'0')                                                    COD_TRB
           , 'D'                                                                TIP_AGV
           , rpad('DESCRIZIONE ASSENTE',80)                                     DES_AGV
           , rpad('U',16)                                                       CLS_AGV
           , rpad('CFTVAG',10)                                                  TIP_RECORD
           , to_char(made.anno)||'0101'                                         DAT_INI_VAL
           , to_char(made.anno)||'1231'                                         DAT_FIN_VAL
           , lpad(f_ulteriore_detrazione(made.anno
                                        ,made.cod_fiscale
                                        ,made.detrazione
                                        ) * 100
                 ,12,'0')                                                       VAL_AGV
        from contribuenti         cont
           , maggiori_detrazioni  made
       where made.cod_fiscale          = cont.cod_fiscale
         and made.motivo_detrazione not in (97,98,99)
         and nvl(made.detrazione,0) > 0
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      for rec_agev in sel_agev loop
         -- Solo se l'ulteriore detrazione calcolata è maggiore di 0 inserisco il record
         if to_number(rec_agev.VAL_AGV) > 0 then
            -- Testata Agevolazioni
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Testata Agevolazioni '||rec_agev.COD_AGV;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_agev.TIP_RECORD_TESTATA
                     ||w_cod_belfiore                  -- COD_ENTE
                     ||rec_agev.COD_AGV
                     ||rec_agev.COD_TRB
                     ||rec_agev.TIP_AGV
                     ||rec_agev.DES_AGV
                     ||rec_agev.CLS_AGV
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in Testata Agevolazioni '||
                                                 ' key: '||rec_agev.COD_AGV||
                                                 ' ('||sqlerrm||')');
            end;
            -- Dettaglio Agevolazioni
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Agevolazioni '||rec_agev.COD_AGV;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_agev.TIP_RECORD
                     ||w_cod_belfiore                  -- COD_ENTE
                     ||rec_agev.COD_AGV
                     ||rec_agev.COD_TRB
                     ||rec_agev.DAT_INI_VAL
                     ||rec_agev.DAT_FIN_VAL
                     ||rec_agev.VAL_AGV
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in Dettaglio Agevolazioni '||
                                                 ' key: '||rec_agev.COD_AGV||
                                                 ' ('||sqlerrm||')');
            end;
         end if;
      end loop;
   end;
   procedure denunce_rsu is
   CURSOR sel_tdt IS
      select rpad('CFDENT',10)                                                  TIP_RECORD
           , '11001'                                                            SUB_TIP_DOC
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFDENT
           , lpad(nvl(to_char(prtr.anno),'0'),4,'0')                            YEA_RIF
           , nvl(to_char(prtr.data,'yyyymmdd'),'19000101')                      DAT_DOC
           , rpad(to_char(cont.ni),30)                                          ID_ORI_CFSOGG_CNT
           , rpad(nvl(to_char(sogg_den.ni),' '),30)                             ID_ORI_CFSOGG_DEN
           , decode(sogg_den.ni
                   ,null,rpad(' ',50)
                   ,substr(rpad(nvl(tica.descrizione,' '),50),1,50)
                   )                                                            CRC_DEN
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , rpad(' ',20)                                                       REG_PRO
           , lpad('0',9,'0')                                                    PRG_PRO
           , rpad(' ',8)                                                        DATA_SYS_INS
           , rpad(' ',8)                                                        DATA_STM
           , lpad(nvl(to_char(prtr.anno),'0'),4,'0')                            YEA_DOC
           , substr(lpad(nvl(to_char(F_NUMERICO(prtr.numero)),'0'),9,'0'),1,9)  NUM_DOC
           , 'N'                                                                FLG_RIL
           , lpad('0',18,'0')                                                   COD_VRB
           , rpad(' ',20)                                                       NUM_VRB
           , '1'                                                                COD_TRB
           , rpad(' ',96)                                                       FILLER
           , prtr.pratica
        from pratiche_tributo     prtr
           , contribuenti         cont
           , tipi_carica          tica
           , soggetti             sogg_den
       where prtr.tipo_carica          = tica.tipo_carica (+)
         and prtr.tipo_tributo||''     = 'TARSU'
         and prtr.tipo_pratica||''     = 'D'
         and prtr.cod_fiscale          = cont.cod_fiscale
         and prtr.cod_fiscale_den      = sogg_den.cod_fiscale (+)
        ;
   CURSOR sel_detai(p_pratica number) IS
      select decode(prtr.tipo_evento
                   ,'I',rpad('CFRSDANI',10)
                   ,'U',rpad('CFRSDANI',10)
                   )                                                            TIP_RECORD
           , lpad(to_char(ogpr.oggetto_pratica),18,'0')                         ID_ORI_CFRSDANI
           , lpad(to_char(ogpr.pratica),18,'0')                                 ID_ORI_CFDENT
           , rpad(to_char(ogpr.oggetto),30)                                     ID_ORI_CFAOGG
           , rpad(to_char(ogpr.oggetto),18)                                     ID_ORI_OGG_TRB
           , decode(prtr.tipo_evento
                   ,'I',nvl(to_char(nvl(ogco.inizio_occupazione,ogco.data_decorrenza),'yyyymmdd')
                           ,'19000101')
                   ,'U',nvl(to_char(nvl(ogco.inizio_occupazione,ogco.data_decorrenza),'yyyymmdd')
                           ,'19000101')
                   )                                                            DAT_EVE
           , lpad(to_char(ogpr.tributo),4,'0')
           ||lpad(to_char(ogpr.categoria),4,'0')
           ||lpad(to_char(ogpr.tipo_tariffa),2,'0')
           ||rpad(' ',6)                                                        COD_CLS_TAR
           , rpad(' ',16)                                                       COD_RID
           , lpad(to_char(ogpr.consistenza * 100),9,'0')                        SUP_TAS
           , lpad('0',9,'0')                                                    SUP_NON_TAS
           , lpad(to_char(ogpr.consistenza * 100),9,'0')                        SUP_TOT
           , rpad(' ',100)                                                      DES_MTV_NON_TAS
           , lpad('0',18,'0')                                                   ID_ORI_CFRS_DANI_RIF
           , lpad(to_char(
                nvl(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),0)
                         ) ,9,'0')                                              TIP_OGG
           , nvl(to_char(nvl(ogco.fine_occupazione
                            ,ogco.data_cessazione),'yyyymmdd')
                ,'00000000')                                                    DAT_FIN_OCC
           , rpad(nvl(prtr.utente,' '),30)                                      COD_UTE_VAR
           , rpad(' ',88)                                                       FILLER
        from oggetti_pratica      ogpr
           , oggetti_contribuente ogco
           , pratiche_tributo     prtr
           , oggetti              ogge
       where ogpr.pratica              = p_pratica
         and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and ogpr.pratica              = prtr.pratica
         and ogge.oggetto              = ogpr.oggetto
         and prtr.tipo_evento         in ('I','U')
        ;
   CURSOR sel_detav(p_pratica number) IS
      select rpad('CFRSDAVZ',10)                                                TIP_RECORD
           , lpad(to_char(ogpr.oggetto_pratica),18,'0')                         ID_ORI_CFRSDAVZ
           , lpad(to_char(ogpr.pratica),18,'0')                                 ID_ORI_CFDENT
           , rpad(to_char(ogpr.oggetto),30)                                     ID_ORI_CFAOGG
           , rpad(to_char(ogpr.oggetto),18)                                     ID_ORI_OGG_TRB
           , nvl(to_char(nvl(ogco.inizio_occupazione
                            ,ogco.data_decorrenza),'yyyymmdd')
                ,'19000101')                                                    DAT_EVE
           , lpad(to_char(ogpr.tributo),4,'0')
           ||lpad(to_char(ogpr.categoria),4,'0')
           ||lpad(to_char(ogpr.tipo_tariffa),2,'0')
           ||rpad(' ',6)                                                        COD_CLS_TAR
           , rpad(' ',16)                                                       COD_RID
           , lpad(to_char(ogpr.consistenza * 100),9,'0')                        SUP_TAS
           , lpad('0',9,'0')                                                    SUP_NON_TAS
           , lpad(to_char(ogpr.consistenza * 100),9,'0')                        SUP_TOT
           , rpad(' ',100)                                                      DES_MTV_NON_TAS
           , lpad('0',18,'0')                                                   ID_ORI_CFRS_DANI_RIF
           , lpad(to_char(
                nvl(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),0)
                         ) ,9,'0')                                              TIP_OGG
           , rpad(' ',88)                                                       FILLER
        from oggetti_pratica      ogpr
           , oggetti_contribuente ogco
           , pratiche_tributo     prtr
           , oggetti              ogge
       where ogpr.pratica              = p_pratica
         and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and ogpr.pratica              = prtr.pratica
         and ogge.oggetto              = ogpr.oggetto
         and prtr.tipo_evento          = 'V'
        ;
   CURSOR sel_detac(p_pratica number) IS
      select rpad('CFRSDACS',10)                                                TIP_RECORD
           , lpad(to_char(ogpr.oggetto_pratica),18,'0')                         ID_ORI_CFRSDACS
           , lpad(to_char(ogpr.pratica),18,'0')                                 ID_ORI_CFDENT
           , rpad(to_char(ogpr.oggetto),30)                                     ID_ORI_CFAOGG
           , rpad(to_char(ogpr.oggetto),18)                                     ID_ORI_OGG_TRB
           , nvl(to_char(nvl(ogco.fine_occupazione
                            ,ogco.data_cessazione),'yyyymmdd')
                ,'00000000')                                                    DAT_EVE
           , lpad('0',18,'0')                                                   PRG_CFRSDACS_RIF
           , rpad(' ',88)                                                       FILLER
        from oggetti_pratica      ogpr
           , oggetti_contribuente ogco
           , pratiche_tributo     prtr
           , oggetti              ogge
       where ogpr.pratica              = p_pratica
         and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and ogpr.pratica              = prtr.pratica
         and ogge.oggetto              = ogpr.oggetto
         and prtr.tipo_evento          = 'C'
        ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Testata Denunce TARSU
      for rec_tdt in sel_tdt loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Testata DEnunce TARSU '||rec_tdt.ID_ORI_CFDENT;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_tdt.TIP_RECORD
                  ||w_cod_belfiore                   -- CODICE_ENTE
                  ||rec_tdt.SUB_TIP_DOC
                  ||rec_tdt.ID_ORI_CFDENT
                  ||rec_tdt.YEA_RIF
                  ||rec_tdt.DAT_DOC
                  ||rec_tdt.ID_ORI_CFSOGG_CNT
                  ||rec_tdt.ID_ORI_CFSOGG_DEN
                  ||rec_tdt.CRC_DEN
                  ||rec_tdt.NUM_PRO
                  ||rec_tdt.YEA_PRO
                  ||rec_tdt.REG_PRO
                  ||rec_tdt.PRG_PRO
                  ||rec_tdt.DATA_SYS_INS
                  ||rec_tdt.DATA_STM
                  ||rec_tdt.YEA_DOC
                  ||rec_tdt.NUM_DOC
                  ||rec_tdt.FLG_RIL
                  ||rec_tdt.COD_VRB
                  ||rec_tdt.NUM_VRB
                  ||rec_tdt.COD_TRB
                  ||rec_tdt.FILLER
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in estrazione Testata Denunce TARSU '||
                                              ' prat '||rec_tdt.ID_ORI_CFDENT||
                                              ' ('||sqlerrm||')');
         end;
         -- Denunce TARSU Iscrizione
         for rec_detai in sel_detai(rec_tdt.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Den. TARSU Isc. '||rec_detai.ID_ORI_CFRSDANI;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_detai.TIP_RECORD
                     ||w_cod_belfiore                    -- CODICE_ENTE
                     ||rec_detai.ID_ORI_CFRSDANI
                     ||rec_detai.ID_ORI_CFDENT
                     ||rec_detai.ID_ORI_CFAOGG
                     ||rec_detai.ID_ORI_OGG_TRB
                     ||rec_detai.DAT_EVE
                     ||rec_detai.COD_CLS_TAR
                     ||rec_detai.COD_RID
                     ||rec_detai.SUP_TAS
                     ||rec_detai.SUP_NON_TAS
                     ||rec_detai.SUP_TOT
                     ||rec_detai.DES_MTV_NON_TAS
                     ||rec_detai.ID_ORI_CFRS_DANI_RIF
                     ||rec_detai.TIP_OGG
                     ||rec_detai.DAT_FIN_OCC
                     ||rec_detai.COD_UTE_VAR
                     ||rec_detai.FILLER
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Dettaglio Den. TARSU Isc '||
                                                 ' ogpr '||rec_detai.ID_ORI_CFRSDANI||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
         -- Denunce TARSU Variazione
         for rec_detav in sel_detav(rec_tdt.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Den. TARSU Var. '||rec_detav.ID_ORI_CFRSDAVZ;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_detav.TIP_RECORD
                     ||w_cod_belfiore                    -- CODICE_ENTE
                     ||rec_detav.ID_ORI_CFRSDAVZ
                     ||rec_detav.ID_ORI_CFDENT
                     ||rec_detav.ID_ORI_CFAOGG
                     ||rec_detav.ID_ORI_OGG_TRB
                     ||rec_detav.DAT_EVE
                     ||rec_detav.COD_CLS_TAR
                     ||rec_detav.COD_RID
                     ||rec_detav.SUP_TAS
                     ||rec_detav.SUP_NON_TAS
                     ||rec_detav.SUP_TOT
                     ||rec_detav.DES_MTV_NON_TAS
                     ||rec_detav.ID_ORI_CFRS_DANI_RIF
                     ||rec_detav.TIP_OGG
                     ||rec_detav.FILLER
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Dettaglio Den. TARSU Var '||
                                                 ' ogpr '||rec_detav.ID_ORI_CFRSDAVZ||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
         -- Denunce TARSU Cessazione
         for rec_detac in sel_detac(rec_tdt.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Dettaglio Den. TARSU Ces. '||rec_detac.ID_ORI_CFRSDACS;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_detac.TIP_RECORD
                     ||w_cod_belfiore                    -- CODICE_ENTE
                     ||rec_detac.ID_ORI_CFRSDACS
                     ||rec_detac.ID_ORI_CFDENT
                     ||rec_detac.ID_ORI_CFAOGG
                     ||rec_detac.ID_ORI_OGG_TRB
                     ||rec_detac.DAT_EVE
                     ||rec_detac.PRG_CFRSDACS_RIF
                     ||rec_detac.FILLER
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in estrazione Dettaglio Den. TARSU Ces '||
                                                 ' ogpr '||rec_detac.ID_ORI_CFRSDACS||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
      end loop;
   end;
   procedure provvedimenti_rsu is
   CURSOR sel_prov IS
      select rpad('CFPRVD',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , lpad(to_char(cont.ni),30,'0')                                      ID_ORI_CFSOGG
           , '00001'                                                            COD_TRB
           , rpad(f_tipo_accertamento(prtr.pratica),16)                         TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , lpad(nvl(f_numerico(prtr.numero),0),9,'0')                         NUM_PRV
           , rpad(' ',20)                                                       REG_PRO
           , rpad(' ',8)                                                        NUM_PRO
           , lpad('0',4,'0')                                                    YEA_PRO
           , lpad('0',18,'0')                                                   PRG_PRO
           , rpad(' ',8)                                                        DAT_PRO
           , to_char(prtr.data,'yyyymmdd')                                      DAT_GEN
           , to_char(prtr.anno)                                                 YEA_RIF
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'SPE') * 100
                    ,'S0000000000')                                             IMP_SPS
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'IMP') * 100
                    ,'S0000000000000')                                          IMP_TOT
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'INT') * 100
                    ,'S0000000000000')                                          INT_TOT
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'SAN') * 100
                    ,'S0000000000000')                                          SNZ_TOT
           , to_char(
                nvl(prtr.importo_totale,0) * 100
                    ,'S0000000000000')                                          DOV_TOT
           , decode(sign(nvl(prtr.importo_totale,0))
                   ,-1,rpad('N',16)
                   ,rpad('P',16)
                   )                                                            TIP_IMP
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'SANRID') * 100
                    ,'S0000000000000')                                          SNZ_RID_TOT
           , to_char(
                nvl(prtr.importo_ridotto,0) * 100
                    ,'S0000000000000')                                          DOV_RID_TOT
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'ADDPRO') * 100
                    ,'S0000000000000')                                          IMP_ADD_P
           , to_char(
                f_importi_violazioni_rsu(prtr.pratica, 'ADDCOM') * 100
                    ,'S0000000000000')                                          IMP_ADD_C
           , lpad('1',9,'0')                                                    VRS
           , rpad(' ',8)                                                        DAT_STA
           , decode(prtr.stato_accertamento
                   ,'A',rpad('A',16)
                   ,'D',decode(prtr.data_notifica
                              ,null,rpad('V',16)
                              ,rpad('N',16)
                              )
                   ,null,decode(prtr.data_notifica
                               ,null,rpad('E',16)
                               ,rpad('N',16)
                               )
                   ,rpad('E',16)
                   )                                                            COD_STA
           , to_char(prtr.data,'yyyymmdd')                                      DAT_ELA
           , rpad(' ',8)                                                        DAT_VAL
           , rpad(' ',8)                                                        DAT_SOS
           , rpad(' ',8)                                                        DAT_ANN
           , nvl(to_char(prtr.data_notifica,'yyyymmdd'),rpad(' ',8))            DAT_NOT
           , rpad(' ',16)                                                       COD_MOT_EMI
           , rpad(substr(nvl(replace(replace(prtr.note,chr(13)||chr(10),' ')
                                    ,chr(9),' ')
                            ,' '),1,250),250)                                   NOTE
           , rpad(' ',8)                                                        DAT_STM
           , rpad(' ',16)                                                       TIP_EMI_COO
           , rpad(' ',16)                                                       COD_EMI_COO
           , rpad(' ',18)                                                       COD_OT
           , lpad('0',18,'0')                                                   ID_ORI_CFPRVD_CUM
           , lpad('0',18,'0')                                                   ID_ORI_CFDENT_QUIR
           , rpad(' ',16)                                                       COD_STA_PRC_ADS
           , rpad(' ',8)                                                        DAT_RIC_ADS
           , rpad(' ',8)                                                        DAT_CNF_ADS
           , rpad(' ',8)                                                        DAT_PRF_ADS
           , lpad('0',4,'0')                                                    YEA_PRO_RIC_ADS
           , rpad(' ',8)                                                        NUM_PRO_RIC_ADS
           , rpad(' ',20)                                                       REG_PRO_RIC_ADS
           , lpad('0',18,'0')                                                   ID_ORI_ULT_RIC
           , 'N'                                                                FLG_SOS_RUO
           , rpad(' ',16)                                                       COD_MOT_SOS_RUO
           , lpad('0',18,'0')                                                   ID_ORI_ELA_RUO
           , rpad(' ',8)                                                        DAT_PREC_RIC
           , rpad(nvl(prtr.flag_adesione,'N') ,8)                               FLG_ADE_FORM
           , decode(prtr.flag_adesione
                   ,'S',nvl(to_char(prtr.data_notifica,'yyyymmdd'),rpad(' ',8))
                   ,rpad(' ',8)
                   )                                                            DAT_ADE_FORM
           , rpad(' ',14)                                                       TMS_TIME_INS
           , rpad(' ',30)                                                       COD_UTE_INS
           , rpad(to_char(prtr.data_variazione,'yyyymmddhh24miss'),14)          TMS_TIME_VAR
           , rpad(prtr.utente,30)                                               COD_UTE_VAR
           , prtr.pratica
        from contribuenti      cont
           , pratiche_tributo  prtr
       where cont.cod_fiscale      = prtr.cod_fiscale
         and prtr.tipo_pratica     = 'A'
         and prtr.tipo_tributo||'' = 'TARSU'
         and exists (select 1
              from sanzioni_pratica sapr
             where sapr.pratica  = prtr.pratica
           )
           ;
   CURSOR sel_cari(p_pratica number) IS
      select rpad('CFIMDI',10)                                                  TIP_RECORD
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFIMDI
           , lpad(to_char(prtr.pratica),18,'0')                                 ID_ORI_CFPRVD
           , rpad(f_tipo_accertamento(prtr.pratica),16)                         TIP_PRV
           , to_char(prtr.anno)                                                 YEA_PRV
           , rpad(f_tipo_carico_rsu(prtr.pratica)
                 ,16)                                                           COD_MOT
           , rpad(to_char(f_max_ogge_pratica_rsu(prtr.pratica)),30)             ID_ORI_CF_AOGG
           , lpad('0',9,'0')                                                    ID_ORI_OGG_TRB
           , lpad('0',2,'0')                                                    RATA
           , rpad(f_pratica_a_ruolo(prtr.pratica),16)                           FLG_IMP_EMS
        --   , rpad(' ',16)                                                       FLG_INT_EMS
        --   , rpad(' ',16)                                                       FLG_SNZ_EMS
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'IMP') * 100
                    ,'S0000000000000')                                          IMP_DOV
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'SAN') * 100
                    ,'S0000000000')                                             IMP_MAG
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'SANRID') * 100
                    ,'S0000000000')                                             IMP_MAG_RID
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'')
                        ,'RO',' '
                        ,'RT',' '
                        ,'AU','OMEDENRSU'
                        ,'AR','INFDENRSU'
                        ,' '
                        )
                 ,16)                                                           TIP_INT
           , rpad(decode(f_tipo_carico_ici(prtr.pratica,prtr.tipo_pratica,'')
                        ,'RO',' '
                        ,'RT',' '
                        ,'AU','OMEDENRSU'
                        ,'AR','INFDENRSU'
                        ,' '
                        )
                 ,16)                                                           TIP_SNZ
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'INT') * 100
                    ,'S0000000000')                                             IMP_INT
           , rpad(' ',8)                                                        DAT_DEC_INT
           , rpad(' ',8)                                                        DAT_CAL_INT
           , lpad('0',5,'0')                                                    PRD_INT
           , lpad('0',7,'0')                                                    SPC_PRC_SNZ
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'ADDPRO') * 100
                    ,'S0000000000000')                                          IMP_ADD_P
           , to_char(f_importi_violazioni_rsu(prtr.pratica,'ADDCOM') * 100
                    ,'S0000000000000')                                          IMP_ADD_C
           , rpad(' ',16)                                                       COD_RAV_APP
           , rpad(' ',18)                                                       ID_ORI_CAL_INT
           , ' '                                                                FLG_APP_SNZ_MIN
           , lpad('0',18,'0')                                                   ID_ORI_CFDENT_ATT
           , lpad('0',18,'0')                                                   ID_ORI_CFRSDETT_ATT
        from pratiche_tributo  prtr
       where prtr.pratica          = p_pratica
         ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(80);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
              , rpad(nvl(com.denominazione ,' '),80)
           into w_cod_belfiore
              , w_comune_desc
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Provvedimenti TARSU
      for rec_prov in sel_prov loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'Provvedimenti TARSU '||rec_prov.ID_ORI_CFPRVD;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_prov.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_prov.ID_ORI_CFPRVD
                  ||rec_prov.ID_ORI_CFSOGG
                  ||rec_prov.COD_TRB
                  ||rec_prov.TIP_PRV
                  ||rec_prov.YEA_PRV
                  ||rec_prov.NUM_PRV
                  ||rec_prov.REG_PRO
                  ||rec_prov.NUM_PRO
                  ||rec_prov.YEA_PRO
                  ||rec_prov.PRG_PRO
                  ||rec_prov.DAT_PRO
                  ||rec_prov.DAT_GEN
                  ||rec_prov.YEA_RIF
                  ||rec_prov.IMP_SPS
                  ||rec_prov.IMP_TOT
                  ||rec_prov.INT_TOT
                  ||rec_prov.SNZ_TOT
                  ||rec_prov.DOV_TOT
                  ||rec_prov.TIP_IMP
                  ||rec_prov.SNZ_RID_TOT
                  ||rec_prov.DOV_RID_TOT
                  ||rec_prov.IMP_ADD_P
                  ||rec_prov.IMP_ADD_C
                  ||rec_prov.VRS
                  ||rec_prov.DAT_STA
                  ||rec_prov.COD_STA
                  ||rec_prov.DAT_ELA
                  ||rec_prov.DAT_VAL
                  ||rec_prov.DAT_SOS
                  ||rec_prov.DAT_ANN
                  ||rec_prov.DAT_NOT
                  ||rec_prov.COD_MOT_EMI
                  ||rec_prov.NOTE
                  ||rec_prov.DAT_STM
                  ||rec_prov.TIP_EMI_COO
                  ||rec_prov.COD_EMI_COO
                  ||rec_prov.COD_OT
                  ||rec_prov.ID_ORI_CFPRVD_CUM
                  ||rec_prov.ID_ORI_CFDENT_QUIR
                  ||rec_prov.COD_STA_PRC_ADS
                  ||rec_prov.DAT_RIC_ADS
                  ||rec_prov.DAT_CNF_ADS
                  ||rec_prov.DAT_PRF_ADS
                  ||rec_prov.YEA_PRO_RIC_ADS
                  ||rec_prov.NUM_PRO_RIC_ADS
                  ||rec_prov.REG_PRO_RIC_ADS
                  ||rec_prov.ID_ORI_ULT_RIC
                  ||rec_prov.FLG_SOS_RUO
                  ||rec_prov.COD_MOT_SOS_RUO
                  ||rec_prov.ID_ORI_ELA_RUO
                  ||rec_prov.DAT_PREC_RIC
                  ||rec_prov.FLG_ADE_FORM
                  ||rec_prov.DAT_ADE_FORM
                  ||rec_prov.TMS_TIME_INS
                  ||rec_prov.COD_UTE_INS
                  ||rec_prov.TMS_TIME_VAR
                  ||rec_prov.COD_UTE_VAR
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Provvedimenti TARSU '||
                                              ' key: '||rec_prov.ID_ORI_CFPRVD||
                                              ' ('||sqlerrm||')');
         end;
         -- Tracciato Provvedimenti RSU: Carichi
         for rec_cari in sel_cari(rec_prov.pratica) loop
            w_progressivo  := w_progressivo + 1;
            w_interruzione := 'Provvedimenti RSU: Carichi '||rec_cari.ID_ORI_CFIMDI;
            begin
               insert into wrk_trasmissioni
                    (numero,dati)
               values( lpad(w_progressivo,15,0)
                     , rec_cari.TIP_RECORD
                     ||w_cod_belfiore                  -- COD_ENTE
                     ||rec_cari.ID_ORI_CFIMDI
                     ||rec_cari.ID_ORI_CFPRVD
                     ||rec_cari.TIP_PRV
                     ||rec_cari.YEA_PRV
                     ||rec_cari.COD_MOT
                     ||rec_cari.ID_ORI_CF_AOGG
                     ||rec_cari.ID_ORI_OGG_TRB
                     ||rec_cari.RATA
                     ||rec_cari.FLG_IMP_EMS
                     ||rec_cari.FLG_IMP_EMS     -- FLG_INT_EMS
                     ||rec_cari.FLG_IMP_EMS     -- FLG_SNZ_EMS
                     ||rec_cari.IMP_DOV
                     ||rec_cari.IMP_MAG
                     ||rec_cari.IMP_MAG_RID
                     ||rec_cari.TIP_INT
                     ||rec_cari.TIP_SNZ
                     ||rec_cari.IMP_INT
                     ||rec_cari.DAT_DEC_INT
                     ||rec_cari.DAT_CAL_INT
                     ||rec_cari.IMP_INT         -- IMP_INT_ORI
                     ||rec_cari.IMP_MAG         -- IMP_MAG_ORI
                     ||rec_cari.PRD_INT
                     ||rec_cari.IMP_DOV         -- BAS_IMP_CAL_MAG
                     ||rec_cari.SPC_PRC_SNZ
                     ||rec_cari.IMP_DOV         -- BAS_IMP_CAL_INT
                     ||rec_cari.IMP_ADD_P
                     ||rec_cari.IMP_ADD_C
                     ||rec_cari.COD_RAV_APP
                     ||rec_cari.ID_ORI_CAL_INT
                     ||rec_cari.FLG_APP_SNZ_MIN
                     ||rec_cari.ID_ORI_CFDENT_ATT
                     ||rec_cari.ID_ORI_CFRSDETT_ATT
                     )
                ;
            exception
               when others then
                  raise_application_error(-20919,'Errore in Provvedimenti RSU: Carichi '||
                                                 ' key: '||rec_cari.ID_ORI_CFIMDI||
                                                 ' ('||sqlerrm||')');
            end;
         end loop;
      end loop;
   end;
   procedure classe_tariffa_rsu is
   CURSOR sel_tar IS
      select rpad('CFRSCLTAR',10)                                               TIP_RECORD
           , lpad(to_char(tari.tributo),4,'0')
           ||lpad(to_char(tari.categoria),4,'0')
           ||lpad(to_char(tari.tipo_tariffa),2,'0')
           ||rpad(' ',6)                                                        COD_CLS_TAR
           , lpad(to_char(nvl(tari.anno,1900))||'0101',8,'0')                   DAT_INI
           , lpad(to_char(nvl(tari.anno,1900))||'0101',8,'0')                   DAT_FIN
           , substr(rpad(cate.descrizione
                       ||decode(tari.descrizione
                               ,null,''
                               ,' - '||tari.descrizione
                               )
                        ,80)
                   ,1,80)                                                       DES_CLS_TAR
           , replace(to_char(tari.tariffa *  100000,'FM000000000'),'.',',')               IMP_UNIT
        from tariffe     tari
           , categorie   cate
       where cate.categoria  = tari.categoria
         and cate.tributo    = tari.tributo
         and tari.anno >= 1900
    order by tari.anno
           , tari.tributo
           , tari.categoria
           , tari.tipo_tariffa
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Aliquote Ici
      for rec_tar in sel_tar loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'tariffe TARSU '||rec_tar.COD_CLS_TAR;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_tar.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_tar.COD_CLS_TAR
                  ||rec_tar.DAT_INI
                  ||rec_tar.DAT_FIN
                  ||rec_tar.DES_CLS_TAR
                  ||rec_tar.IMP_UNIT
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in Tariffe TARSU '||
                                              ' key: '||rec_tar.COD_CLS_TAR||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
   procedure tipi_oggetto_rsu is
   CURSOR sel_tota IS
      select rpad('CFTPORSU',10)                                                TIP_RECORD
           , lpad('1',16,'0')                                                   COD_TAB
           , lpad(to_char(tiog.tipo_oggetto),16,'0')                            COD_COD
           , rpad(nvl(tiog.descrizione,' '),80)                                 DES_COD
        from tipi_oggetto     tiog
           , oggetti_tributo  ogti
       where tiog.tipo_oggetto = ogti.tipo_oggetto
         and ogti.tipo_tributo = 'TARSU'
           ;
   w_interruzione       varchar2(500);
   w_progressivo        number := 0;
   w_comune_utente      varchar2(6);
   w_cod_belfiore       varchar2(4);
   w_comune_desc        varchar2(50);
   w_data_estrazione    varchar2(10);
   begin
      --Cancello la tabella di lavoro
      SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
      -- Estrazione Codice Catastale Ente
      begin
         select rpad(nvl(com.sigla_cfis,' '),4)
           into w_cod_belfiore
           from dati_generali       dage
              , ad4_comuni          com
          where com.provincia_stato   = dage.pro_cliente
            and com.comune            = dage.com_cliente
              ;
      exception
         when others then
            raise_application_error(-20919,'Errore Estrazione Codice Catastale Ente'||
                                           ' ('||sqlerrm||')');
      end;
      -- Tracciato Aliquote Ici
      for rec_tota in sel_tota loop
         w_progressivo  := w_progressivo + 1;
         w_interruzione := 'tipi oggetti TARSU '||rec_tota.COD_COD;
         begin
            insert into wrk_trasmissioni
                 (numero,dati)
            values( lpad(w_progressivo,15,0)
                  , rec_tota.TIP_RECORD
                  ||w_cod_belfiore                  -- COD_ENTE
                  ||rec_tota.COD_TAB
                  ||rec_tota.COD_COD
                  ||rec_tota.DES_COD
                  )
             ;
         exception
            when others then
               raise_application_error(-20919,'Errore in tipi oggetto TARSU '||
                                              ' key: '||rec_tota.COD_COD||
                                              ' ('||sqlerrm||')');
         end;
      end loop;
   end;
END TR4ER_ELIFIS;
/

