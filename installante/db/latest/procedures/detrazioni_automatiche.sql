--liquibase formatted sql 
--changeset abrandolini:20250326_152423_detrazioni_automatiche stripComments:false runOnChange:true 
 
create or replace procedure DETRAZIONI_AUTOMATICHE
/*************************************************************************
Versione  Data              Autore    Descrizione
2         20/09/2023        VM        #66699 - sostituito filtro ricerca sogg.cognome_nome
                                      con sogg.cognome_nome_ric
1         01/04/2015        VD        Unificato trattamento dei 4 cursori
                                      Le detrazione vengono sempre
                                      riproporzionate ai mesi di possesso
                                      e alla detrazione base
**************************************************************************/
( a_anno           IN   number
, a_cognome_nome   IN   varchar2
, a_cod_fiscale    IN   varchar2
, a_tipo_tributo   IN   varchar2
)
is
  w_detrazione                number;
  w_detrazione_prec           number;
  w_detrazione_base           number;
  w_detrazione_base_prec      number;
  w_motivo_det                number:=99;
  w_motivo_det2               number:=98;
  w_motivo_det3               number:=97;
  w_detrazione_cal            number:=0;
  errore                      exception;
  w_errore                    varchar2(2000);
--a_tipo_tributo varchar2(5) := 'ICI';
cursor sel_ogco_acc is
       select ogco.cod_fiscale,
              ogco.detrazione,
              ogco.anno,
              nvl(ogco.mesi_possesso,12) mesi_possesso,
              decode(nvl(ogco.mesi_possesso,12),
--                     0,f_round(nvl(ogco.detrazione,w_detrazione_base_prec),0),
                     0,f_round(nvl(ogco.detrazione,w_detrazione_base),0),
                       f_round((ogco.detrazione/ogco.mesi_possesso)*12,0)) detrazione_cal
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              pratiche_tributo prtr,
              soggetti sogg,
              contribuenti cont
        where ogco.flag_ab_principale = 'S'
          and ((nvl(ogco.detrazione,0)  >  0
                and nvl(ogco.mesi_possesso,12)  between 1 and 11)
               or nvl(ogco.mesi_possesso,12) = 0)
          and ogco.flag_possesso is not null
          and ogpr.categoria_catasto like 'A%'
          and ogco.anno = (select max(ogco2.anno)
                             from oggetti_contribuente ogco2,
                                  oggetti_pratica ogpr2,
                                  pratiche_tributo prtr2
                            where ogco2.cod_fiscale        = ogco.cod_fiscale
                              and ogco2.flag_ab_principale = 'S'
                              and ogco2.anno              <= a_anno
                              and ogco2.oggetto_pratica    = ogpr2.oggetto_pratica
                              and ogpr2.pratica            = prtr2.pratica
                              and prtr2.tipo_pratica       = 'A'
                              and prtr2.tipo_tributo       = a_tipo_tributo)
          and not exists ( select 'x'
                             from oggetti_contribuente ogco3,
                                  oggetti_pratica ogpr3,
                                  pratiche_tributo prtr3
                            where ogco3.anno           <= a_anno
                              and ogco3.anno            > ogco.anno
                              and ogco3.cod_fiscale     = ogco.cod_fiscale
                              and ogco3.detrazione is not null
                              and ogco3.oggetto_pratica = ogpr3.oggetto_pratica
                              and ogpr3.pratica         = prtr3.pratica
                              and prtr3.tipo_pratica    = 'A'
                              and prtr3.tipo_tributo    = a_tipo_tributo)
          and not exists ( select 'x'
                             from maggiori_detrazioni made
                            where made.anno         = a_anno
                              and made.cod_fiscale  = ogco.cod_fiscale
                              and made.tipo_tributo = a_tipo_tributo)
          and ogco.oggetto_pratica = ogpr.oggetto_pratica
          and ogpr.pratica         = prtr.pratica
          and prtr.tipo_pratica    = 'A'
          and prtr.tipo_tributo    = a_tipo_tributo
          and ogco.cod_fiscale     = cont.cod_fiscale
          and sogg.ni              = cont.ni
          and sogg.cognome_nome_ric like nvl(a_cognome_nome,'%')
          and cont.cod_fiscale  like nvl(a_cod_fiscale,'%')
       ;
