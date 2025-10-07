--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dato_riog stripComments:false runOnChange:true 
 
create or replace function F_DATO_RIOG
/*************************************************************************
 Rev.    Date         Author      Note
 2       18/02/2021   VD          Modificata definizione categoria catasto
                                  per terreni: se flag riduzione attivo o
                                  mesi riduzione > 0, si considera terreno
                                  ridotto (categoria = 'T2').
                                  Corretta sequenza selezione tipo oggetto
                                  e categoria catasto: prima RIOG, poi OGPR,
                                  poi OGGE.
 1       08/01/2015   VD          Aggiunta gestione tipo RE - Rendita
 0       16/06/2003               Prima emissione
*************************************************************************/
(a_cod_fiscale          in varchar2
,a_oggetto_pratica      in number
,a_anno                 in number
,a_tipo                 in varchar2
) Return string
is
w_valore                   number;
w_flag_possesso            varchar2(1);
w_flag_possesso_prec       varchar2(1);
w_flag_esclusione          varchar2(1);
w_flag_esclusione_prec     varchar2(1);
w_mesi_possesso            number;
w_mesi_possesso_1s         number;
w_mesi_esclusione          number;
w_mesi_esclusione_prec     number;
w_oggetto                  number;
w_tipo_oggetto             number;
w_categoria_catasto        varchar2(3);
w_classe_catasto           varchar2(2);
w_moltiplicatore           number;
w_rivalutazione            number;
w_anno_ogco                number;
w_data_inizio_possesso     date;
w_data_inizio_possesso_1s  date;
w_data_fine_possesso       date;
w_data_fine_possesso_1s    date;
w_data_inizio_anno         date;
w_data_fine_anno           date;
w_data_fine_semestre       date;
w_importo                  number;
w_importo_1s               number;
w_imm_storico              varchar2(1);
begin
--dbms_output.put_line('Oggetto Pratica '||to_char(a_oggetto_pratica));
   w_data_inizio_anno   := to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   w_data_fine_anno     := to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   w_data_fine_semestre := to_date('3006'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   begin
      select f_valore(nvl(f_valore_d(ogpr.oggetto_pratica,a_anno),ogpr.valore)
                     ,ogpr.tipo_oggetto
                     ,prtr.anno
                     ,a_anno
                     ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                     ,prtr.tipo_pratica
                     ,ogpr.FLAG_VALORE_RIVALUTATO
                     )
            ,nvl(ogco.flag_possesso,'N')
            ,decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
            ,decode(ogco.anno,a_anno,ogco.mesi_possesso_1sem,6)
            ,nvl(ogco.flag_esclusione,'N')
            ,decode(ogco.anno
                   ,a_anno,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
                   )
            ,ogge.oggetto
            ,ogge.tipo_oggetto
            ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1,nvl(nvl(ogpr.categoria_catasto,ogge.categoria_catasto),'T')
                   ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                   )
            ,nvl(ogpr.classe_catasto,ogge.classe_catasto)
            -- (VD - 18/02/2021): per problemi di outer join, la selezione
            --                    del moltiplicatore avviene a parte,
            --                    utilizzando come filtri le variabili
            --                    selezionate in questa query
            --,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --       ,1,nvl(molt.moltiplicatore,1)
            --       ,3,decode(nvl(ogpr.IMM_STORICO,'N')||to_char(sign(2012 - a_anno))
            --                ,'S1',100
            --                ,nvl(molt.moltiplicatore,1)
            --                )
            --       ,1
            --       )
            ,nvl(rire.aliquota,0)
            ,ogco.anno
            ,ogpr.IMM_STORICO
        into w_valore
            ,w_flag_possesso
            ,w_mesi_possesso
            ,w_mesi_possesso_1s
            ,w_flag_esclusione
            ,w_mesi_esclusione
            ,w_oggetto
            ,w_tipo_oggetto
            ,w_categoria_catasto
            ,w_classe_catasto
            --,w_moltiplicatore
            ,w_rivalutazione
            ,w_anno_ogco
            ,w_imm_storico
        from oggetti_contribuente   ogco
            ,oggetti_pratica        ogpr
            ,pratiche_tributo       prtr
            ,oggetti                ogge
            ,rivalutazioni_rendita  rire
            --,moltiplicatori         molt
       where /*molt.anno               (+) = a_anno
         and molt.categoria_catasto  (+) =
             --decode(ogge.tipo_oggetto
             --      ,1,nvl(ogge.categoria_catasto,'T')
             --        ,ogge.categoria_catasto
             --      )
             decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1,decode(nvl(ogco.flag_riduzione,'N')
                            ,'S','T2'
                            ,decode(nvl(ogco.mesi_riduzione,0)
                                   ,0,nvl(nvl(ogpr.categoria_catasto,ogge.categoria_catasto),'T')
                                     ,'T2'
                                   )
                            )
                   ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                   )
         and */
             rire.anno               (+) = a_anno
         and rire.tipo_oggetto       (+) = ogge.tipo_oggetto
         and ogge.oggetto                = ogpr.oggetto
         and ogpr.oggetto_pratica        = ogco.oggetto_pratica
         and prtr.pratica                = ogpr.pratica
         and ogco.oggetto_pratica        = a_oggetto_pratica
         and ogco.cod_fiscale            = a_cod_fiscale
      ;
   exception
      when others then
