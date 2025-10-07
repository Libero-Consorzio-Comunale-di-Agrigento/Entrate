--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_prossima_pratica stripComments:false runOnChange:true 
 
create or replace function F_PROSSIMA_PRATICA
(a_pratica      in number
,a_cod_fiscale  in varchar2
,a_tipo_tributo in varchar2
) Return String is
fine                         exception;
sSTringa                     varchar2(20);
nOggetto_Pratica             number;
nOggetto_Pratica_Rif         number;
dData                        date;
sTipo_Evento                 varchar2(1);
dDal                         date;
nPratica                     number;
sFlag_Annullamento          varchar2(1);
BEGIN
-- Se Tipo Tributo non e` TARSU , TOSAP, ICP,
-- non si esegue il trattamento.
   if a_tipo_tributo in ('ICI','ICIAP') then
      RAISE FINE;
   end if;
-- Se non esiste l`oggetto pratica oppure esistono piu`
-- oggetti pratica, non si puo` ricavare la Pratica.
   BEGIN
      select ogpr.oggetto_pratica
            ,nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
            ,nvl(prtr.data,to_date('01011900','ddmmyyyy'))
            ,prtr.tipo_evento
         ,prtr.flag_annullamento
        into nOggetto_Pratica
            ,nOggetto_Pratica_Rif
            ,dData
            ,sTipo_Evento
         ,sFlag_Annullamento
        from pratiche_tributo   prtr
            ,oggetti_pratica    ogpr
       where prtr.pratica          = ogpr.pratica
         and prtr.pratica          = a_pratica
         and prtr.tipo_tributo||'' = a_tipo_tributo
         and prtr.cod_fiscale      = a_cod_fiscale
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         RAISE FINE;
   END;
-- Se pratica Annullata,
-- non si esegue il trattamento.
   if nvl(sFlag_Annullamento,' ') = 'S' then
      RAISE FINE;
   end if;
-- Gli eventi di chiusura non hanno pratica successiva.
   if sTipo_Evento = 'C' then
      RAISE FINE;
   end if;
-- Determinazione della validita` della Pratica.
   BEGIN
      select nvl(ogco.data_decorrenza
                ,nvl(ogco.data_cessazione
                    ,to_date('01011900','ddmmyyyy')
                    )
                )
        into dDal
        from oggetti_contribuente ogco
       where ogco.cod_fiscale         = a_cod_fiscale
         and ogco.oggetto_pratica     = nOggetto_Pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         RAISE FINE;
   END;
dbms_output.put_line('OGPR '||to_char(nOggetto_Pratica)||' Dal '||to_char(dDal,'ddmmyyyy'));
-- Determinazione della Pratica Successiva a quella data.
   BEGIN
      select substr(min(to_char(nvl(ogco.data_decorrenza
                                   ,nvl(ogco.data_cessazione
                                       ,to_date('01011900','ddmmyyyy')
                                       )
                                   )
                               ,'yyyymmdd'
                               )||
                        to_char(nvl(prtr.data,to_date('01011900','ddmmyyyy'))
                               ,'yyyymmdd'
                               )||
                        lpad(to_char(prtr.pratica),10,'0')||
                        prtr.tipo_evento
                       ),17,11
                   )
        into sStringa
        from oggetti_contribuente  ogco
            ,oggetti_pratica       ogpr
            ,pratiche_tributo      prtr
       where prtr.pratica             = ogpr.pratica
         and ogpr.oggetto_pratica     = ogco.oggetto_pratica
         and ogpr.oggetto_pratica_rif = nOggetto_Pratica_Rif
         and ogco.cod_fiscale         = a_cod_fiscale
         and prtr.tipo_tributo||''    = a_tipo_tributo
       and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')        = 'S'
       and nvl(prtr.stato_accertamento,'D') = 'D'
         and to_char(nvl(ogco.data_decorrenza
                        ,nvl(ogco.data_cessazione,to_date('01011900','ddmmyyyy'))
                        ),'yyyymmdd'
                    )||
             to_char(nvl(prtr.data,to_date('01011900','ddmmyyyy')),'yyyymmdd')||
             lpad(to_char(prtr.pratica),10,'0')
                                         >
             to_char(dDal,'yyyymmdd')||to_char(dData,'yyyymmdd')||
             lpad(to_char(a_pratica),10,'0')
      and prtr.flag_annullamento is null
      ;
      sStringa := substr(sStringa,11,1)||substr(sStringa,1,10);
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         RAISE FINE;
   END;
   Return sStringa;
EXCEPTION
   WHEN FINE THEN
      RETURN '';
END;
/* End Function: F_PROSSIMA_PRATICA */
/