cursor sel_ogco_acc12 is
       select ogco.cod_fiscale,
              ogco.detrazione,
              ogco.anno,
              nvl(ogco.mesi_possesso,12) mesi_possesso,
              ogco.detrazione detrazione_cal
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              pratiche_tributo prtr,
              soggetti sogg,
              contribuenti cont
        where ogco.flag_ab_principale = 'S'
          and nvl(ogco.detrazione,0)     > 0
          and nvl(ogco.mesi_possesso,12) = 12
          and ogco.flag_possesso is not null
          and ogpr.categoria_catasto like 'A%'
          and ogco.anno = (select max(ogco2.anno)
                             from oggetti_contribuente ogco2,
                                  oggetti_pratica ogpr2,
                                  pratiche_tributo prtr2
                            where ogco2.cod_fiscale        = ogco.cod_fiscale
                              and ogco2.flag_ab_principale = 'S'
                              and ogco2.anno              <= a_anno
                              and ogco2.oggetto_pratica    = ogpr2.oggetto_pratica
                              and ogpr2.pratica            = prtr2.pratica
                              and prtr2.tipo_pratica       = 'A'
                              and prtr2.tipo_tributo       = a_tipo_tributo)
          and not exists ( select 'x'
                             from oggetti_contribuente ogco3,
                                  oggetti_pratica ogpr3,
                                  pratiche_tributo prtr3
                            where ogco3.anno            <= a_anno
                              and ogco3.anno            > ogco.anno
                              and ogco3.cod_fiscale     = ogco.cod_fiscale
                              and ogco3.detrazione is not null
                              and ogco3.oggetto_pratica = ogpr3.oggetto_pratica
                              and ogpr3.pratica         = prtr3.pratica
                              and prtr3.tipo_pratica    = 'A'
                              and prtr3.tipo_tributo    = a_tipo_tributo)
          and not exists ( select 'x'
                    from maggiori_detrazioni made
                   where made.anno        = a_anno
                     and made.cod_fiscale = ogco.cod_fiscale
                     and made.tipo_tributo = a_tipo_tributo)
          and ogco.oggetto_pratica = ogpr.oggetto_pratica
          and ogpr.pratica         = prtr.pratica
          and prtr.tipo_pratica    = 'A'
          and prtr.tipo_tributo = a_tipo_tributo
          and ogco.cod_fiscale     = cont.cod_fiscale
          and sogg.ni              = cont.ni
          and sogg.cognome_nome_ric like nvl(a_cognome_nome,'%')
          and cont.cod_fiscale  like nvl(a_cod_fiscale,'%')
       ;
