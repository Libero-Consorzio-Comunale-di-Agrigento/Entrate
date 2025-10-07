--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_acc_concessioni stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACC_CONCESSIONI
(a_tipo_tributo in varchar2
,a_anno         in number
,a_cod_fiscale  in varchar2
,a_cognome_nome in varchar2
,a_utente       in varchar2
) IS
errore                  exception;
w_errore                varchar2(2000);
w_cf                    varchar2(16);
w_ins_pratica           varchar2(2);
--w_err                   number; --MAI USATO
w_ind                   number;
w_tot                   number;
w_dep                   number;
w_dep_r1                number;
w_dep_r2                number;
w_dep_r3                number;
w_dep_r4                number;
w_dep_rt                number;
--w_cod_sanzione          number; --MAI USATO
w_imposta               number;
w_imposta_r1            number;
w_imposta_r2            number;
w_imposta_r3            number;
w_imposta_r4            number;
w_imposta_rt            number;
w_scad_r1               date;
w_scad_r2               date;
w_scad_r3               date;
w_scad_r4               date;
w_scadenza_r1           date;
w_scadenza_r2           date;
w_scadenza_r3           date;
w_scadenza_r4           date;
w_omesso_r1             number;
w_omesso_r2             number;
w_omesso_r3             number;
w_omesso_r4             number;
w_eccedenza_r1          number;
w_eccedenza_r2          number;
w_eccedenza_r3          number;
w_eccedenza_r4          number;
w_versato_r1            number;
w_versato_r1_da_r2      number;
w_versato_r1_da_r3      number;
w_versato_r1_da_r4      number;
w_versato_r2            number;
w_versato_r2_da_r1      number;
w_versato_r2_da_r3      number;
w_versato_r2_da_r4      number;
w_versato_r3            number;
w_versato_r3_da_r1      number;
w_versato_r3_da_r2      number;
w_versato_r3_da_r4      number;
w_versato_r4            number;
w_versato_r4_da_r1      number;
w_versato_r4_da_r2      number;
w_versato_r4_da_r3      number;
w_data_versamento_r1    date;
w_data_versamento_r2    date;
w_data_versamento_r3    date;
w_data_versamento_r4    date;
w_tot_versato           number;
w_tot_versato_r1        number;
w_tot_versato_r2        number;
w_tot_versato_r3        number;
w_tot_versato_r4        number;
w_cod_fiscale_prec      varchar2(16);
w_cod_fiscale           varchar2(16);
w_oggetto_pratica       number;
w_oggetto_pratica_rif   number;
w_oggetto               number;
w_pratica               number;
w_data_pratica          date;
w_numero_pratica        varchar2(15);
w_tipo_pratica          varchar2(1);
w_tipo_evento           varchar2(1);
w_tipo_occupazione      varchar2(1);
w_dal                   date;
w_al                    date;
w_anno                  number;
w_data_concessione      date;
w_data_concessione_prec date;
w_tot_rate              number;
w_min_rata              number;
--w_min_ogim              number; --MAI USATO
--w_max_ogim              number; --MAI USATO
--w_conta                 number; --MAI USATO
w_stringa_vers_r1       varchar2(2300);
w_stringa_vers_r2       varchar2(2300);
w_stringa_vers_r3       varchar2(2300);
w_stringa_vers_r4       varchar2(2300);
w_stringa_eccedenze_r1  varchar2(2300);
w_stringa_eccedenze_r2  varchar2(2300);
w_stringa_eccedenze_r3  varchar2(2300);
w_stringa_eccedenze_r4  varchar2(2300);
w_ind_stringa           number;
--w_ind_stringa_2         number; --MAI USATO
w_imp_confronto         number;
--
--   Selezione delle pratiche scadute.
--   Vengono considerate solo le Pratiche TOSAP relative all`anno
--   con Data di Concessione.
--
cursor sel_acc (p_tipo_trib   varchar2
              , p_anno         number
              , p_cod_fiscale varchar2
              , p_cognome_nome varchar2) is
select ogva.cod_fiscale
      ,ogva.oggetto_pratica
      ,ogva.oggetto_pratica_rif
      ,ogva.oggetto
      ,ogva.pratica
      ,ogva.data
      ,ogva.numero
      ,ogva.anno
      ,ogva.tipo_pratica
      ,ogva.tipo_evento
      ,ogva.tipo_occupazione
      ,ogva.dal
      ,ogva.al
      ,ogpr.data_concessione
  from oggetti_pratica     ogpr
      ,oggetti_validita    ogva
      ,contribuenti        cont
      ,soggetti            sogg
 where cont.cod_fiscale                like p_cod_fiscale
   and sogg.ni                            = cont.ni
   and sogg.cognome_nome_ric           like p_cognome_nome
   and ogpr.oggetto_pratica               = ogva.oggetto_pratica
   and ogva.tipo_tributo||''              = p_tipo_trib
   and ogva.cod_fiscale                   = cont.cod_fiscale
   and nvl(to_number(to_char(ogva.dal,'yyyy')),0)
                                         <= p_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
                                         >= p_anno
   and decode(ogva.tipo_pratica,'A',ogva.anno,p_anno - 1)
                                         <> p_anno
   and decode(ogva.tipo_pratica,'A',ogva.flag_denuncia,'S')
                                          = 'S'
   and nvl(ogva.stato_accertamento,'D')   = 'D'
   and nvl(ogpr.flag_contenzioso,'N') <> 'S'
   and F_CONCESSIONE_ATTIVA(ogva.cod_fiscale,p_tipo_trib,p_anno
                           ,ogva.pratica,null,null
                           )              = 'SI'
   and (    ogva.tipo_occupazione||''     = 'T'
        or  ogva.tipo_occupazione||''     = 'P'
        and not exists
           (select 1
              from oggetti_validita ogv2
             where ogv2.cod_fiscale       = ogva.cod_fiscale
               and ogv2.tipo_tributo||''  = ogva.tipo_tributo
               and ogv2.oggetto_pratica_rif
                                          = ogva.oggetto_pratica_rif
               and decode(ogv2.tipo_pratica,'A',ogv2.anno,p_anno - 1)
                                         <> p_anno
               and decode(ogv2.tipo_pratica,'A',ogv2.flag_denuncia,'S')
                                          = 'S'
               and nvl(ogv2.stato_accertamento,'D')
                                          = 'D'
               and nvl(to_number(to_char(ogv2.dal,'yyyy')),0)
                                         <= p_anno
               and nvl(to_number(to_char(ogv2.al ,'yyyy')),9999)
                                         >= p_anno
               and (    nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          >
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                          >
                        nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                    or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                    and ogv2.pratica      > ogva.pratica
                   )
           )
       )
   and not exists
       (select 1
          from pratiche_tributo prt2
         where prt2.tipo_tributo          = p_tipo_trib
           and prt2.anno                  = p_anno
           and prt2.cod_fiscale           = ogva.cod_fiscale
           and prt2.tipo_pratica          = 'A'
           and nvl(prt2.stato_accertamento,'D')
                                          = 'D'
           and (   prt2.data_notifica    is not null
                or prt2.numero           is not null
               )
       )
 order by ogva.cod_fiscale
;
-- Determinazione delle Scadenze delle Rate per Anno e Tipo Tributo.
cursor sel_scad (p_tipo_tributo in varchar2
               , p_anno in number) is
select scad.data_scadenza
      ,scad.rata
  from scadenze scad
 where scad.tipo_tributo  = p_tipo_tributo
   and scad.anno          = p_anno
   and scad.rata         is not null
   and scad.tipo_scadenza = 'V'
;
--
-- Determinazione dei Versamenti.
--
cursor sel_vers (p_cod_fiscale in varchar2
               , p_tipo_tributo in varchar2
               , p_anno        in number
               , p_scadenza_r1 in date
               , p_scadenza_r2  in date
               , p_scadenza_r3 in date
               , p_scadenza_r4  in date
                ) is
select decode(p_scadenza_r1
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,0,vers.importo_versato
                         ,1,vers.importo_versato
                           ,0
                         )
             ) versato_r1
      ,decode(p_scadenza_r1
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,0,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                         ,1,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r1
      ,decode(p_scadenza_r2
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,2,vers.importo_versato
                           ,0
                         )
             ) versato_r2
      ,decode(p_scadenza_r2
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,2,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r2
      ,decode(p_scadenza_r3
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,3,vers.importo_versato
                           ,0
                         )
             ) versato_r3
      ,decode(p_scadenza_r3
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,3,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r3
      ,decode(p_scadenza_r4
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,4,vers.importo_versato
                           ,0
                         )
             ) versato_r4
      ,decode(p_scadenza_r4
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,4,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r4
      ,vers.importo_versato versato
      ,vers.data_pagamento
  from versamenti                         vers
     -- ,pratiche_tributo                   prtr
 where vers.cod_fiscale                      = p_cod_fiscale
   and vers.tipo_tributo                     = p_tipo_tributo
   and vers.anno                             = p_anno
   and (vers.pratica is null or
       (vers.pratica is not null
        /*and exists (select 'x' from pratiche_tributo prtr
                 where prtr.pratica                    = vers.pratica
                   and (    nvl(prtr.tipo_pratica,'D') = 'D'
                        or  nvl(prtr.tipo_pratica,'D') = 'A'
                        and nvl(prtr.anno,p_anno - 1)  <> p_anno
                       )
               )*/
        and exists (select 'x'
                      from pratiche_tributo prtr
                         , oggetti_pratica  ogpr
                     where prtr.pratica          = vers.pratica
                       and prtr.tipo_pratica     = 'D'
                       and prtr.anno             = p_anno
                       and prtr.pratica          = ogpr.pratica
                       and ogpr.tipo_occupazione = 'P'
                   )
        and F_CONCESSIONE_ATTIVA(p_cod_fiscale,p_tipo_tributo,p_anno
                                ,vers.pratica,null,vers.oggetto_imposta
                                )                 = 'SI'
       )
       )
;
PROCEDURE SISTEMA_ECCEDENZE (p_importo   in     number
                              ,p_stringa_1 in out varchar2
                              ,p_stringa_2 in out varchar2
                              )
IS
w_importo                  number;
w_stringa_1                varchar2(2300);
w_stringa_2                varchar2(2300);
w_imp_confronto            number;
w_ind                      number;
w_ind_2                    number;
BEGIN
   w_importo         := p_importo;
   w_stringa_1       := p_stringa_1;
   w_stringa_2       := p_stringa_2;
   w_ind             := nvl(length(w_stringa_1),0) / 23;
   w_imp_confronto   := 0;
   if w_importo > 0 then
      loop
         if w_ind = 0 then
            exit;
         end if;
--
-- Caso di raggiungimento del valore; la parte di valore si riporta
-- nella stringa 2 e si aggiorna la stringa 1 con la quota
-- rimasta dopo avere sottratto la quota spostata nella stringa 2.
--
         if w_imp_confronto + to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100
                            > w_importo then
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2 := w_stringa_2||
                                 substr(w_stringa_1,w_ind * 23 - 22,8)||
                                 lpad(to_char((w_importo - w_imp_confronto) * 100),15,'0');
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) -
                                 to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15))),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 - 22,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2 := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15)) +
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) -
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         else
--
-- Caso di Importo non raggiunto: tutta la quota della stringa 1 va
-- nella stringa 2 e si incrementa il valore di confronto per
-- il raggiungimento del valore  (w_imp_confronto).
--
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2     := w_stringa_2||
                                     substr(w_stringa_1,w_ind * 23 - 22,23);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 - 22,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2     := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                     substr(w_stringa_1,w_ind * 23 - 14,15)||
                                     substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         end if;
--
-- Si continua a scorrere a ritroso la stringa dei versamenti.
--
         w_ind := w_ind - 1;
      end loop;
   end if;
   p_stringa_1 := w_stringa_1;
   p_stringa_2 := w_stringa_2;
END SISTEMA_ECCEDENZE;
PROCEDURE COMPENSA_ECCEDENZE (p_a         in     number
                             ,p_da        in     number
                             ,p_importo   in     number
                             ,p_stringa_1 in out varchar2
                             ,p_stringa_2 in out varchar2
                             )
--p_a, p_da MAI UTILIZZATI
IS
w_importo                  number;
w_stringa_1                varchar2(2300);
w_stringa_2                varchar2(2300);
w_imp_confronto            number;
w_ind                      number;
w_ind_2                    number;
BEGIN
   w_importo         := p_importo;
   w_stringa_1       := p_stringa_1;
   w_stringa_2       := p_stringa_2;
   w_ind             := 0;
   w_imp_confronto   := 0;
   if w_importo > 0 then
      loop
         if w_ind = nvl(length(w_stringa_1),0) / 23 then
            exit;
         end if;
--
-- Caso di raggiungimento del valore; la parte di valore si riporta
-- nella stringa 2 e si aggiorna la stringa 1 con la quota
-- rimasta dopo avere sottratto la quota spostata nella stringa 2.
--
         if w_imp_confronto + to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100
                            > w_importo then
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2 := w_stringa_2||
                                 substr(w_stringa_1,w_ind * 23 + 1,8)||
                                 lpad(to_char((w_importo - w_imp_confronto) * 100),15,'0');
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) -
                                 to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15))),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 + 1,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2 := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15)) +
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) -
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         else
--
-- Caso di Importo non raggiunto: tutta la quota della stringa 1 va
-- nella stringa 2 e si incrementa il valore di confronto per
-- il raggiungimento del valore  (w_imp_confronto).
--
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2     := w_stringa_2||
                                     substr(w_stringa_1,w_ind * 23 + 1,23);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 + 1,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2     := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                     substr(w_stringa_1,w_ind * 23 + 9,15)||
                                     substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         end if;
--
-- Si continua a scorrere la stringa dei versamenti.
--
         w_ind := w_ind + 1;
      end loop;
   end if;
   p_stringa_1 := w_stringa_1;
   p_stringa_2 := w_stringa_2;
END COMPENSA_ECCEDENZE;
PROCEDURE BONIFICA_STRINGA (p_stringa in out varchar2)
IS
w_stringa                 varchar2(2300);
w_stringa_2               varchar2(2300);
w_elem_stringa            varchar2(23);
w_ind                     number;
--w_ind_2                   number;
BEGIN
   w_stringa := p_stringa;
--
-- Si tolgono gli elementi che non hanno importo.
--
   w_stringa_2 := '';
   w_ind := 0;
   loop
      if nvl(length(w_stringa),0) < w_ind * 23 + 1 then
         exit;
      end if;
      w_elem_stringa := substr(w_stringa,w_ind * 23 + 1,23);
      if substr(w_elem_stringa,9,15) <> '000000000000000' then
         w_stringa_2 := w_stringa_2||w_elem_stringa;
      end if;
      w_ind := w_ind + 1;
   end loop;
   w_stringa := w_stringa_2;
   p_stringa := w_stringa;
END BONIFICA_STRINGA;
--
-- CALCOLO_ACC_CONCESSIONI
--
BEGIN
   w_cf := '';
   w_scad_r1  := to_date('31122999','ddmmyyyy');
   w_scad_r2  := to_date('31122999','ddmmyyyy');
   w_scad_r3  := to_date('31122999','ddmmyyyy');
   w_scad_r4  := to_date('31122999','ddmmyyyy');
   w_tot_rate := 0;
   for rec_scad in sel_scad (a_tipo_tributo,a_anno)
   loop
      w_tot_rate := w_tot_rate + 1;
      if    rec_scad.rata = 1 then
         w_scad_r1 := rec_scad.data_scadenza;
      elsif rec_scad.rata = 2 then
         w_scad_r2 := rec_scad.data_scadenza;
      elsif rec_scad.rata = 3 then
         w_scad_r3 := rec_scad.data_scadenza;
      elsif rec_scad.rata = 4 then
         w_scad_r4 := rec_scad.data_scadenza;
      end if;
   end loop;
   open sel_acc (a_tipo_tributo
               , a_anno
               , a_cod_fiscale
               , a_cognome_nome);
   fetch sel_acc into w_cod_fiscale
                    , w_oggetto_pratica
                    , w_oggetto_pratica_rif
                    , w_oggetto
                    , w_pratica
                    , w_data_pratica
                    , w_numero_pratica
                    , w_anno
                    , w_tipo_pratica
                    , w_tipo_evento
                    , w_tipo_occupazione
                    , w_dal
                    , w_al
                    , w_data_concessione
   ;
   if sel_acc%FOUND then
      w_cod_fiscale_prec := w_cod_fiscale;
      w_data_concessione_prec := w_data_concessione;
      w_imposta_r1 := 0;
      w_imposta_r2 := 0;
      w_imposta_r3 := 0;
      w_imposta_r4 := 0;
      w_imposta_rt := 0;
      w_imposta    := 0;
      loop
         w_cf := w_cod_fiscale;
--
-- Per esigenze di stampa dei bollettini, si e` operato sul calcolo imposta
-- distinguendo le pratiche dell`anno di imposta che si pagano al momento della
-- dichiarazione. Se l`imposta viene determinata senza rateizzazione non cambia
-- niente rispetto a prima; se invece si desidera rateizzare, allora per le pratiche
-- dell`anno di imposta la rateizzazione e` solo per utenza, mentre per le pratiche
-- relative agli anni precedenti la rateizzazione puo` essere anche per contribuente.
-- In questa sede si fanno dei controlli sulla data di presentazione della denuncia
-- soltanto per le pratiche dell`anno. Come si e` detto prima, queste pratiche sono
-- eventualmente rateizzate solo per utenza (rate con oggetto imposta); per evitare
-- di ripetere successivamente gli stessi controlli, le imposte e la rateizzazione su
-- utenza sono determinate ora sulla base dell`oggetto imposta. Le restanti rateizzazioni
-- eventuali da sommare saranno tutte quelle senza oggetto imposta che, come si e` gia`
-- detto, provengono da rateizzazione per contribuente che pero` e` possibile solo per
-- pratiche di anni precedenti sulle quali non c`e` il controllo di data di presentazione
-- scaduta e quindi sono da considerarsi tutte valide. Vengono trattate a cambio contribuente.
-- Quando si sono trattate tutte le imposte e tutte le rateizzazioni, puo` verificarsi
-- che i totali non tornino. I casi sono due: o non c`e` stata rateizzazione, o non c`e`
-- stata parziale rateizzazione (perche` si e` operato volutamente in questo modo o
-- perche` non e` stato raggiunto il limite per la rateizzazione). La differenza
-- va gestita sulla scadenza della prima rata (o della rata 0 in assenza di rate vere).
--
         BEGIN
            select nvl(max(nvl(ogim.imposta,0)),0)
                  ,nvl(sum(decode(nvl(raim.rata,0),0,nvl(raim.imposta,0)
                                                  ,1,nvl(raim.imposta,0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),2,nvl(raim.imposta,0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),3,nvl(raim.imposta,0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),4,nvl(raim.imposta,0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(nvl(raim.imposta,0)),0)
              into w_dep
                  ,w_dep_r1
                  ,w_dep_r2
                  ,w_dep_r3
                  ,w_dep_r4
                  ,w_dep_rt
              from oggetti_imposta       ogim
                  ,rate_imposta          raim
                  ,oggetti_pratica       ogpr
                  ,pratiche_tributo      prtr
             where ogim.oggetto_pratica     = w_oggetto_pratica
               and ogpr.oggetto_pratica     = w_oggetto_pratica
               and prtr.pratica             = ogpr.pratica
               and prtr.tipo_tributo||''    = a_tipo_tributo
               and ogim.anno                = a_anno
               and raim.oggetto_imposta (+) = ogim.oggetto_imposta
               and substr(nvl(prtr.utente,'?'),1,1)
                                           <> '#'
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_dep    := 0;
               w_dep_r1 := 0;
               w_dep_r2 := 0;
               w_dep_r3 := 0;
               w_dep_r4 := 0;
               w_dep_rt := 0;
         END;
         w_imposta    := w_imposta    + w_dep;
         w_imposta_r1 := w_imposta_r1 + w_dep_r1;
         w_imposta_r2 := w_imposta_r2 + w_dep_r2;
         w_imposta_r3 := w_imposta_r3 + w_dep_r3;
         w_imposta_r4 := w_imposta_r4 + w_dep_r4;
         w_imposta_rt := w_imposta_rt + w_dep_rt;
         fetch sel_acc into w_cod_fiscale,w_oggetto_pratica,w_oggetto_pratica_rif
                           ,w_oggetto,w_pratica,w_data_pratica,w_numero_pratica
                           ,w_anno,w_tipo_pratica,w_tipo_evento,w_tipo_occupazione
                           ,w_dal,w_al,w_data_concessione
         ;
         if sel_acc%NOTFOUND
         or w_cod_fiscale <> w_cod_fiscale_prec then
            w_scadenza_r1 := w_scad_r1;
            w_scadenza_r2 := w_scad_r2;
            w_scadenza_r3 := w_scad_r3;
            w_scadenza_r4 := w_scad_r4;
--
-- Sostituzione della data di concessione al posto della prima rata.
--
            w_cf := w_cod_fiscale_prec;
            BEGIN
               select min(raim.rata)
                     ,count(*)
                 into w_min_rata
                     ,w_tot_rate
                 from rate_imposta    raim
                where raim.cod_fiscale        = w_cod_fiscale_prec
                  and raim.anno               = a_anno
                  and raim.tipo_tributo       = a_tipo_tributo
                  and F_CONCESSIONE_ATTIVA(w_cod_fiscale_prec,a_tipo_tributo,a_anno
                                          ,null,null,raim.oggetto_imposta
                                          )   = 'SI'
               ;
            END;
            if w_tot_rate = 0 then
               w_tot_rate := 1;
               w_min_rata := 1;
            end if;
            if    w_min_rata = 1 then
                  w_scadenza_r1 := w_data_concessione_prec;
            elsif w_min_rata = 2 then
                  w_scadenza_r2 := w_data_concessione_prec;
            elsif w_min_rata = 3 then
                  w_scadenza_r3 := w_data_concessione_prec;
            elsif w_min_rata = 4 then
                  w_scadenza_r4 := w_data_concessione_prec;
            end if;
--
-- Si gestiscono le rate imposta rateizzate per contribuente.
--
            BEGIN
               select nvl(sum(decode(raim.rata,0,raim.imposta
                                              ,1,raim.imposta
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,2,raim.imposta
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,3,raim.imposta
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,4,raim.imposta
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(raim.imposta),0)
                 into w_dep_r1
                     ,w_dep_r2
                     ,w_dep_r3
                     ,w_dep_r4
                     ,w_dep_rt
                 from rate_imposta    raim
                where raim.cod_fiscale        = w_cod_fiscale_prec
                  and raim.anno               = a_anno
                  and raim.tipo_tributo       = a_tipo_tributo
                  and F_CONCESSIONE_ATTIVA(w_cod_fiscale_prec,a_tipo_tributo,a_anno
                                          ,null,null,raim.oggetto_imposta
                                          )   = 'SI'
                  and raim.oggetto_imposta   is null
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_dep_r1 := 0;
                  w_dep_r2 := 0;
                  w_dep_r3 := 0;
                  w_dep_r4 := 0;
                  w_dep_rt := 0;
            END;
            w_imposta_r1 := w_imposta_r1 + w_dep_r1;
            w_imposta_r2 := w_imposta_r2 + w_dep_r2;
            w_imposta_r3 := w_imposta_r3 + w_dep_r3;
            w_imposta_r4 := w_imposta_r4 + w_dep_r4;
            w_imposta_rt := w_imposta_rt + w_dep_rt;
--
-- Eventuali differenze tra il totale imposta di oggetti imposta) e
-- il totale imposta di rate imposta e` imputabile a utenze che non sono
-- state soggette a rateizzazione per cui detta differenza va
-- ad incrementarsi sulla prima rata.
--
            if w_imposta > w_imposta_rt then
               w_imposta_r1 := w_imposta - w_imposta_rt + w_imposta_r1;
            end if;
