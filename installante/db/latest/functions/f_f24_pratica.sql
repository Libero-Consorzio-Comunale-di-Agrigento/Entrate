--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_pratica stripComments:false runOnChange:true 
 
create or replace function F_F24_PRATICA
/*************************************************************************
 NOME:        F_F24_PRATICA
 DESCRIZIONE: Dato un identificativo operazione proveniente da file
              versamenti F24, la data pagamento, il tipo tributo e il
              codice fiscale del contribuente, restituisce il relativo
              numero di pratica.
 RITORNA:     number              Numero pratica
 NOTE:        Se l'identificativo è vuoto oppure si tratta di un sollecito
              oppure i primi 4 crt sono numerici, restituisce null.
              Se si tratta di un identificativo non emesso da TR4
              (che non inizia per SOLL, LIQ o ACC), il risultato
              è null.
              Se l'identificativo è della lunghezza errata restituisce -1.
              Se l'anno, la pratica o la rata contenuti nell'identificativo
              non sono numerici restituisce -1.
              Se la pratica non esiste oppure non è del contribuente indicato
              oppure del tipo indicato, restituisce:
               -1     se si tratta di pratiche di liquidazione/accertamento/ecc.
               -4     se si tratta di denunca TOSAP/COSAP e ICP.
              Se la pratica esiste, ma la data di pagamento è < della data di
              notifica, restituisce -2.
              Se la pratica esiste, ma la data di notifica è nulla,
              restituisce -3.
              In caso di pratica rateizzata:
              - se la pratica esiste, ma la data di rateazione è > della
                data di versamento, restituisce -5.
              - se la pratica esiste, ma la rata indicata sul versamento
                è superiore al numero di rate indicato, restituisce -6.
              - se esiste gia' un versamento per la stessa pratica e la
                rata indicata, restituisce -7.
              Se vengono superati tutti i controlli, restituisce il numero di
              pratica
              Composizione identificativo operazione:
              Per i ruoli (non gestiti in questa funzione, ma gestiti
              nella funzione F_F24_RUOLO):
              RUOLAAAARRNNNNNNNN
              Per gli insolventi (solleciti):
              SOLLAAAANNYYYYMMDD
              Ravvedimenti
              RAVPAAAANNNNNNNNNN x Pratica
              Liquidazioni e accertamenti:
              LIQPAAAANNNNNNNNNN x Pratica
              ACCPAAAANNNNNNNNNN x Pratica
              ACCTAAAANNNNNNNNNN x Pratica Totale IMU
              ACCAAAAANNNNNNNNNN x Acc. automatici (tipo_evento = 'A')
              ACCUAAAANNNNNNNNNN x Acc. manuali (tipo_evento = 'U')
              dove AAAA è l'anno della pratica e NNNNNNNNNNN è il numero Pratica
              TOSAP/COSAP/ICP su denuncia
              DENPAAAANNNNNNNNNN x Pratica (occupazione permanente)
              DENTAAAANNNNNNNNNN x Pratica (occupazione temporanea)
              Pratiche rateizzate:
              LIQPAAAARRNNNNNNNN x Pratica
              ACCPAAAARRNNNNNNNN x Pratica
              ACCTAAAARRNNNNNNNN x Pratica Totale IMU
              ACCAAAAARRNNNNNNNN x acc automatici (tipo_evento = 'A')
              ACCUAAAARRNNNNNNNN x acc manuali (tipo_evento = 'U')
              dove AAAA è l'anno della pratica, RR è il numero rata,
              NNNNNNNN è il numero pratica (in questo caso è di sole 8 cifre).
 Rev.    Date         Author      Note
 009     17/04/2023   VM          Aggiunti controlli su identificativo operazione
 008     25/09/2018   VD          Aggiunti controlli per pratiche rateizzate,
                                  compreso quello di versamento gia' presente
 007     12/09/2018   VD          Modificata condizione di where su
                                  tipo_evento: ora deve essere uguale a
                                  quello indicato nell'identificativo
                                  operazione.
 006     27/07/2018   VD          Aggiunta gestione pratiche rateizzate.
 005     04/03/2018   VD          Aggiunta gestione identificativo per
                                  denunce TOSAP/COSAP e ICP.
 004     30/01/2015               In ricerca pratica aggiunto controllo
                                  sul tipo tributo
 003     28/01/2015               Aggiunta gestione identificativo per
                                  ravvedimenti e ruolo
 002     18/12/2014   VD          Aggiunti controlli:
                                  data pagamento >= data notifica (se non
                                  superato restituisce -2)
                                  data notifica nulla e data pagamento non
                                  nulla (se non superato restituisce -3)
 001     10/12/2014   VD          Prima emissione.
*************************************************************************/
(p_cod_fiscale        varchar2
,p_id_operazione      varchar2
,p_data_pagamento     date
,p_tipo_tributo       varchar2
)
  return number
