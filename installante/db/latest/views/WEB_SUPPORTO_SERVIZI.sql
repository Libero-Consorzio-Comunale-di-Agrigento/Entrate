--liquibase formatted sql 
--changeset abrandolini:20250326_152401_WEB_SUPPORTO_SERVIZI stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW WEB_SUPPORTO_SERVIZI
AS
select b.*,paut.utente utente_paut,a.anno anno_ord, a.tipo_tributo tipo_tributo_ord, a.differenza_imposta differenza_imposta_ord, a.cod_fiscale cod_fiscale_ord
  from parametri_utente paut,supporto_servizi a, supporto_servizi b
 where b.cod_fiscale  = a.cod_fiscale
   and b.cognome_nome = a.cognome_nome
   and b.tipo_tributo = a.tipo_tributo
   and b.anno between substr(paut.valore,1,4) and substr(paut.valore,6,4)
   and paut.tipo_parametro = 'SUPPORTO_SERVIZI'
   and (a.anno, a.cod_fiscale, a.tipo_tributo) in (select min(c.anno), c.cod_fiscale, c.tipo_tributo
                                                     from parametri_utente paub,supporto_servizi c
                                                    where c.cod_fiscale = a.cod_fiscale
                                                      and c.cognome_nome = a.cognome_nome
                                                      and c.anno between substr(paub.valore,1,4) and substr(paub.valore,6,4)
                                                      and paub.tipo_parametro = paut.tipo_parametro
                                                      and paub.utente = paut.utente
                                                    group by c.cod_fiscale, c.tipo_tributo);
comment on table WEB_SUPPORTO_SERVIZI is 'web supporto servizi';