--
            w_versato_r1         := 0;
            w_versato_r1_da_r2   := 0;
            w_versato_r1_da_r3   := 0;
            w_versato_r1_da_r4   := 0;
            w_versato_r2         := 0;
            w_versato_r2_da_r1   := 0;
            w_versato_r2_da_r3   := 0;
            w_versato_r2_da_r4   := 0;
            w_versato_r3         := 0;
            w_versato_r3_da_r1   := 0;
            w_versato_r3_da_r2   := 0;
            w_versato_r3_da_r4   := 0;
            w_versato_r4         := 0;
            w_versato_r4_da_r1   := 0;
            w_versato_r4_da_r2   := 0;
            w_versato_r4_da_r3   := 0;
            w_tot_versato        := 0;
            w_tot_versato_r1     := 0;
            w_tot_versato_r2     := 0;
            w_tot_versato_r3     := 0;
            w_tot_versato_r4     := 0;
            w_data_versamento_r1 := to_date('31122999','ddmmyyyy');
            w_data_versamento_r2 := to_date('31122999','ddmmyyyy');
            w_data_versamento_r3 := to_date('31122999','ddmmyyyy');
            w_data_versamento_r4 := to_date('31122999','ddmmyyyy');
            w_omesso_r1          := 0;
            w_omesso_r2          := 0;
            w_omesso_r3          := 0;
            w_omesso_r4          := 0;
            w_eccedenza_r1       := 0;
            w_eccedenza_r2       := 0;
            w_eccedenza_r3       := 0;
            w_eccedenza_r4       := 0;
            w_ins_pratica        := 'NO';
