--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_ogim stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_OGIM
(a_pratica              in number
,a_anno                 in number
,a_cod_fiscale          in varchar2
) return number is
nImporto                number;
nConta                  number;
sTipo_Pratica           varchar2(1);
sFlag_Denuncia          varchar2(1);
iAnno                   number(4);
sFlag_Calcolo           varchar2(1);
sTipo_tributo           varchar2(5);
BEGIN
   BEGIN
      select anno
            ,tipo_pratica
            ,flag_denuncia
            ,tipo_tributo
        into iAnno
            ,sTipo_Pratica
            ,sFlag_Denuncia
            ,sTipo_tributo
        from pratiche_tributo
       where pratica           = a_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         nImporto := null;
         Return nImporto;
   END;
   if sTipo_Pratica = 'D'
   or sTipo_Pratica = 'C'
   or sTipo_Pratica = 'A' and sFlag_Denuncia = 'S' and iAnno < a_anno then
      sFlag_Calcolo := 'S';
   else
      sFlag_Calcolo := '%';
   end if;
   BEGIN
      select sum(decode(ogim.ruolo
               ,null,ogim.imposta
                    ,F_IMPOSTA_RUOL_CONT_ANNO_TITR(ogim.cod_fiscale
                                                  ,ogim.anno
                                                  ,prtr.tipo_tributo
                                                  ,ogim.oggetto_pratica
                                                  ,nvl(cotr.conto_corrente
                                                      ,titr.conto_corrente
                                                      )
                                                  ,ogim.ruolo
                                                  )
                         )
                  )
            ,count(*)
        into nImporto
            ,nConta
        from oggetti_pratica ogpr
            ,oggetti_imposta ogim
            ,codici_tributo  cotr
            ,tipi_tributo    titr
            ,pratiche_tributo prtr
       where ogpr.oggetto_pratica   = ogim.oggetto_pratica
         and ogim.anno              = a_anno
         and ogpr.pratica           = a_pratica
         and nvl(ogim.flag_calcolo,' ')
                                 like sFlag_Calcolo
         and ogim.cod_fiscale       = a_cod_fiscale
         and cotr.tributo      (+)  = ogpr.tributo
         and titr.tipo_tributo      = prtr.tipo_tributo
         and prtr.pratica           = ogpr.pratica
      ;
      if nConta = 0 then
         RAISE NO_DATA_FOUND;
      end if;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         BEGIN
/* In assenza di Oggetti Imposta vengono scartati gli Accertamenti */
/* e le Denunce che non sono dell`anno in esame.                    */
            if sTipo_Pratica         = 'A' then
               nImporto := null;
            elsif sTipo_Pratica      = 'C'
            or iAnno                 = a_anno then
               nImporto := 0;
            else
               nImporto := null;
            end if;
         END;
   END;
   Return nImporto;
END;
/* End Function: F_IMPORTO_OGIM */
/