--dbms_output.put_line('Eccezione others '||SQLERRM);
         Return null;
   end;
   -- (VD - 18/02/2021): nuova query per estrarre il moltiplicatore
   --                    relativo alla categoria catasto corretta
   --                    recuperata nella query precedente
   begin
     select decode(w_tipo_oggetto
                  ,1,nvl(molt.moltiplicatore,1)
                  ,3,decode(w_imm_storico||to_char(sign(2012 - a_anno))
                           ,'S1',100
                           ,nvl(molt.moltiplicatore,1)
                           )
                  ,1
                  )
       into w_moltiplicatore
       from moltiplicatori molt
      where molt.anno               = a_anno
        and molt.categoria_catasto  = w_categoria_catasto;
   exception
     when others then
       w_moltiplicatore := 1;
   end;
   begin
      select max(nvl(ogco.flag_possesso,'N'))
            ,substr(max(nvl(ogco.flag_possesso,'N')||nvl(ogco.flag_esclusione,'N')),2,1)
        into w_flag_possesso_prec
            ,w_flag_esclusione_prec
        from oggetti_contribuente      ogco
            ,oggetti_pratica           ogpr
            ,pratiche_tributo          prtr
       where ogco.cod_fiscale                        = a_cod_fiscale
         and ogpr.oggetto                            = w_oggetto
         and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
         and prtr.pratica                            = ogpr.pratica
         and prtr.tipo_tributo||''                   = 'ICI'
         and prtr.anno                               < w_anno_ogco
         and ogco.anno||ogco.tipo_rapporto||nvl(ogco.flag_possesso,'N')
                                                     =
            (select max(b.anno||b.tipo_rapporto||nvl(b.flag_possesso,'N'))
               from pratiche_tributo     c,
                    oggetti_contribuente b,
                    oggetti_pratica      a
              where(    c.data_notifica             is not null
                    and c.tipo_pratica||''            = 'A'
                    and nvl(c.stato_accertamento,'D') = 'D'
                    and nvl(c.flag_denuncia,' ')      = 'S'
                    or  c.data_notifica              is null
                    and c.tipo_pratica||''            = 'D'
                   )
                and c.pratica                         = a.pratica
                and a.oggetto_pratica                 = b.oggetto_pratica
                and c.tipo_tributo||''                = 'ICI'
                and c.anno                            < w_anno_ogco
                and b.cod_fiscale                     = ogco.cod_fiscale
                and a.oggetto                         = w_oggetto
            )
        group by w_oggetto
      ;
   exception
      when no_data_found then