--
-- Totalizzazione del Versato del Contribuente e determinazione del Tardivo.
--
            for rec_vers in sel_vers (w_cod_fiscale_prec,a_tipo_tributo,a_anno
                                     ,w_scadenza_r1,w_scadenza_r2
                                     ,w_scadenza_r3,w_scadenza_r4
                                     )
            loop
               w_tot_versato        := w_tot_versato + nvl(rec_vers.versato,0);
               w_tot_versato_r1     := w_tot_versato_r1                +
                                       nvl(rec_vers.versato_r1,0);
               if  rec_vers.data_pagamento_r1 < w_data_versamento_r1 then
                  w_data_versamento_r1 := rec_vers.data_pagamento_r1;
               end if;
               w_tot_versato_r2     := w_tot_versato_r2                +
                                       nvl(rec_vers.versato_r2,0);
               if  rec_vers.data_pagamento_r2 < w_data_versamento_r2 then
                  w_data_versamento_r2 := rec_vers.data_pagamento_r2;
               end if;
               w_tot_versato_r3     := w_tot_versato_r3                +
                                       nvl(rec_vers.versato_r3,0);
               if  rec_vers.data_pagamento_r3 < w_data_versamento_r3 then
                  w_data_versamento_r3 := rec_vers.data_pagamento_r3;
               end if;
               w_tot_versato_r4     := w_tot_versato_r4                +
                                       nvl(rec_vers.versato_r4,0);
               if  rec_vers.data_pagamento_r4 < w_data_versamento_r4 then
                  w_data_versamento_r4 := rec_vers.data_pagamento_r4;
               end if;