cursor sel_ogco is
       select ogco.cod_fiscale,
              ogco.detrazione,
              ogco.anno,
              nvl(ogco.mesi_possesso,12) mesi_possesso,
              decode(nvl(ogco.mesi_possesso,12),
--               0,f_round(nvl(ogco.detrazione,w_detrazione_base_prec),0),
               0,f_round(nvl(ogco.detrazione,w_detrazione_base),0),
               f_round((ogco.detrazione/ogco.mesi_possesso)*12,0)) detrazione_cal
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              pratiche_tributo prtr,
              soggetti sogg,
              contribuenti cont
        where ogco.flag_ab_principale   = 'S'
          and ((nvl(ogco.detrazione,0)  >  0              and
                nvl(ogco.mesi_possesso,12)  between 1 and 11)  or
                nvl(ogco.mesi_possesso,12) = 0)
          and ogco.flag_possesso is not null
          and ogpr.categoria_catasto like 'A%'
          and ogco.anno =
             (select max(ogco2.anno)
                            from oggetti_contribuente ogco2,
                                 oggetti_pratica ogpr2,
                                 pratiche_tributo prtr2
                           where ogco2.cod_fiscale         = ogco.cod_fiscale
                             and ogco2.flag_ab_principale  = 'S'
                             and ((nvl(ogco2.detrazione,0) > 0 and
                                   nvl(ogco2.mesi_possesso,12) between 1 and 11)
             or
                                   nvl(ogco2.mesi_possesso,12) = 0)
                             and ogco2.anno            < a_anno
                             and ogco2.oggetto_pratica = ogpr2.oggetto_pratica
                             and ogpr2.pratica         = prtr2.pratica
                             and prtr2.tipo_pratica    = 'D'
                             and prtr2.tipo_tributo||'' = a_tipo_tributo)
          and not exists ( select 'x'
                             from oggetti_contribuente ogco3,
                                  oggetti_pratica ogpr3,
                                  pratiche_tributo prtr3
                            where ogco3.anno            <= a_anno
                              and ogco3.anno            > ogco.anno
                              and ogco3.cod_fiscale     = ogco.cod_fiscale
                              and ogco3.detrazione is not null
                              and ogco3.oggetto_pratica = ogpr3.oggetto_pratica
                              and ogpr3.pratica         = prtr3.pratica
                              and prtr3.tipo_pratica    = 'D'
                              and prtr3.tipo_tributo||'' = a_tipo_tributo)
          and not exists ( select 'x'
                             from maggiori_detrazioni made
                            where made.anno        = a_anno
                              and made.cod_fiscale = ogco.cod_fiscale
                              and made.tipo_tributo = a_tipo_tributo)
          and ogco.oggetto_pratica = ogpr.oggetto_pratica
          and ogpr.pratica         = prtr.pratica
          and prtr.tipo_pratica    = 'D'
          and prtr.tipo_tributo||'' = a_tipo_tributo
          and ogco.cod_fiscale     = cont.cod_fiscale
          and sogg.ni              = cont.ni
          and sogg.cognome_nome_ric like nvl(a_cognome_nome,'%')
          and cont.cod_fiscale  like nvl(a_cod_fiscale,'%')
       ;
cursor sel_ogco12 is
       select ogco.cod_fiscale,
              ogco.detrazione,
              ogco.anno,
              nvl(ogco.mesi_possesso,12) mesi_possesso,
              ogco.detrazione detrazione_cal
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              pratiche_tributo prtr,
--              detrazioni detr,
              soggetti sogg,
              contribuenti cont
        where ogco.flag_ab_principale    = 'S'
          and nvl(ogco.detrazione,0)     > 0
          and nvl(ogco.mesi_possesso,12) = 12
          and ogco.flag_possesso is not null
--          and ogco.anno                  = detr.anno
--          and detr.tipo_tributo = a_tipo_tributo
--          and detr.detrazione_base       != w_detrazione_base        ??????
          and ogpr.categoria_catasto like 'A%'
          and ogco.anno = (select max(ogco2.anno)
                             from oggetti_contribuente ogco2,
                                  oggetti_pratica ogpr2,
                                  pratiche_tributo prtr2
                            where ogco2.cod_fiscale       = ogco.cod_fiscale
                              and ogco2.flag_ab_principale    = 'S'
                              and nvl(ogco2.detrazione,0)    > 0
                              and nvl(ogco2.mesi_possesso,12)    = 12
                              and ogco2.anno          < a_anno
                              and ogco2.oggetto_pratica    = ogpr2.oggetto_pratica
                              and ogpr2.pratica       = prtr2.pratica
                              and prtr2.tipo_pratica       = 'D'
                              and prtr2.tipo_tributo||'' = a_tipo_tributo)
          and not exists ( select 'x'
                             from oggetti_contribuente ogco3,
                                  oggetti_pratica ogpr3,
                                  pratiche_tributo prtr3
                            where ogco3.anno            <= a_anno
                              and ogco3.anno            > ogco.anno
                              and ogco3.cod_fiscale     = ogco.cod_fiscale
                              and ogco3.detrazione is not null
                              and ogco3.oggetto_pratica = ogpr3.oggetto_pratica
                              and ogpr3.pratica         = prtr3.pratica
                              and prtr3.tipo_pratica    = 'D'
                              and prtr3.tipo_tributo||'' = a_tipo_tributo)
          and not exists ( select 'x'
                             from maggiori_detrazioni made
                            where made.anno        = a_anno
                              and made.cod_fiscale = ogco.cod_fiscale
                              and made.tipo_tributo = a_tipo_tributo)
          and ogco.oggetto_pratica = ogpr.oggetto_pratica
          and ogpr.pratica         = prtr.pratica
          and prtr.tipo_pratica    = 'D'
          and prtr.tipo_tributo||'' = a_tipo_tributo
          and ogco.cod_fiscale     = cont.cod_fiscale
          and sogg.ni              = cont.ni
          and sogg.cognome_nome_ric like nvl(a_cognome_nome,'%')
          and cont.cod_fiscale  like nvl(a_cod_fiscale,'%')
       ;