--dbms_output.put_line('no data found');
         w_flag_possesso_prec   := 'N';
         w_flag_esclusione_prec := 'N';
   end;
--dbms_output.put_line('Valore '||to_char(w_valore));
--dbms_output.put_line('Possesso '||nvl(w_flag_possesso,'N')||' per '||to_char(w_mesi_possesso));
--dbms_output.put_line('Oggetto '||to_char(w_oggetto)||' Tipo '||to_char(w_tipo_oggetto));
--dbms_output.put_line('Cat. '||w_categoria_catasto||' Cl '||w_classe_catasto);
--dbms_output.put_line('Molt. '||to_char(w_moltiplicatore)||' Riv. '||to_char(w_rivalutazione));
--dbms_output.put_line('Anno '||to_char(w_anno_ogco)||' Rif '||to_char(a_anno));
--dbms_output.put_line('Prec. Poss. '||w_flag_possesso_prec);
   if w_mesi_esclusione > w_mesi_possesso then
      w_mesi_esclusione := w_mesi_possesso;
   end if;
   w_mesi_possesso := w_mesi_possesso - w_mesi_esclusione;
 /*
   if w_mesi_possesso > 0 then
      if w_flag_possesso = 'S' then
            w_data_inizio_possesso    := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
            w_data_fine_possesso      := w_data_fine_anno;
--dbms_output.put_line('data_inizio_possesso '||to_char(w_data_inizio_possesso,'ddmmyyyy'));
      else
        if w_flag_possesso_prec = 'S' then
            w_data_inizio_possesso    := w_data_inizio_anno;
            w_data_fine_possesso      := add_months(w_data_inizio_anno,w_mesi_possesso) -1;
       else
          if w_mesi_possesso_1s is null or w_mesi_possesso_1s = 0 then
             w_data_inizio_possesso  := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
            w_data_fine_possesso    := w_data_fine_anno;
         else
            if w_mesi_possesso > w_mesi_possesso_1s then
               w_data_inizio_possesso  := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
               w_data_fine_possesso    := add_months(w_data_fine_semestre, w_mesi_possesso - w_mesi_possesso_1s ) ;
            else
               w_data_inizio_possesso  := w_data_inizio_anno;
              w_data_fine_possesso    := add_months(w_data_inizio_anno,w_mesi_possesso) -1;
            end if;
         end if;
       end if;
      end if;
   else
      w_data_inizio_possesso       := null;
      w_data_fine_possesso         := null;
   end if;
   if w_mesi_possesso > 6 then
      if w_flag_possesso = 'S'  then
         w_mesi_possesso_1s        := w_mesi_possesso - 6;
         w_data_inizio_possesso_1s := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
         w_data_fine_possesso_1s   := w_data_fine_semestre;
      else
        if w_flag_possesso_prec = 'S' then
            w_mesi_possesso_1s        := 6;
            w_data_inizio_possesso_1s := w_data_inizio_anno;
            w_data_fine_possesso_1s   := w_data_fine_semestre;
       else
          if w_mesi_possesso_1s is null then
               w_mesi_possesso_1s        := w_mesi_possesso - 6;
               w_data_inizio_possesso_1s := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
               w_data_fine_possesso_1s   := w_data_fine_semestre;
         else
               w_data_inizio_possesso_1s := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
               w_data_fine_possesso_1s   := w_data_fine_semestre;
         end if;
       end if;
      end if;
   else
      if w_flag_possesso = 'S' then
         w_mesi_possesso_1s        := 0;
         w_data_inizio_possesso_1s := null;
         w_data_fine_possesso_1s   := null;
      else
       if w_flag_possesso_prec = 'S' then
            w_mesi_possesso_1s        := w_mesi_possesso;
            w_data_inizio_possesso_1s := w_data_inizio_anno;
            w_data_fine_possesso_1s   := add_months(w_data_inizio_anno,w_mesi_possesso_1s) -1;
       else
          if w_mesi_possesso_1s is null or w_mesi_possesso_1s = 0 then
               w_mesi_possesso_1s        := 0;
               w_data_inizio_possesso_1s := null;
               w_data_fine_possesso_1s   := null;
         else
            if w_mesi_possesso > w_mesi_possesso_1s then
                  w_data_inizio_possesso_1s := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
                  w_data_fine_possesso_1s   := w_data_fine_semestre;
            else
               w_data_inizio_possesso_1s := w_data_inizio_anno;
              w_data_fine_possesso_1s   := add_months(w_data_inizio_anno,w_mesi_possesso_1s) -1;
            end if;
         end if;
       end if;
      end if;
   end if;
   */
     determina_mesi_possesso_ici(w_flag_possesso, w_flag_possesso_prec, a_anno, w_mesi_possesso, w_mesi_possesso_1s,
                               w_data_inizio_possesso, w_data_fine_possesso, w_data_inizio_possesso_1s, w_data_fine_possesso_1s);
   begin
