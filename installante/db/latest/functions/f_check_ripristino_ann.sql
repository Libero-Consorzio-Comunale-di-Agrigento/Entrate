--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_ripristino_ann stripComments:false runOnChange:true 
 
create or replace function F_CHECK_RIPRISTINO_ANN
/*************************************************************************
 Data una pratica da riattivare, la funzione verifica che per ogni oggetto
 esista la relativa iscrizione attiva,
 Per le pratiche di variazione, si controlla che non esistano pratiche di
 cessazione valide con data antecedente alla decorrenza della variazione
 che si vuole ripristinare
 Nota: il flag w_ogpr_valido puo assumere i seguenti valori:
       0 - controlli superati
       1 - oggetto per cui non esiste un'iscrizione valida
       2 - oggetto per cui esiste una cessazione in data antecedente
           alla data della variazione da ripristinare
 Versione  Data              Autore    Descrizione
 1         14/05/2024        DM        Rimosso controllo su ripristino C
 0         16/06/2015        VD        Prima emissione
*************************************************************************/
( a_pratica      number )
return varchar2
is
w_tipo_evento            varchar2(1);
w_cod_fiscale            varchar2(16);
w_ogpr_valido            number;
w_oggetti_ok             varchar2(1) := 'S';
w_messaggio              varchar2(2000) := null;
begin
--
-- Si seleziona il tipo evento della pratica da trattare
--
  begin
    select tipo_evento
         , cod_fiscale
      into w_tipo_evento
         , w_cod_fiscale
      from pratiche_tributo
     where pratica = a_pratica;
  exception
    when others then
      w_tipo_evento := 'X';
      w_oggetti_ok := 'N';
  end;
--
  if
     w_tipo_evento = 'I' then
     w_messaggio := null;
  elsif
     w_tipo_evento = 'V' then
     for rec_ogpr in (select ogpr.oggetto_pratica
                           , ogpr.oggetto_pratica_rif
                           , ogco.data_decorrenza
                        from oggetti_pratica      ogpr
                           , oggetti_contribuente ogco
                       where ogpr.pratica = a_pratica
                         and ogpr.oggetto_pratica = ogco.oggetto_pratica
                         and ogco.cod_fiscale = w_cod_fiscale)
     loop
       if rec_ogpr.oggetto_pratica_rif is not null then
          begin
            select 0
              into w_ogpr_valido
              from pratiche_tributo prtr
                 , oggetti_pratica ogpr
             where prtr.pratica = ogpr.pratica
               and ogpr.oggetto_pratica = rec_ogpr.oggetto_pratica_rif
               and prtr.flag_annullamento is null;
          exception
            when others then
              w_ogpr_valido := 1;
          end;
          --
          if w_ogpr_valido = 0 then
             begin
               select 0
                 into w_ogpr_valido
                 from dual
                where not exists (select 'x'
                                    from oggetti_contribuente ogco
                                       , oggetti_pratica      ogpr
                                       , pratiche_tributo     prtr
                                   where rec_ogpr.oggetto_pratica_rif = ogpr.oggetto_pratica_rif
                                     and ogco.cod_fiscale = prtr.cod_fiscale
                                     and ogco.oggetto_pratica = ogpr.oggetto_pratica
                                     and ogpr.pratica = prtr.pratica
             --                                  and prtr.tipo_evento = 'C'
                                     and prtr.flag_annullamento is null
                                     and ogco.data_cessazione < rec_ogpr.data_decorrenza);
             exception
               when others then
                 w_ogpr_valido := 2;
             end;
          end if;
       else
          w_ogpr_valido := 0;
       end if;
       --
       if w_ogpr_valido = 1 then
          w_messaggio:= 'Non esistono oggetti attivi per la pratica da riattivare';
          exit;
       end if;
       --
       if w_ogpr_valido = 2 then
          w_messaggio:= 'Esistono cessazioni antecedenti alla pratica da riattivare';
          exit;
       end if;
     end loop;
  end if;
return(w_messaggio);
end;
/* End Function: F_CHECK_RIPRISTINO_ANN */
/