cursor sel_made_del is
select made.anno,
       made.cod_fiscale
  from soggetti            sogg,
       contribuenti        cont,
       maggiori_detrazioni made
 where sogg.ni                  = cont.ni
   and cont.cod_fiscale         = made.cod_fiscale
   and made.motivo_detrazione  in (w_motivo_det,w_motivo_det2,w_motivo_det3)
   and made.anno                = a_anno
   and made.tipo_tributo        = a_tipo_tributo
   and made.cod_fiscale      like nvl(a_cod_Fiscale,'%')
   and sogg.cognome_nome_ric like nvl(a_cognome_nome,'%')
;
procedure TRATTA_MADE
( p_ogco_anno                number
, p_ogco_detrazione_cal      number
, p_ogco_cod_fiscale         varchar2
, p_motivo_det               varchar2
) is
begin
--
-- Si riproporziona la detrazione calcolata alla detrazione base
--
  begin
    select decode(sign(w_detrazione -
                       ((p_ogco_detrazione_cal / detrazione_base) *
                         w_detrazione_base)),1,
                       ((p_ogco_detrazione_cal / detrazione_base) *
                         w_detrazione_base),
                         w_detrazione_base)
     into w_detrazione_cal
     from detrazioni
    where anno = p_ogco_anno
      and tipo_tributo = a_tipo_tributo
  ;
  exception
    when no_data_found then
         null;
    when others then
         w_errore := 'Errore nel calcolo detrazione' ||
                     ' ('||sqlerrm||')';
         raise errore;
  end;
--
  begin
    insert into maggiori_detrazioni
           ( cod_fiscale
           , anno
           , detrazione
           , motivo_detrazione
           , tipo_tributo
           )
    select p_ogco_cod_fiscale
         , a_anno
         , least(w_detrazione_cal,w_detrazione_base)
         , p_motivo_det
         , a_tipo_tributo
      from dual
     where not exists (select 'x'
                         from maggiori_detrazioni made
                        where made.anno = a_anno
                          and made.cod_fiscale = p_ogco_cod_fiscale
                          and made.motivo_detrazione = p_motivo_det
                          and made.tipo_tributo = a_tipo_tributo)
    ;
    if sql%rowcount = 0 then
       begin
         update maggiori_detrazioni
            set detrazione = least(w_detrazione_cal,w_detrazione_base)
          where anno = a_anno
            and cod_fiscale = p_ogco_cod_fiscale
            and motivo_detrazione = p_motivo_det
            and tipo_tributo = a_tipo_tributo
       ;
       exception
         when others then
              w_errore := 'Errore in aggiornamento Maggiori Detrazioni ' ||
                          p_ogco_cod_fiscale ||' - '|| p_motivo_det ||
                          ' ('||sqlerrm||')';
              raise errore;
       end;
    end if;
  exception
    when errore then
         raise;
    when others then
         w_errore := 'Errore in inserimento Maggiori Detrazioni ' ||
                     p_ogco_cod_fiscale ||' - '|| p_motivo_det ||
                     ' ('||sqlerrm||')';
         raise errore;
  end;
