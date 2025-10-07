--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_concessione_attiva stripComments:false runOnChange:true 
 
create or replace function F_CONCESSIONE_ATTIVA
(a_cod_fiscale      in varchar2
,a_tipo_tributo     in varchar2
,a_anno             in number
,a_pratica          in number
,a_oggetto_pratica  in number
,a_oggetto_imposta  in number
) Return String is
w_return               varchar2(2);
w_pratica              number;
w_anno                 number;
w_conta                number;
w_conta_distinct       number;
w_data_concessione     date;
  w_cod_istat          varchar2(6);
--  Pratica, Oggetto Pratica e Oggetto Imposta sono
--  in alternativa tra loro.
--  Si dice che esiste una concessione attiva se:
--  1 - Tipo Tributo = TOSAP
--  2 - Anno della Pratica = Anno da parametri
--  3 - Data Concessione di Oggetti Pratica significativa
--      e tutti gli Oggetti Pratica della Pratica hanno
--      la stessa data di concessione
--  4 - Non esistono Rate Imposta per la Pratica
--      oppure
--    - Esistono Rate Imposta per gli Oggetti Imposta
--      della Pratica relativamente all`anno da parametri
BEGIN
-- Tipo Tributo non TOSAP.
  BEGIN
    select lpad(to_char(pro_cliente), 3, '0') ||
           lpad(to_char(com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali;
    END;
   if a_tipo_tributo <> 'TOSAP' then
      Return 'NO';
   end if;
-- Modifica di Betta il 17/10/2008 per Impruneta
   if a_tipo_tributo = 'TOSAP'
       and w_cod_istat in ('048022','050029') THEN  -- Impruneta, Pontedera
      Return 'NO';
   end if;
   if  a_oggetto_imposta is null
   and a_oggetto_pratica is null
   and a_pratica         is null then
       Return 'NO';
   end if;
   BEGIN
      select prtr.pratica
            ,prtr.anno
        into w_pratica
            ,w_anno
        from oggetti_imposta   ogim
            ,oggetti_pratica   ogpr
            ,pratiche_tributo  prtr
       where ogim.oggetto_imposta  = a_oggetto_imposta
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
         and prtr.pratica          = ogpr.pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         BEGIN
            select prtr.pratica
                  ,prtr.anno
              into w_pratica
                  ,w_anno
              from oggetti_pratica   ogpr
                  ,pratiche_tributo  prtr
             where ogpr.oggetto_pratica  = a_oggetto_pratica
               and prtr.pratica          = ogpr.pratica
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               BEGIN
                  select prtr.pratica
                        ,prtr.anno
                    into w_pratica
                        ,w_anno
                    from pratiche_tributo  prtr
                   where prtr.pratica          = a_pratica
                  ;
               EXCEPTION
                  WHEN OTHERS THEN
                     Return '??';
               END;
            WHEN OTHERS THEN
               Return '??';
         END;
      WHEN OTHERS THEN
         Return '??';
   END;
-- Anno Pratica diverso.
   if w_anno <> a_anno then
      Return 'NO';
   end if;
   BEGIN
      select count(distinct nvl(ogpr.data_concessione,to_date('01011900','ddmmyyyy')))
            ,max(nvl(ogpr.data_concessione,to_date('01011900','ddmmyyyy')))
            ,count(*)
        into w_conta_distinct
            ,w_data_concessione
            ,w_conta
        from oggetti_pratica ogpr
       where ogpr.pratica = w_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         Return '??';
   END;
-- Oggetti Pratica con Date di Concessione diverse o Oggetti Pratica
-- senza Data di Concessione
   if w_conta_distinct > 1 or w_data_concessione = to_date('01011900','ddmmyyyy') then
      Return 'NO';
   end if;
   Return 'SI';
END;
/* End Function: F_CONCESSIONE_ATTIVA */
/