is
  w_pratica           number;
  w_tipo_pratica      varchar2(3);
  w_tipo_evento       varchar2(1);
  w_anno              number;
  w_dep_pratica       number;
  w_dep_tipo_pratica  varchar2(1);
  w_dep_rata          number;
  w_data_notifica     date;
  w_tipo_atto         number;
  w_data_rateazione   date;
  w_numero_rate       number;
  w_vers_presenti     number;
begin
--
-- Se l'identificativo operazione è nullo oppure si tratta di un sollecito,
-- si restituisce null
-- Se l'identificativo operazione non inizia per "ACC" o per "LIQ",
-- si restituisce null
--
-- 04/03/2018: Aggiunto test per F24 da denuncia (DEN)
-- 28/01/2015: Aggiunto test per ravvedimento (RAV) e ruolo (RUOL)
-- 16/03/2015: Aggiunto test per pratiche non numeriche. ritorna null.
--
  if p_id_operazione is null or
     p_id_operazione like 'SOLL%' or
     p_id_operazione like 'RUOL%' or
     substr(p_id_operazione,1,3) not in ('ACC','LIQ','RAV','DEN') then
     w_pratica := to_number(null);
  else
     if length(p_id_operazione) < 18 or                           -- id operazione
        afc.is_numeric(substr(p_id_operazione,5,4)) = 0  or       -- anno
        afc.is_numeric(substr(p_id_operazione,11,8)) = 0 or       -- pratica
        afc.is_numeric(substr(p_id_operazione,9,2)) = 0           -- rata
        then
         w_pratica := -1;
     else
         w_tipo_pratica := substr(p_id_operazione,1,3);
         w_tipo_evento  := substr(p_id_operazione,4,1);
         begin
           w_anno         := to_number(substr(p_id_operazione,5,4));
           --
           -- (VD - 27/07/2018): aggiunta gestione pratiche rateizzate.
           --                    il numero di pratica è negli ultimi
           --                    8 caratteri.
           --w_dep_pratica  := to_number(substr(p_id_operazione,9,10));
           w_dep_pratica  := to_number(substr(p_id_operazione,11,8));
           w_dep_rata     := to_number(substr(p_id_operazione,9,2));
           begin
             select pratica
                  , data_notifica
                  , tipo_pratica
                  , tipo_atto
                  , data_rateazione
                  , rate
               into w_pratica
                  , w_data_notifica
                  , w_dep_tipo_pratica
                  , w_tipo_atto
                  , w_data_rateazione
                  , w_numero_rate
               from pratiche_tributo
              where pratica      = w_dep_pratica
                and anno         = w_anno
                and tipo_tributo = p_tipo_tributo
                and cod_fiscale  = p_cod_fiscale
                and tipo_pratica = decode(w_tipo_pratica,'DEN','D',
                                                         'LIQ','L',
                                                         'RAV','V','A')
                and tipo_evento  = decode(w_tipo_evento,'P',tipo_evento,
                                                            w_tipo_evento);
           --                                             'T','U',w_tipo_evento);
           exception
             when others then
               if w_tipo_pratica = 'DEN' then
                  w_pratica := -4;
               else
                  w_pratica := -1;
               end if;
           end;
           if w_pratica > 0 and w_tipo_pratica not in ('DEN','RAV') then
              if nvl(p_data_pagamento,to_date('31/12/9999','dd/mm/yyyy')) <
                 nvl(w_data_notifica,to_date('01/01/1800','dd/mm/yyyy')) then
                 w_pratica := -2;
              elsif w_data_notifica is null and w_dep_tipo_pratica in ('A','I','L')
                and p_data_pagamento is not null then
                 w_pratica := -3;
              end if;
              -- (VD - 25/09/2018): aggiunti controlli relativi alle pratiche
              --                    rateizzate
              if w_tipo_atto = 90 then
                 if nvl(p_data_pagamento,to_date('31/12/9999','dd/mm/yyyy')) <
                    nvl(w_data_rateazione,to_date('01/01/1800','dd/mm/yyyy')) then
                    w_pratica := -5;
                 elsif w_dep_rata < 1 or w_dep_rata > w_numero_rate then
                    w_pratica := -6;
                 end if;
              end if;
           end if;
         exception
           when others then -- invalid number nella assegnazione del numero o anno pratica
             w_pratica := to_number(null);
         end;
     end if;
  end if;
  return w_pratica;
end;
/* End Function: F_F24_PRATICA */
/