end TRATTA_MADE;
----------------------
-- Inizio trattamento
----------------------
begin
  BEGIN
    select detrazione,detrazione_base
      into w_detrazione,w_detrazione_base
      from detrazioni
     where anno = a_anno
       and tipo_tributo = a_tipo_tributo
    ;
  EXCEPTION
    WHEN no_data_found THEN
         w_errore := 'Non esiste la detrazione per l''anno indicato' ||
                     ' ('||SQLERRM||')';
         RAISE errore;
    WHEN others THEN
         w_errore := 'Errore in ricerca Detrazioni' ||
                     ' ('||SQLERRM||')';
         RAISE errore;
  END;
--
/*  BEGIN
    select detrazione,detrazione_base
      into w_detrazione_prec,w_detrazione_base_prec
      from detrazioni
     where anno = (a_anno - 1)
       and tipo_tributo = a_tipo_tributo
    ;
  EXCEPTION
    WHEN no_data_found THEN
         w_errore := 'Non esiste la detrazione per l''anno precedente' ||
                     ' ('||SQLERRM||')';
         RAISE errore;
    WHEN others THEN
         w_errore := 'Errore in ricerca Detrazioni' ||
                     ' ('||SQLERRM||')';
         RAISE errore;
  END; */
--
-- Eliminazione maggiori detrazioni da elaborazioni precedenti
--
  for rec_made_del in sel_made_del
  loop
     begin
       delete maggiori_detrazioni made
        where made.anno        = rec_made_del.anno
          and made.cod_fiscale = rec_made_del.cod_fiscale
          and tipo_tributo = a_tipo_tributo
       ;
     exception
       when others then
            w_errore := 'Errore in cancellazione Maggiori Detrazioni'||
                        ' ('||sqlerrm||')';
            raise errore;
     end;
  end loop;
--
-- Trattamento accertamenti di oggetti posseduti per meno di 12 mesi
--
  for rec_ogco in sel_ogco_acc
  loop
-- dbms_output.put_line ('detrazione calcolata: '||rec_ogco.detrazione_cal);
    tratta_made ( rec_ogco.anno
                , rec_ogco.detrazione_cal
                , rec_ogco.cod_fiscale
                , w_motivo_det3
                );
  end loop;
--
-- Trattamento accertamenti di oggetti posseduti per 12 mesi
--
  for rec_ogco in sel_ogco_acc12 loop
-- dbms_output.put_line ('detrazione calcolata: '||rec_ogco.detrazione_cal);
    tratta_made ( rec_ogco.anno
                , rec_ogco.detrazione_cal
                , rec_ogco.cod_fiscale
                , w_motivo_det3
                );
  end loop;
--
-- Trattamento denunce di oggetti posseduti per meno di 12 mesi
--
  for rec_ogco in sel_ogco loop
    tratta_made ( rec_ogco.anno
                , rec_ogco.detrazione_cal
                , rec_ogco.cod_fiscale
                , w_motivo_det
                );
  end loop;
--
-- Trattamento denunce di oggetti posseduti per 12 mesi
--
  for rec_ogco in sel_ogco12 loop
-- dbms_output.put_line ('detrazione calcolata: '||rec_ogco.detrazione_cal);
    tratta_made ( rec_ogco.anno
                , rec_ogco.detrazione_cal
                , rec_ogco.cod_fiscale
                , w_motivo_det2
                );
  end loop;
--
exception
  when errore then
       rollback;
       raise_application_error (-20999,w_errore);
  when others then
       rollback;
       raise_application_error (-20999,'Errore in Calcolo Automatico Detrazioni' ||
                                       ' ('||sqlerrm||')');
end;
/* End Procedure: DETRAZIONI_AUTOMATICHE */
/