--
-- Si compongono le stringe dei versamenti per le 4 rate in cui vengono memorizzati tanti
-- elementi a lunghezza fissa con data (ggmmyyyy) e importo in centesimi di 15 chr (tot=23).
-- Per data uguale si totalizzano gli importi relativi.
--
               if  rec_vers.data_pagamento_r1 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r1),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r1 := w_stringa_vers_r1
                                           || to_char(rec_vers.data_pagamento_r1,'ddmmyyyy')
                                           || lpad(to_char(nvl(rec_vers.versato_r1,0) * 100),15,'0');
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r1,'ddmmyyyy') =
                         substr(w_stringa_vers_r1,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r1 :=
                            substr(w_stringa_vers_r1,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r1,w_ind_stringa * 23 + 9,15)) / 100 +
                                                        nvl(rec_vers.versato_r1,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r1,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
               if  rec_vers.data_pagamento_r2 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r2),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r2 := w_stringa_vers_r2
                                           || to_char(rec_vers.data_pagamento_r2,'ddmmyyyy')
                                           || lpad(to_char(nvl(rec_vers.versato_r2,0) * 100),15,'0');
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r2,'ddmmyyyy') =
                         substr(w_stringa_vers_r2,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r2 :=
                            substr(w_stringa_vers_r2,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r2,w_ind_stringa * 23 + 9,15)) / 100 +
                                                        nvl(rec_vers.versato_r2,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r2,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
               if  rec_vers.data_pagamento_r3 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r3),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r3 := w_stringa_vers_r3
                                           || to_char(rec_vers.data_pagamento_r3,'ddmmyyyy')
                                           || lpad(to_char(nvl(rec_vers.versato_r3,0) * 100),15,'0');
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r3,'ddmmyyyy') =
                         substr(w_stringa_vers_r3,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r3 :=
                            substr(w_stringa_vers_r3,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r3,w_ind_stringa * 23 + 9,15)) / 100 +
                                                        nvl(rec_vers.versato_r3,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r3,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
               if  rec_vers.data_pagamento_r4 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r4),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r4 := w_stringa_vers_r4
                                           || to_char(rec_vers.data_pagamento_r4,'ddmmyyyy')
                                           || lpad(to_char(nvl(rec_vers.versato_r4,0) * 100),15,'0');
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r4,'ddmmyyyy') =
                         substr(w_stringa_vers_r4,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r4 :=
                            substr(w_stringa_vers_r4,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r4,w_ind_stringa * 23 + 9,15)) / 100 +
                                                        nvl(rec_vers.versato_r4,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r4,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
            end loop;
--
-- Determinazione del Numero di Scadenze.
--
            w_tot := 1;
            if  w_scadenza_r2 <> to_date('31122999','ddmmyyyy')
            and w_scadenza_r3  = to_date('31122999','ddmmyyyy')
            and w_scadenza_r4  = to_date('31122999','ddmmyyyy') then
                w_tot := 2;
            end if;
            if  w_scadenza_r3 <> to_date('31122999','ddmmyyyy')
            and w_scadenza_r4  = to_date('31122999','ddmmyyyy') then
                w_tot := 3;
            end if;
            if  w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
                w_tot := 4;
            end if;
--
-- Determinazione di Eccedenze di Versamento e del Versato non in eccedenza.
-- Per la gestione delle stringhe dei versamenti e delle eccedenze viene richiamata
-- la procedura relativa.
--
            if w_scadenza_r1 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r1 > w_imposta_r1 then
                  w_eccedenza_r1 := w_tot_versato_r1 - w_imposta_r1;
                  w_versato_r1   := w_imposta_r1;
               else
                  w_versato_r1   := w_tot_versato_r1;
               end if;
            end if;
--
            SISTEMA_ECCEDENZE(w_eccedenza_r1,w_stringa_vers_r1,w_stringa_eccedenze_r1);
--
            if w_scadenza_r2 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r2 > w_imposta_r2 then
                  w_eccedenza_r2 := w_tot_versato_r2 - w_imposta_r2;
                  w_versato_r2   := w_imposta_r2;
               else
                  w_versato_r2   := w_tot_versato_r2;
               end if;
            end if;
--
            SISTEMA_ECCEDENZE(w_eccedenza_r2,w_stringa_vers_r2,w_stringa_eccedenze_r2);
--
            if w_scadenza_r3 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r3 > w_imposta_r3 then
                  w_eccedenza_r3 := w_tot_versato_r3 - w_imposta_r3;
                  w_versato_r3   := w_imposta_r3;
               else
                  w_versato_r3   := w_tot_versato_r3;
               end if;
            end if;
--
            SISTEMA_ECCEDENZE(w_eccedenza_r3,w_stringa_vers_r3,w_stringa_eccedenze_r3);
--
            if w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r4 > w_imposta_r4 then
                  w_eccedenza_r4 := w_tot_versato_r4 - w_imposta_r4;
                  w_versato_r4   := w_imposta_r4;
               else
                  w_versato_r4   := w_tot_versato_r4;
               end if;
            end if;
--
            SISTEMA_ECCEDENZE(w_eccedenza_r4,w_stringa_vers_r4,w_stringa_eccedenze_r4);
--
--
-- Determinazione delle Compensazioni tra Rate.
-- Per la gestione delle stringhe dei versamenti e delle eccedenze viene richiamata
-- la procedura relativa.
--
            if w_scadenza_r1 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r1 < w_imposta_r1 then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r1_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r1 - w_versato_r1
                                                );
