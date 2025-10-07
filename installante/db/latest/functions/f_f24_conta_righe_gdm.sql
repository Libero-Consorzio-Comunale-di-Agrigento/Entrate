--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_conta_righe_gdm stripComments:false runOnChange:true 
 
create or replace function F_F24_CONTA_RIGHE_GDM
/*************************************************************************
 NOME:        F_F24_CONTA_RIGHE_GDM
 DESCRIZIONE: Questa funzione riprende la prima select del mod. F24
              TARES per contare quante righe estrae.
              Se estrae piu' di una riga, allora la seconda select della
              stessa dw deve trovare una riga che corrisponde alla rata unica
              del ruolo (per chi vuole pagare in un'unica soluzione)
 RITORNA:     number             Numero di righe compilate dell'F24.
 NOTE:
 Rev.    Date         Author      Note
 001     19/05/2022   VD          Modificato sistema di conteggio:
                                  non e' necessario sapere quanti F24 vengono
                                  effettivamente stampati, ma quanti F24
                                  sarebbero previsti.
 000     28/05/2018   VD          Prima emissione.
*************************************************************************/
( p_se_stampa_trib varchar2
, p_se_stampa_magg varchar2
, p_cod_fiscale    varchar2
, p_ruolo          number
)
return number
is
  w_conta number := 1;
