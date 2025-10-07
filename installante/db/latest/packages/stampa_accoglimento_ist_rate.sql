--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_accoglimento_ist_rate stripComments:false runOnChange:true 
 
create or replace package stampa_accoglimento_ist_rate is
  function contribuente(a_pratica number default -1) return sys_refcursor;
  function accoglimento_istanza(a_pratica number default -1)
    return sys_refcursor;
end stampa_accoglimento_ist_rate;
/
create or replace package body stampa_accoglimento_ist_rate is
  function contribuente(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica);
    return rc;
  end;
  function accoglimento_istanza(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
  
    open rc for
      select a_pratica as pratica,
             f_descrizione_titr(prtr.tipo_tributo, prtr.anno) descr_titr,
             'Avviso di Accertamento ' ||
             f_descrizione_titr(prtr.tipo_tributo, prtr.anno) || ' n. ' ||
             prtr.numero || ' relativo all''anno d''imposta ' || prtr.anno dett_pratica_1,
             'Importo da rateizzare: ' ||
             lpad(translate(to_char(decode(prtr.tipo_tributo,
                                           'TARSU',
                                           decode(nvl(cata.flag_lordo, 'N'),
                                                  'S',
                                                  f_importi_acc(prtr.pratica,
                                                                'N',
                                                                'LORDO'),
                                                  f_importi_acc(prtr.pratica,
                                                                'N',
                                                                'NETTO')),
                                           f_round(prtr.importo_totale, 1)) +
                                    nvl(prtr.mora, 0) -
                                    nvl(prtr.versato_pre_rate, 0),
                                    '9,999,999,999,990.00'),
                            ',.',
                            '.,'),
                  25) dett_pratica_2,
             to_char(prtr.data_rateazione, 'DD/MM/YYYY') as data_rateazione,
             sopr.*
             , sopr.data_pratica AS data
        from pratiche_tributo prtr,
             carichi_tarsu    cata,
             soggetti_pratica sopr
       where prtr.pratica = a_pratica
         and prtr.anno = cata.anno(+)
         and sopr.pratica = a_pratica;
    return rc;
  end;
end stampa_accoglimento_ist_rate;
/