--
                     COMPENSA_ECCEDENZE(1,2,w_versato_r1_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r1);
--
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r1_da_r2;
                  end if;
               end if;
               if w_versato_r1 < (w_imposta_r1 + w_versato_r1_da_r2) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r1_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r1 - w_versato_r1
                                                              - w_versato_r1_da_r2
                                                );
--
                     COMPENSA_ECCEDENZE(1,3,w_versato_r1_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r1);
--
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r1_da_r3;
                  end if;
               end if;
               if w_versato_r1 < (w_imposta_r1 + w_versato_r1_da_r2
                                               + w_versato_r1_da_r3) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r1_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r1 - w_versato_r1
                                                              - w_versato_r1_da_r2
                                                              - w_versato_r1_da_r3
                                                );
--
                     COMPENSA_ECCEDENZE(1,4,w_versato_r1_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r1);
--
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r1_da_r4;
                  end if;
               end if;
            end if;
--
            if w_scadenza_r2 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r2 < w_imposta_r2 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r2_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r2 - w_versato_r2
                                                );
--
                     COMPENSA_ECCEDENZE(2,1,w_versato_r2_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r2);
--
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r2_da_r1;
                  end if;
               end if;
               if w_versato_r2 < (w_imposta_r2 + w_versato_r2_da_r1) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r2_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r2 - w_versato_r2
                                                              - w_versato_r2_da_r1
                                                );