--dbms_output.put_line('Possesso '||to_char(w_data_inizio_possesso,'dd/mm/yyyy')||
--' - '||to_char(w_data_fine_possesso,'dd/mm/yyyy'));
--dbms_output.put_line('Mesi Poss. 1s '||to_char(w_mesi_possesso_1s));
--dbms_output.put_line('Possesso 1s '||to_char(w_data_inizio_possesso_1s,'dd/mm/yyyy')||
--' - '||to_char(w_data_fine_possesso_1s,'dd/mm/yyyy'));
      if a_tipo = 'VA' or a_tipo = 'VT' then
         calcolo_riog_multiplo(w_oggetto
                              ,w_valore
                              ,w_data_inizio_possesso
                              ,w_data_fine_possesso
                              ,w_data_inizio_possesso_1s
                              ,w_data_fine_possesso_1s
                              ,w_moltiplicatore
                              ,w_rivalutazione
                              ,w_tipo_oggetto
                              ,w_anno_ogco
                              ,a_anno
                              ,w_imm_storico
                              ,w_importo
                              ,w_importo_1s
                              )
         ;
--dbms_output.put_line('Importo '||to_char(w_importo));
--dbms_output.put_line(' ');
         if a_tipo = 'VA' then
            Return to_char(w_importo_1s);
         else
            Return to_char(w_importo);
         end if;
      end if;
-- In data 2/3/2006 ho tolto nvl(' ') perche ci creava problemi di controllo referenziale
-- al momento della generazione delle liquidazioni, non si e capito quando e perche era
-- stato messo nvl( - BO12260 - Attivita 15086
      if a_tipo in ('CA','CL','RE') then
         Return f_dato_riog_multiplo
               (w_oggetto
               ,w_categoria_catasto
               ,w_classe_catasto
               ,w_data_inizio_possesso
               ,w_data_fine_possesso
               ,w_data_inizio_possesso_1s
               ,w_data_fine_possesso_1s
               ,a_anno
               ,a_tipo
               );
      end if;
      if a_tipo = 'PT' then
         Return lpad(to_char(nvl(w_mesi_possesso,0)),2,'0')||
                nvl(to_char(w_data_inizio_possesso,'ddmmyyyy'),'00000000')||
                nvl(to_char(w_data_fine_possesso,'ddmmyyyy'),'00000000');
      end if;
      if a_tipo = 'PA' then
         Return lpad(to_char(nvl(w_mesi_possesso_1s,0)),2,'0')||
                nvl(to_char(w_data_inizio_possesso_1s,'ddmmyyyy'),'00000000')||
                nvl(to_char(w_data_fine_possesso_1s,'ddmmyyyy'),'00000000');
      end if;
   end;
exception
   when others then
      Return null;
end;
/* End Function: F_DATO_RIOG */
/