begin
/*  select count(*)
    into w_conta
    from ad4_comuni ad4_comuni_a
        ,ad4_provincie ad4_provincie_a
        ,archivio_vie
        ,soggetti
        ,contribuenti
        ,ad4_comuni ad4_comuni_b
        ,ad4_provincie ad4_provincie_b
        ,dati_generali dage
        ,ad4_comuni ad4_comuni_c
        ,ruoli ruol
        ,(select max (decode (ruol_prec.rate,  0, 1,  null, 1,  ruol_prec.rate)
                     ) rate
            from ruoli ruol_prec
               , ruoli ruol
           where nvl (ruol_prec.tipo_emissione(+), 'T') = 'A'
             and ruol_prec.invio_consorzio(+) is not null
             and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
             and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
             and ruol.ruolo = p_ruolo
         ) ruol_prec
        ,(select imco1.importo_rata importo_tares
                ,imco1.versato
                ,imco1.importo_tot
                ,imco1.num_fab_tares
                ,imco1.rate
                ,imco1.ruolo
                ,imco1.cod_fiscale
                ,imco1.maggiorazione_tares
                ,decode(imco1.importo_rata
                       ,0,0
                       ,decode(sign(ceil (imco1.versato / imco1.importo_rata) - imco1.rate),0,imco1.rate,1,imco1.rate,ceil (imco1.versato / imco1.importo_rata))
                       )  rate_versate
                ,decode(imco1.importo_rata
                       ,0,imco1.importo_tot
                       ,round (imco1.importo_tot
                          - ((imco1.importo_rata - (imco1.versato - (imco1.importo_rata * decode(trunc (imco1.versato / imco1.importo_rata),
                                                                                                 ceil (imco1.versato / imco1.importo_rata),
                                                                                                 trunc (imco1.versato / imco1.importo_rata) - 1,
                                                                                                 trunc (imco1.versato / imco1.importo_rata)))))
                          + (imco1.importo_rata * (imco1.rate - ceil (imco1.versato / imco1.importo_rata)-1))))
                       )
                   importo_ultima_rata
            from (  select round (  (round (  (  nvl (sum (ruog.importo), 0)
                                               - nvl (sum (ogim.maggiorazione_tares
                                                          )
                                                     ,0
                                                     ))
                                            + nvl (max (sanzioni.sanzione), 0)
                                            - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                   ,ruog.cod_fiscale
                                                                   ,ruol.tipo_tributo
                                                                   ,ruog.ruolo
                                                                   ,'S'
                                                                   )
                                            + f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                   ,ruog.cod_fiscale
                                                                   ,ruol.tipo_tributo
                                                                   ,ruog.ruolo
                                                                   ,'SM'
                                                                   )
                                            - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                   ,ruog.cod_fiscale
                                                                   ,ruol.tipo_tributo
                                                                   ,ruog.ruolo
                                                                   ,'C'
                                                                   )
                                           ,0
                                           ))
                                  / decode (ruol.rate
                                           ,null, 1
                                           ,0, 1
                                           ,ruol.rate
                                           )
                                 ,0
                                 )
                             importo_rata
                          ,decode (nvl (ruol.tipo_emissione, 'T')
                                  ,'T',f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                            ,ruog.cod_fiscale
                                                            ,ruol.tipo_tributo
                                                            ,null
                                                            ,'VN'
                                                            )
                                       + decode (ruol.tipo_ruolo
                                                ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                                ,0
                                                )
                                  ,0)
                             versato
                          , (  (  nvl (sum (ruog.importo), 0)
                                - nvl (sum (ogim.maggiorazione_tares), 0))
                             + nvl (max (sanzioni.sanzione), 0)
                             - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                    ,ruog.cod_fiscale
                                                    ,ruol.tipo_tributo
                                                    ,ruog.ruolo
                                                    ,'S'
                                                    )
                             + f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                    ,ruog.cod_fiscale
                                                    ,ruol.tipo_tributo
                                                    ,ruog.ruolo
                                                    ,'SM'
                                                    )
                             - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                    ,ruog.cod_fiscale
                                                    ,ruol.tipo_tributo
                                                    ,ruog.ruolo
                                                    ,'C'
                                                    )
                             - decode (nvl (ruol.tipo_emissione, 'T')
                                      ,'T', f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                            ,ruog.cod_fiscale
                                                                            ,ruol.tipo_tributo
                                                                            ,null
                                                                            ,'VN'
                                                                            )
                                            + decode (ruol.tipo_ruolo
                                                     ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                                     ,0
                                                     )
                                      ,0
                                      ))
                             importo_tot
                          ,  greatest(0,sum (ogim.maggiorazione_tares)
                           - decode (nvl (ruol.tipo_emissione, 'T')
                                    ,'T', f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                               ,ruog.cod_fiscale
                                                               ,ruol.tipo_tributo
                                                               ,null
                                                               ,'M'
                                                               )
                                         + decode (ruol.tipo_ruolo
                                                  ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'S'),0)
                                                  ,0
                                                  )
                                    ,0
                                    )
                           - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                  ,ruog.cod_fiscale
                                                  ,ruol.tipo_tributo
                                                  ,ruog.ruolo
                                                  ,'SM'
                                                  ))
                             maggiorazione_tares
                          ,count (1) num_fab_tares
                          ,decode (ruol.rate,  null, 1,  0, 1,  ruol.rate) rate
                          ,ruog.ruolo
                          ,ruog.cod_fiscale
                      from oggetti_imposta ogim
                          ,ruoli_contribuente ruog
                          ,ruoli ruol
                          ,sanzioni
                          ,dati_generali dage
                     where ruog.ruolo = ruol.ruolo
                       and ruog.oggetto_imposta = ogim.oggetto_imposta
                       and ruog.cod_fiscale = p_cod_fiscale
                       and ruol.ruolo = p_ruolo
                       and sanzioni.cod_sanzione(+) = 115
                       and sanzioni.tipo_tributo(+) = ruol.tipo_tributo
                  group by ruog.ruolo
                          ,ruog.cod_fiscale
                          ,ruol.rate
                          ,ruol.tipo_emissione
                          ,ruol.anno_ruolo
                          ,ruol.tipo_tributo
                          ,ruol.tipo_ruolo) imco1) tares
        ,(select 1 rata from dual
          union all
          select 2 rata from dual
          union all
          select 3 rata from dual
          union all
          select 4 rata from dual
          union all
          select 5 rata from dual) rate
   where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
     and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
     and soggetti.cod_com_res = ad4_comuni_a.comune(+)
     and soggetti.cod_via = archivio_vie.cod_via(+)
     and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
     and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
     and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
     and soggetti.cod_via = archivio_vie.cod_via(+)
     and dage.pro_cliente = ad4_comuni_c.provincia_stato
     and dage.com_cliente = ad4_comuni_c.comune
     and contribuenti.ni = soggetti.ni
     and rate.rata <= tares.rate
     and contribuenti.cod_fiscale = p_cod_fiscale
     and ruol.ruolo = p_ruolo
     and tares.cod_fiscale = contribuenti.cod_fiscale
     and tares.ruolo = ruol.ruolo
     and (tares.importo_tot > 0.49
      or nvl (tares.maggiorazione_tares, 0) > 0.49)
     and (decode (sign (rate.rata - tares.rate_versate)
                ,1, decode (rate.rata
                           ,tares.rate, importo_ultima_rata
                           ,tares.importo_tares
                           )
                ,0,   decode (rate.rata
                             ,tares.rate, (  tares.importo_tares
                                                                * (rate.rata-1))+importo_ultima_rata
                             , (tares.importo_tares * rate.rata)
                             )
                    - round (tares.versato)
                ,0
                ) > 0    and nvl (p_se_stampa_trib, ' ') = 'S'
        OR  (      decode (rate.rata
                             ,tares.rate,decode (sign (rate.rata - tares.rate_versate)
                ,1, nvl (tares.maggiorazione_tares, 0)
                ,0,   nvl (tares.maggiorazione_tares, 0)
                ,nvl (tares.maggiorazione_tares, 0)),0)
                > 0   and nvl (p_se_stampa_magg, ' ') = 'S')  );*/
-- (VD - 19/05/2022): modifica temporanea per Pioltello, da valutare perche'
--                    potrebbe essere definitiva.
--                    In presenza di ruolo con più rate, se il contribuente
--                    ne deve pagare solo 1 perchè le altre le ha già versate,
--                    questa funzione restituisce il numero di rate residue
--                    Se le rate sono 2 e non si vuole stampare la rata unica,
--                    il risultato è che non viene stampato alcun F24.
--                    Il metodo corretto sarebbe di estrarre il numero delle
--                    rate previste dal ruolo, senza considerare quante ne
--                    sono state gia' pagate.
--
  begin
    select rate
      into w_conta
      from ruoli
     where ruolo = p_ruolo;
  exception
    when others then
      w_conta := 0;
  end;
--
  return w_conta;
--
end;
/* End Function: F_F24_CONTA_RIGHE_GDM */
/

