--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_mesi_possesso_ici stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_MESI_POSSESSO_ICI
(a_anno_rif            in     number
,a_cod_fiscale         in     varchar2
,a_oggetto             in     number
,a_flag_possesso       in     varchar2
,a_flag_esclusione     in     varchar2
,a_flag_al_ridotta     in     varchar2
,a_anno                in     number
,a_mesi_possesso_i     in     number
,a_mesi_al_ridotta_i   in     number
,a_mesi_esclusione_i   in     number
,a_mesi_Possesso       in out number
,a_mesi_possesso_1s    in out number
,a_mesi_al_ridotta     in out number
,a_mesi_al_ridotta_1s  in out number
) is
w_flag_possesso               varchar2(1);
w_flag_possesso_prec          varchar2(1);
w_flag_esclusione             varchar2(1);
w_flag_esclusione_prec        varchar2(1);
w_flag_al_ridotta             varchar2(1);
w_flag_al_ridotta_prec        varchar2(1);
w_mesi_possesso               number(4);
w_mesi_possesso_1s            number(4);
w_mesi_al_ridotta             number(4);
w_mesi_al_ridotta_1s          number(4);
w_mesi_esclusione             number(4);
w_mesi_esclusione_1s          number(4);
BEGIN
-- Di seguito viene eseguito il controllo se l`oggetto era posseduto dal contribuente
-- all`inizio dell`anno di elaborazione. Se l`anno risulta < dell`anno in corso, allora
-- l`oggetto era posseduto, viceversa e` necessario controllare l`eventuale oggetto
-- contribuente precedente (il maggiore tra i minori di anno) a parita` di contribuente
-- e oggetto; se non esiste, l`oggetto non era posseduto, viceversa e` il flag di
-- possesso che fornisce l`informazione desiderata.
   if a_anno < a_anno_rif then
      w_flag_possesso_prec   := a_flag_possesso;
      w_flag_esclusione_prec := a_flag_esclusione;
      w_flag_al_ridotta_prec := a_flag_al_ridotta;
   else
      BEGIN
         select max(ogco.flag_possesso)
               ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_esclusione),2,1)
               ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_al_ridotta),2,1)
           into w_flag_possesso_prec
               ,w_flag_esclusione_prec
               ,w_flag_al_ridotta_prec
           from oggetti_contribuente      ogco
               ,oggetti_pratica           ogpr
               ,pratiche_tributo          prtr
          where ogco.cod_fiscale                        = a_cod_fiscale
            and ogpr.oggetto                            = a_oggetto
            and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
            and prtr.pratica                            = ogpr.pratica
            and prtr.tipo_tributo||''                   = 'ICI'
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
                   and c.anno                            < a_anno
                   and b.cod_fiscale                     = ogco.cod_fiscale
                   and a.oggetto                         = a_oggetto
               )
           group by a_oggetto
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_flag_possesso_prec   := null;
            w_flag_esclusione_prec := null;
            w_flag_al_ridotta_prec := null;
      END;
   end if;
   if w_flag_possesso_Prec is null then
      w_flag_esclusione_prec := null;
      w_flag_al_ridotta_prec := null;
   end if;
-- Se l`oggetto era posseduto a inizio anno e ora e` posseduto, i mesi del 1. semestre
-- sono i mesi di possesso fino ad un massimo di 6; gli eventuali rimanenti sono del
-- 2. semestre (e devono essere 6). Se l`oggetto era posseduto a inizio anno e ora non e`
-- posseduto, i mesi del 1. semestre sono i mesi di possesso fino ad un massimo di 6 e
-- gli eventuali rimanenti sono del 2. semestre. Se l`oggetto non era posseduto a inizio
-- anno e ora e` posseduto, i mesi del 1. semestre sono gli eventuali eccedenti il numero
-- 6 dei mesi di possesso, mentre i mesi del 2. semestre sono i mesi di possesso fino ad
-- un valore massimo di 6. Se l`oggetto non era posseduto a inizio anno e non e` posseduto,
-- non e` possibile stabilire quali siano i mesi del 1. e 2. semestre e quindi i mesi di
-- possesso vengono attribuiti tutti al 2. semestre e nessuno al 1. semestre per creare
-- una situazione piu` favorevole all`utente.
   w_mesi_possesso            := a_mesi_possesso_i;
   if w_mesi_possesso > 6 then
      if a_flag_possesso = 'S' or w_mesi_possesso = 12 then
         w_mesi_possesso_1s   := w_mesi_possesso - 6;
      else
         if w_flag_possesso_prec = 'S' then
            w_mesi_possesso_1s   := 6;
         else
            w_mesi_possesso_1s   := w_mesi_possesso - 6;
         end if;
      end if;
   else
      if a_flag_possesso = 'S' then
         w_mesi_possesso_1s   := 0;
      else
         if w_flag_possesso_prec = 'S' then
            w_mesi_possesso_1s   := w_mesi_possesso;
         else
            w_mesi_possesso_1s   := 0;
         end if;
      end if;
   end if;
   w_mesi_al_ridotta          := a_mesi_al_ridotta_i;
   if w_mesi_al_ridotta > 6 then
      if a_flag_al_ridotta = 'S' or w_mesi_al_ridotta = 12 then
         w_mesi_al_ridotta_1s   := w_mesi_al_ridotta - 6;
      else
         if w_flag_al_ridotta_prec = 'S' then
            w_mesi_al_ridotta_1s   := 6;
         else
            w_mesi_al_ridotta_1s   := w_mesi_al_ridotta - 6;
         end if;
      end if;
   else
      if a_flag_al_ridotta = 'S' then
         w_mesi_al_ridotta_1s   := 0;
      else
         if w_flag_al_ridotta_prec = 'S' then
            w_mesi_possesso_1s   := w_mesi_al_ridotta;
         else
            w_mesi_al_ridotta_1s := 0;
         end if;
      end if;
   end if;
   w_mesi_esclusione          := a_mesi_esclusione_i;
   if w_mesi_esclusione > 6 then
      if a_flag_esclusione = 'S' or w_mesi_esclusione = 12 then
         w_mesi_esclusione_1s   := w_mesi_esclusione - 6;
      else
         if w_flag_esclusione_prec = 'S' then
            w_mesi_esclusione_1s   := 6;
         else
            w_mesi_esclusione_1s   := w_mesi_esclusione - 6;
         end if;
      end if;
   else
      if a_flag_esclusione = 'S' then
         w_mesi_esclusione_1s   := 0;
      else
         if w_flag_esclusione_prec = 'S' then
            w_mesi_esclusione_1s   := w_mesi_esclusione;
         else
            w_mesi_esclusione_1s := 0;
         end if;
      end if;
   end if;
   if nvl(w_mesi_esclusione_1s,0) > nvl(w_mesi_possesso_1s,0) then
      w_mesi_esclusione_1s        := w_mesi_possesso_1s;
   end if;
   if nvl(w_mesi_al_ridotta_1s,0) > nvl(w_mesi_possesso_1s,0) -  nvl(w_mesi_esclusione_1s,0) then
      w_mesi_al_ridotta_1s        := w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0);
   end if;
   a_mesi_possesso        := nvl(w_mesi_possesso,0)      - nvl(w_mesi_esclusione,0);
   a_mesi_possesso_1s     := nvl(w_mesi_possesso_1s,0)   - nvl(w_mesi_esclusione_1s,0);
   a_mesi_al_ridotta      := nvl(w_mesi_al_ridotta,0);
   a_mesi_al_ridotta_1s   := nvl(w_mesi_al_ridotta_1s,0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CALCOLO_MESI_POSSESSO_ICI */
/