--
                     COMPENSA_ECCEDENZE(2,3,w_versato_r2_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r2);
--
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r2_da_r3;
                  end if;
               end if;
               if w_versato_r2 < (w_imposta_r2 + w_versato_r2_da_r1
                                               + w_versato_r2_da_r3) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r2_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r2 - w_versato_r2
                                                              - w_versato_r2_da_r1
                                                              - w_versato_r2_da_r3
                                                );
--
                     COMPENSA_ECCEDENZE(2,4,w_versato_r2_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r2);
--
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r2_da_r4;
                  end if;
               end if;
            end if;
--
            if w_scadenza_r3 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r3 < w_imposta_r3 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r3_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r3 - w_versato_r3
                                                );
--
                     COMPENSA_ECCEDENZE(3,1,w_versato_r3_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r3);
--
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r3_da_r1;
                  end if;
               end if;
               if w_versato_r3 < (w_imposta_r3 + w_versato_r3_da_r1) then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r3_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r3 - w_versato_r3
                                                              - w_versato_r3_da_r1
                                                );
--
                     COMPENSA_ECCEDENZE(3,2,w_versato_r3_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r3);
--
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r3_da_r2;
                  end if;
               end if;
               if w_versato_r3 < (w_imposta_r3 + w_versato_r3_da_r1
                                               + w_versato_r3_da_r2) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r3_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r3 - w_versato_r3
                                                              - w_versato_r3_da_r1
                                                              - w_versato_r3_da_r2
                                                );
--
                     COMPENSA_ECCEDENZE(3,4,w_versato_r3_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r3);
--
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r3_da_r4;
                  end if;
               end if;
            end if;
--
            if w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r4 < w_imposta_r4 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r4_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r4 - w_versato_r4
                                                );
--
                     COMPENSA_ECCEDENZE(4,1,w_versato_r4_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r4);
--
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r4_da_r1;
                  end if;
               end if;
               if w_versato_r4 < (w_imposta_r4 + w_versato_r4_da_r1) then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r4_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r4 - w_versato_r4
                                                              - w_versato_r4_da_r1
                                                );
--
                     COMPENSA_ECCEDENZE(4,2,w_versato_r4_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r4);
--
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r4_da_r2;
                  end if;
               end if;
               if w_versato_r4 < (w_imposta_r4 + w_versato_r4_da_r1
                                               + w_versato_r4_da_r2) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r4_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r4 - w_versato_r4
                                                              - w_versato_r4_da_r1
                                                              - w_versato_r4_da_r2
                                                );
--
                     COMPENSA_ECCEDENZE(4,3,w_versato_r4_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r4);
--
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r4_da_r3;
                  end if;
               end if;
            end if;
--
-- Determinazione dell`omesso.
--
            if w_imposta_r1 > (w_versato_r1 + w_versato_r1_da_r2
                                            + w_versato_r1_da_r3
                                            + w_versato_r1_da_r4
                              ) then
               w_omesso_r1 := w_imposta_r1 - w_versato_r1
                                           - w_versato_r1_da_r2
                                           - w_versato_r1_da_r3
                                           - w_versato_r1_da_r4;
            end if;
            if w_imposta_r2 > (w_versato_r2 + w_versato_r2_da_r1
                                            + w_versato_r2_da_r3
                                            + w_versato_r2_da_r4
                              ) then
               w_omesso_r2 := w_imposta_r2 - w_versato_r2
                                           - w_versato_r2_da_r1
                                           - w_versato_r2_da_r3
                                           - w_versato_r2_da_r4;
            end if;
            if w_imposta_r3 > (w_versato_r3 + w_versato_r3_da_r1
                                            + w_versato_r3_da_r2
                                            + w_versato_r3_da_r4
                              ) then
               w_omesso_r3 := w_imposta_r3 - w_versato_r3
                                           - w_versato_r3_da_r1
                                           - w_versato_r3_da_r2
                                           - w_versato_r3_da_r4;
            end if;
            if w_imposta_r4 > (w_versato_r4 + w_versato_r4_da_r1
                                            + w_versato_r4_da_r2
                                            + w_versato_r4_da_r3
                              ) then
               w_omesso_r4 := w_imposta_r4 - w_versato_r4
                                           - w_versato_r4_da_r1
                                           - w_versato_r4_da_r2
                                           - w_versato_r4_da_r3;
            end if;
--
-- Si tolgono dalle stringhe gli elementi che hanno importo a zero.
--
            BONIFICA_STRINGA(w_stringa_vers_r1);
            BONIFICA_STRINGA(w_stringa_vers_r2);
            BONIFICA_STRINGA(w_stringa_vers_r3);
            BONIFICA_STRINGA(w_stringa_vers_r4);
            BONIFICA_STRINGA(w_stringa_eccedenze_r1);
            BONIFICA_STRINGA(w_stringa_eccedenze_r2);
            BONIFICA_STRINGA(w_stringa_eccedenze_r3);
            BONIFICA_STRINGA(w_stringa_eccedenze_r4);
--dbms_output.put_line('CONCESSIONI');
--dbms_output.put_line('1^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r1,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r1)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r1,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r1)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r1)||
--                     ' da rata2 '||to_char(w_versato_r1_da_r2)||
--                     ' da rata3 '||to_char(w_versato_r1_da_r3)||
--                     ' da rata4 '||to_char(w_versato_r1_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r1)||
--                     ' Eccedenza '||to_char(w_eccedenza_r1)
--                    );
--dbms_output.put_line(substr('Stringa Versamenti '||w_stringa_vers_r1,1,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r1,1,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r1,256,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r1,511,255));
--dbms_output.put_line('2^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r2,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r2)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r2,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r2)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r2)||
--                     ' da rata1 '||to_char(w_versato_r2_da_r1)||
--                     ' da rata3 '||to_char(w_versato_r2_da_r3)||
--                     ' da rata4 '||to_char(w_versato_r2_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r2)||
--                     ' Eccedenza '||to_char(w_eccedenza_r2)
--                    );
--dbms_output.put_line(substr('Stringa Versamenti '||w_stringa_vers_r2,1,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r2,1,255));
--dbms_output.put_line('3^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r3,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r3)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r3,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r3)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r3)||
--                     ' da rata1 '||to_char(w_versato_r3_da_r1)||
--                     ' da rata2 '||to_char(w_versato_r3_da_r2)||
--                     ' da rata4 '||to_char(w_versato_r3_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r3)||
--                     ' Eccedenza '||to_char(w_eccedenza_r3)
--                    );
--dbms_output.put_line(substr('Stringa Versamenti '||w_stringa_vers_r3,1,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r3,1,255));
--dbms_output.put_line('4^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r4,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r4)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r4,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r4)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r4)||
--                     ' da rata1 '||to_char(w_versato_r4_da_r1)||
--                     ' da rata2 '||to_char(w_versato_r4_da_r2)||
--                     ' da rata3 '||to_char(w_versato_r4_da_r3)||
--                     ' Omesso '||to_char(w_omesso_r4)||
--                     ' Eccedenza '||to_char(w_eccedenza_r4)
--                    );
--dbms_output.put_line(substr('Stringa Versamenti '||w_stringa_vers_r4,1,255));
--dbms_output.put_line(substr('Stringa Eccedenze '||w_stringa_eccedenze_r4,1,255));
            CALCOLO_ACC_SANZIONI(w_cod_fiscale_prec
                               , a_tipo_tributo
                               , a_anno
                               , a_utente
                               , w_imposta_r1
                               , w_scadenza_r1
                               , w_stringa_vers_r1
                               , w_stringa_eccedenze_r1
                               , w_imposta_r2
                               , w_scadenza_r2
                               , w_stringa_vers_r2
                               , w_stringa_eccedenze_r2
                               , w_imposta_r3
                               , w_scadenza_r3
                               , w_stringa_vers_r3
                               , w_stringa_eccedenze_r3
                               , w_imposta_r4
                               , w_scadenza_r4
                               , w_stringa_vers_r4
                               , w_stringa_eccedenze_r4
                               , 'SI'
                                );
         end if;
         if sel_acc%NOTFOUND then
            exit;
         elsif w_cod_fiscale_prec <> w_cod_fiscale then
            w_cod_fiscale_prec := w_cod_fiscale;
            w_data_concessione_prec := w_data_concessione;
            w_imposta_r1 := 0;
            w_imposta_r2 := 0;
            w_imposta_r3 := 0;
            w_imposta_r4 := 0;
            w_imposta    := 0;
         end if;
      end loop;
   end if;
   close sel_acc;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'CF = '||w_cf||' Conc. '||w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Calcolo Automatico Concessioni di '||w_cf||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACC_CONCESSIONI */
/

