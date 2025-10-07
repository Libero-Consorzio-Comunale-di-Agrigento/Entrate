--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_ravvedimento_da_vers stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CREA_RAVVEDIMENTO_DA_VERS
/***************************************************************************
 NOME:        CREA_RAVVEDIMENTO_DA_VERS
 DESCRIZIONE: Crea una pratica di ravvedimento a fronte di un versamento
              totale per ravvedimento operoso, senza inserire gli immobili
              in oggetti_pratica.
 NOTE:
 Rev.    Date         Author      Note
 003     07/06/2021   VD          Modificata gestione data pratice in
                                  inserimento tabella PRATICHE_TRIBUTO:
                                  ora viene inserita la più piccolata tra
                                  la data di versamento e la data di sistema.
                                  Lo stesso valore viene utilizzato come
                                  parametro nel richiamo della procedure
                                  NUMERA_PRATICHE.
 002     23/03/2021   VD          Modificata valorizzazione data su
                                  PRATICHE_TRIBUTO: si inserisce la data di
                                  sistema per data pratica > data di sistema.
 001     21/12/2020   VD          Corretta gestione di versamento tardivo
                                  per acconto ma nei termini per il saldo.
                                  In questo caso sul saldo si calcola solo
                                  l'imposta evasa.
 000     12/05/2020   VD          Prima emissione
***************************************************************************/
( a_cod_fiscale                   IN  VARCHAR2
, a_anno                          IN  NUMBER
, a_data_versamento               IN  DATE
, a_tipo_versamento               IN  VARCHAR2
, a_flag_infrazione               IN  VARCHAR2
, a_utente                        IN  VARCHAR2
, a_tipo_tributo                  IN  varchar2
, a_sequenza_vers                 IN  number
, a_importo_versato               IN  number
, a_pratica                       IN  OUT NUMBER
, a_messaggio                     OUT varchar2
, a_ab_principale                 IN  number default null
, a_rurali                        IN  number default null
, a_terreni_comune                IN  number default null
, a_terreni_erariale              IN  number default null
, a_aree_comune                   IN  number default null
, a_aree_erariale                 IN  number default null
, a_altri_comune                  IN  number default null
, a_altri_erariale                IN  number default null
, a_fabbricati_d_comune           IN  number default null
, a_fabbricati_d_erariale         IN  number default null
, a_fabbricati_merce              IN  number default null)
IS
w_errore                       varchar(2000) := NULL;
errore                         exception;
w_denuncia                     number;
w_anno_scadenza                number;
w_comune                       varchar2(6);
w_gg_anno                      number;
w_delta_anni                   number;
w_data_pratica                 date;
w_data_rif                     date;
w_scadenza                     date;
w_scadenza_acc                 date;
w_scadenza_present             date;
w_scadenza_pres_rav            date;
w_conta_ravv                   number;
w_conta_ogim                   number;
w_numera                       varchar2(2000);
w_conta_sanzioni               number;
w_importo_sanzioni             number;
w_diff_giorni                  number;
w_diff_giorni_acc              number;
w_diff_giorni_pres             number;
w_imposta_a                    number;
w_sanzioni_a                   number;
w_interessi_a                  number;
w_imposta_s                    number;
w_sanzioni_s                   number;
w_interessi_s                  number;
w_cod_sanzione_acc             number;
w_sequenza_sanz_acc            number(4);
w_rid_acc                      number;
w_percentuale_acc              number;
w_tot_int_gg_acc               number;
w_imposta_acc                  number;
w_sanzioni_acc                 number;
w_interessi_acc                number;
w_cod_sanzione_sal             number;
w_sequenza_sanz_sal            number(4);
w_rid_sal                      number;
w_percentuale_sal              number;
w_tot_int_gg_sal               number;
w_imposta_sal                  number;
w_sanzioni_sal                 number;
w_interessi_sal                number;
w_importo_versato              number;
w_ab_principale                number;
w_terreni_agricoli             number;
w_terreni_comune               number;
w_terreni_erariale             number;
w_aree_fabbricabili            number;
w_aree_comune                  number;
w_aree_erariale                number;
w_rurali                       number;
w_rurali_comune                number;
w_rurali_erariale              number;
w_altri_fabbricati             number;
w_altri_comune                 number;
w_altri_erariale               number;
w_fabbricati_d                 number;
w_fabbricati_d_comune          number;
w_fabbricati_d_erariale        number;
w_fabbricati_merce             number;
w_tipo_versamento              varchar2(1);
w_cod_sanzione                 number;
w_sequenza_sanz                number(4);
w_imposta                      number;
w_sanzioni                     number;
w_interessi                    number;
w_ind                          number;
w_max_ind                      number;
type type_imposta_acc   is table of number      index by binary_integer;
t_imposta_acc                  type_imposta_acc;
type type_sanzioni_acc  is table of number      index by binary_integer;
t_sanzioni_acc                 type_sanzioni_acc;
type type_interessi_acc is table of number      index by binary_integer;
t_interessi_acc                type_interessi_acc;
type type_imposta_sal   is table of number      index by binary_integer;
t_imposta_sal                  type_imposta_sal;
type type_sanzioni_sal  is table of number      index by binary_integer;
t_sanzioni_sal                 type_sanzioni_sal;
type type_interessi_sal is table of number      index by binary_integer;
t_interessi_sal                type_interessi_sal;
w_diff_quad                    number;
w_importo_min                  number;
w_importo_max                  number;
w_tipo_min                     varchar2(3);
w_tipo_max                     varchar2(3);
w_dep_importo                  number;
--------------------------------------------------------------------------------
PROCEDURE IMPOSTA_SANZIONI_INTERESSI
( p_importo_versato            IN number
, p_percentuale                IN number
, p_tot_int_gg                 IN number
, p_gg_anno                    IN number
, p_imposta                   OUT number
, p_sanzioni                  OUT number
, p_interessi                 OUT number
) is
begin
  if p_importo_versato is not null then
     p_imposta   := round(p_importo_versato /
                         (1 + (p_percentuale / 100) + 1 * p_tot_int_gg / p_gg_anno),2);
     p_sanzioni  := round(p_imposta * p_percentuale / 100,2);
     p_interessi := round(p_imposta * p_tot_int_gg / p_gg_anno,2);
     if p_interessi <> (p_importo_versato - p_imposta - p_sanzioni) then
        p_interessi := p_importo_versato - p_imposta - p_sanzioni;
        if p_interessi < 0 then
           p_sanzioni  := p_sanzioni + p_interessi;
           p_interessi := 0;
        end if;
     end if;
  else
     p_imposta    := to_number(null);
     p_sanzioni   := to_number(null);
     p_interessi  := to_number(null);
  end if;
end;
PROCEDURE IMPOSTA_SANZIONI_INTERESSI_U
( p_importo_versato            IN number
, p_percentuale_acc            IN number
, p_tot_int_gg_acc             IN number
, p_percentuale_sal            IN number
, p_tot_int_gg_sal             IN number
, p_gg_anno                    IN number
, p_giorni_diff_acc            IN number
, p_giorni_diff_sal            IN number
, p_imposta_acc               OUT number
, p_sanzioni_acc              OUT number
, p_interessi_acc             OUT number
, p_imposta_sal               OUT number
, p_sanzioni_sal              OUT number
, p_interessi_sal             OUT number
) is
  w_imposta                       number;
begin
  --dbms_output.put_line('Importo versato: '||p_importo_versato);
  if p_importo_versato is not null then
     w_imposta   := round(p_importo_versato /
                    (1 + 1/2 * ((p_percentuale_acc / 100) + (p_tot_int_gg_acc / p_gg_anno)) +
                         1/2 * ((p_percentuale_sal / 100) + (p_tot_int_gg_sal / p_gg_anno))),2);
     p_imposta_acc   := round(w_imposta / 2,2);
     p_imposta_sal   := p_imposta_acc;
     p_sanzioni_acc  := round(p_imposta_acc * p_percentuale_acc / 100,2);
     p_interessi_acc := round(p_imposta_acc * p_tot_int_gg_acc / p_gg_anno,2);
     p_sanzioni_sal  := round(p_imposta_sal * p_percentuale_sal / 100,2);
     p_interessi_sal := round(p_imposta_sal * p_tot_int_gg_sal / p_gg_anno,2);
     if p_interessi_sal > 0 then
        if p_interessi_sal <> (p_importo_versato - p_imposta_sal - p_sanzioni_sal -
                               p_imposta_acc - p_sanzioni_acc - p_interessi_acc) then
           p_interessi_sal := p_importo_versato - p_imposta_sal - p_sanzioni_sal -
                              p_imposta_acc - p_sanzioni_acc - p_interessi_acc;
           if p_interessi_sal < 0 then
              p_sanzioni_sal := p_sanzioni_sal + p_interessi_sal;
              p_interessi_sal := 0;
           end if;
        end if;
     else
        if p_interessi_acc <> (p_importo_versato - p_imposta_sal - p_sanzioni_sal -
                               p_imposta_acc - p_sanzioni_acc) then
           p_interessi_acc := p_importo_versato - p_imposta_sal - p_sanzioni_sal -
                              p_imposta_acc - p_sanzioni_acc;
           if p_interessi_acc < 0 then
              p_sanzioni_acc  := p_sanzioni_acc + p_interessi_acc;
              p_interessi_acc := 0;
           end if;
        end if;
     end if;
  else
     p_imposta_acc   := to_number(null);
     p_imposta_sal   := to_number(null);
     p_sanzioni_acc  := to_number(null);
     p_interessi_acc := to_number(null);
     p_sanzioni_sal  := to_number(null);
     p_interessi_sal := to_number(null);
  end if;
  --dbms_output.put_line('Acconto: '||p_imposta_acc||', '||p_sanzioni_acc||', '||p_interessi_acc);
  --dbms_output.put_line('Saldo  : '||p_imposta_sal||', '||p_sanzioni_sal||', '||p_interessi_sal);
end;

--
-- Funzione per il recupero della sequenza della sanzione
--
FUNCTION F_SEQUENZA_SANZIONE
(a_cod_sanzione      IN     number
,a_data_scadenza     IN     date
,a_sequenza          IN OUT number
) Return string
is
  w_err                varchar2(2000);
BEGIN
   w_err := null;
   BEGIN
      select sanz.sequenza
        into a_sequenza
        from sanzioni sanz
       where sanz.tipo_tributo = a_tipo_tributo
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista in data ' || to_char(a_data_scadenza,'DD/MM/YYYY');
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   return w_err;
END F_SEQUENZA_SANZIONE;
--------------------------------------------------------------------------------

BEGIN
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
           , decode(to_char(last_day(to_date('02'||a_anno,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366))
        into w_comune
           , w_gg_anno
        from dati_generali
           ;
   END;
   w_anno_scadenza := to_number(to_char(a_data_versamento,'yyyy'));
 -------------------------------------------------------------------------
 -- Controlli prima della creazione---------------------------------------
 -------------------------------------------------------------------------
 --DBMS_OUTPUT.Put_Line('1 - Controlli prima della creazione');
 --DBMS_OUTPUT.Put_Line('2 - Controllo dell''anno della pratica');
    -- Controllo dell'anno della pratica
   if a_anno < 1998 then
      w_errore  := 'Gestione Non Prevista per Anni con Vecchio sanzionamento';
      raise errore;
   end if;
   --DBMS_OUTPUT.Put_Line('3 - Controllo di esistenza di dichiarazioni precedenti');
   -- Controllo di esistenza di dichiarazioni precedenti
   -- (VD - 22/07/2020): questo controllo non ha senso perche' si caricano
   --                    ravvedimenti senza oggetti
/*   BEGIN
     select max(1)
       into w_denuncia
       from pratiche_tributo prtr
          , rapporti_tributo ratr
      where prtr.pratica       = ratr.pratica
        and ratr.cod_fiscale   = a_cod_fiscale
        and prtr.tipo_pratica in ('D','A')
        and decode(prtr.tipo_pratica,'D','S',prtr.flag_denuncia) = 'S'
        and nvl(prtr.stato_accertamento,'D') = 'D'
        and prtr.tipo_tributo||'' = a_tipo_tributo
        and prtr.anno         <= a_anno
          ;
   EXCEPTION
       WHEN OTHERS THEN
           w_denuncia := 0;
   END;
   if nvl(w_denuncia,0) = 0 then
      a_pratica := null;
      w_errore  := '4 - Non esistono dichiarazioni precedenti ('||a_cod_fiscale||')';
      raise errore;
   end if; */
   -- Determinazione scadenza presentazione denuncia
   w_delta_anni := 0;
   w_errore := F_GET_DATA_SCADENZA(a_tipo_tributo,a_anno + w_delta_anni,null,'D',w_scadenza_present);
   if w_errore is not null then
      raise errore;
   end if;
   w_errore := F_GET_DATA_SCADENZA(a_tipo_tributo,a_anno,'A','V',w_scadenza_acc);
   if w_errore is not null then
      raise errore;
   end if;
   w_errore := F_GET_DATA_SCADENZA(a_tipo_tributo,a_anno,'S','V',w_scadenza);
   if w_errore is not null then
      raise errore;
   end if;
--dbms_output.put_line('Scadenze - Pres. '||to_char(w_scadenza_present,'dd/mm/yyyy')||' Acc. '||
--to_char(w_scadenza_acc,'dd/mm/yyyy')||' Sal. '||to_char(w_scadenza,'dd/mm/yyyy')||' delta '||
--to_char(w_delta_anni));
--
--
   if a_flag_infrazione is null then
      w_errore := F_GET_DATA_SCADENZA(a_tipo_tributo,a_anno + w_delta_anni,null,'R',w_scadenza_pres_rav);
   else
      w_errore := F_GET_DATA_SCADENZA(a_tipo_tributo,a_anno + w_delta_anni + 1,null,'R',w_scadenza_pres_rav);
   end if;
   if w_errore is not null then
      raise errore;
   end if;
   --DBMS_OUTPUT.Put_Line('7 - La Data del Ravvedimento e` > alla Scadenza per Ravvedersi');
   if a_data_versamento > w_scadenza_pres_rav then
      w_errore := 'La Data del Ravvedimento '||to_char(a_data_versamento,'dd/mm/yyyy')||
                  ' e` > della Scadenza per Ravvedersi '||to_char(w_scadenza_pres_rav,'dd/mm/yyyy') ||
                  ' ('||a_cod_fiscale||')';
      raise errore;
   end if;
   -- Controllo data versamento: se e' antecedente alla scadenza prevista
   -- non e' possibile caricare un ravvedimento
   if (a_tipo_versamento = 'A' and a_data_versamento <= w_scadenza_acc) or
      (a_tipo_versamento = 'S' and a_data_versamento <= w_scadenza) or
      (a_tipo_versamento = 'U' and a_data_versamento <= w_scadenza_acc and a_data_versamento <= w_scadenza) then
      w_errore := 'Ravvedimento non possibile - versamento effettuato entro la scadenza prevista';
      raise errore;
   end if;
   --DBMS_OUTPUT.Put_Line('8 - Esistono altre Pratiche di Ravvedimento per questo Pagamento');
   if a_pratica is null then
      BEGIN
         select count(*)
           into w_conta_ravv
           from sanzioni_pratica sapr
               ,pratiche_tributo prtr
               ,sanzioni         sanz
          where sapr.pratica                      = prtr.pratica
            and prtr.cod_fiscale                  = a_cod_fiscale
            and prtr.anno                         = a_anno
            and prtr.tipo_tributo||''             = a_tipo_tributo
            and nvl(prtr.stato_accertamento,'D')  ='D'
            and prtr.tipo_pratica                 = 'V'
            and prtr.tipo_tributo                 = sanz.tipo_tributo
            and sapr.cod_sanzione                 = sanz.cod_sanzione
            and sapr.sequenza_sanz                = sanz.sequenza
            and (    a_tipo_versamento            = 'A'
                 and sanz.tipo_versamento         = 'A'
                 or  a_tipo_versamento            = 'S'
                 and sanz.tipo_versamento         = 'S'
                 or  a_tipo_versamento            = 'U'
                 and sanz.tipo_versamento         in ('A','S')
                )
               ;
         if w_conta_ravv > 0 then
            w_errore := 'Esistono altre Pratiche di Ravvedimento per questo Pagamento ('||a_cod_fiscale||')';
            raise errore;
         end if;
      END;
   end if;
   -----------------------------------------------------------------------------------------------
   -- Inserimento della pratica--------------------------------------------------------------------
   -----------------------------------------------------------------------------------------------
   --DBMS_OUTPUT.Put_Line('11 - Inserimento della pratica');
   --a_pratica := null;
   w_data_pratica := a_data_versamento;
   -- Se la pratica non e' nulla, significa che e stato modificato il
   -- tipo versamento e occorre ricalcolare le sanzioni: si eliminano
   -- le righe di sanzioni_pratica e si aggiorna il tipo versamento
   -- su pratiche_tributo
   if a_pratica is not null then
      begin
        delete sanzioni_pratica
         where pratica = a_pratica;
      exception
       WHEN OTHERS THEN
             w_errore := 'Errore in eliminazione sanzioni pratica '||a_pratica;
             raise errore;
      end;
      -- (VD - 23/03/2021): modificata valorizzazione data pratica
      begin
        update pratiche_tributo
           set tipo_evento = a_tipo_versamento
             , data        = trunc(sysdate)  --a_data_versamento)
         where pratica = a_pratica;
      exception
       WHEN OTHERS THEN
             w_errore := 'Errore in aggiornamento pratica '||a_pratica;
             raise errore;
      end;
   else
      PRATICHE_TRIBUTO_NR(a_pratica);
      -- (VD - 23/03/2021): modificata valorizzazione data pratica
      begin
         Insert into PRATICHE_TRIBUTO
             ( pratica
             , cod_fiscale
             , tipo_tributo
             , anno
             , tipo_pratica
             , tipo_evento
             , data
             , data_rif_ravvedimento
             , utente
             , data_variazione
             , tipo_ravvedimento)
         Values
             ( a_pratica
             , a_cod_fiscale
             , a_tipo_tributo
             , a_anno
             , 'V'
             , a_tipo_versamento
             -- (VD - 07/06/2021): modificata gestione data pratica
             , least(trunc(sysdate),a_data_versamento)
             , least(trunc(sysdate),a_data_versamento)
             , a_utente
             , trunc(sysdate)
             ,'V')
             ;
      EXCEPTION
          WHEN OTHERS THEN
                w_errore := 'Errore in inserimento pratica per '||a_cod_fiscale;
                raise errore;
      end;
      begin
         Insert into RAPPORTI_TRIBUTO
             ( pratica
             , cod_fiscale
             , tipo_rapporto)
         Values
             ( a_pratica
             , a_cod_fiscale
             , NULL)
             ;
      EXCEPTION
          WHEN OTHERS THEN
                w_errore := 'Errore in inserimento ratr per '||a_cod_fiscale;
                raise errore;
      end;
      begin
         Insert into contatti_contribuente
             ( cod_fiscale
             , data
             , numero
             , anno
             , tipo_contatto
             , tipo_richiedente
             , testo
             , tipo_tributo)
         Values
             ( a_cod_fiscale
             , trunc(sysdate)
             , NULL
             , a_anno
             , 10
             , 2
             , NULL
             , a_tipo_tributo)
             ;
      EXCEPTION
          WHEN OTHERS THEN
                w_errore := 'Errore in inserimento coco per '||a_cod_fiscale;
                raise errore;
      end;
   end if;
   -----------------------------------------------------------------------------
   -- Calcoli
   -----------------------------------------------------------------------------
   -- Determinazione differenza giorni tra data scadenza e data effettiva
   BEGIN
      select a_data_versamento - w_scadenza
            ,a_data_versamento - w_scadenza_acc
            ,a_data_versamento - w_scadenza_present
        into w_diff_giorni
            ,w_diff_giorni_acc
            ,w_diff_giorni_pres
        from dual
      ;
   END;
   --dbms_output.put_line('Cod.fiscale '||a_cod_fiscale||' Scadenza acc. '||to_date(w_scadenza_acc,'dd/mm/yyyy')||', giorni '||w_diff_giorni_acc);
   --dbms_output.put_line('Cod.fiscale '||a_cod_fiscale||' Scadenza saldo '||to_date(w_scadenza,'dd/mm/yyyy')||', giorni '||w_diff_giorni);
   -- Valorizzazione dell'importo versato a seconda della provenienza:
   -- se a_importo_versato null e a_sequenza not null, occorre ricavare
   -- gli importi dal versamento
   if a_sequenza_vers is null then
      w_importo_versato       := nvl(a_importo_versato,0);
      w_ab_principale         := nvl(a_ab_principale,0);
      w_rurali                := nvl(a_rurali,0);
      w_terreni_comune        := nvl(a_terreni_comune,0);
      w_terreni_erariale      := nvl(a_terreni_erariale,0);
      w_aree_comune           := nvl(a_aree_comune,0);
      w_aree_erariale         := nvl(a_aree_erariale,0);
      w_altri_comune          := nvl(a_altri_comune,0);
      w_altri_erariale        := nvl(a_altri_erariale,0);
      w_fabbricati_d_comune   := nvl(a_fabbricati_d_comune,0);
      w_fabbricati_d_erariale := nvl(a_fabbricati_d_erariale,0);
      w_fabbricati_merce      := nvl(a_fabbricati_merce,0);
   else
      begin
        select importo_versato
             , nvl(ab_principale,0)
             , nvl(rurali,0)
             , nvl(terreni_comune,0)
             , nvl(terreni_erariale,0)
             , decode(a_tipo_tributo,'ICI',nvl(aree_comune,0),nvl(aree_fabbricabili,0))
             , nvl(aree_erariale,0)
             , decode(a_tipo_tributo,'ICI',nvl(altri_comune,0),nvl(altri_fabbricati,0))
             , nvl(altri_erariale,0)
             , nvl(fabbricati_d_comune,0)
             , nvl(fabbricati_d_erariale,0)
             , nvl(fabbricati_merce,0)
          into w_importo_versato
             , w_ab_principale
             , w_rurali
             , w_terreni_comune
             , w_terreni_erariale
             , w_aree_comune
             , w_aree_erariale
             , w_altri_comune
             , w_altri_erariale
             , w_fabbricati_d_comune
             , w_fabbricati_d_erariale
             , w_fabbricati_merce
          from versamenti
         where tipo_tributo = a_tipo_tributo
           and cod_fiscale = a_cod_fiscale
           and anno = a_anno
           and sequenza = a_sequenza_vers;
      exception
        when others then
          w_errore := substr('Sel. VERSAMENTI - C.F. '||a_cod_fiscale||
                             ', sequenza '||a_sequenza_vers||' - '||sqlerrm,1,2000);
          raise errore;
      end;
   end if;
  --dbms_output.put_line('Importo versato: '||w_importo_versato);
  --dbms_output.put_line('Ab. principale: '||w_ab_principale);
  --dbms_output.put_line('Fabbr.rurali: '||w_rurali);
  --dbms_output.put_line('Terreni comune: '||w_terreni_comune);
  --dbms_output.put_line('Terreni erariale: '||w_terreni_erariale);
  --dbms_output.put_line('Aree comune: '||w_aree_comune);
  --dbms_output.put_line('Aree erariale: '||w_aree_erariale);
  --dbms_output.put_line('Altri fabbr. comune: '||w_altri_comune);
  --dbms_output.put_line('Altri fabbr. erariale: '||w_altri_erariale);
  --dbms_output.put_line('Fabbr. D comune: '||w_fabbricati_d_comune);
  --dbms_output.put_line('Fabbr. D erariale: '||w_fabbricati_d_erariale);
  --dbms_output.put_line('Fabbr. merce: '||w_fabbricati_merce);
  -- Definizione sanzione e interessi per tardivo versamento in acconto
  if a_tipo_versamento in  ('A','U') and w_diff_giorni_acc > 0 then
     -- Ravvedimento operoso lungo
     if w_diff_giorni_acc > 730 and
        a_data_versamento >= to_date('01012020','ddmmyyyy') then
        w_cod_sanzione_acc := 166;
        w_rid_acc := 6;
     elsif
        w_diff_giorni_acc > 365 and
        a_data_versamento >= to_date('01012020','ddmmyyyy') then
        w_cod_sanzione_acc := 165;
        w_rid_acc := 7;
     elsif
     -- Ravvedimento operoso medio
        (w_diff_giorni_acc > 90 and
         a_data_versamento >= to_date('01012015','ddmmyyyy')) or
        (w_diff_giorni_acc > 30 and
         a_data_versamento < to_date('01012015','ddmmyyyy')) then
        w_rid_acc      := 8;
        if sign(2 - w_anno_scadenza + a_anno) < 1 then
           w_cod_sanzione_acc := 155;
        else
           w_cod_sanzione_acc := 152;
        end if;
     elsif w_diff_giorni_acc > 30 then
        w_rid_acc      := 9;
        if  sign(2 - w_anno_scadenza + a_anno) < 1 then
           w_cod_sanzione_acc := 155;
        else
           w_cod_sanzione_acc := 152;
        end if;
     else
        -- ravvedimento operoso sprint
        w_rid_acc         := 10;
        if w_diff_giorni_acc <= 15 then
           w_cod_sanzione_acc := 157;
        else
           w_cod_sanzione_acc := 158;
        end if;
     end if;
     --
     -- Se la pratica e' del 2016 e il versamento e' stato effettuato
     -- entro 90 gg dalla scadenza, la sanzione viene dimezzata
     -- (la riduzione viene raddoppiata)
     if a_data_versamento >= to_date('01/01/2016','dd/mm/yyyy') and
        w_diff_giorni_acc <= 90 then
        w_rid_acc := w_rid_acc * 2;
     end if;
     --
     if w_cod_sanzione_acc is null then
        w_errore := 'Non è stato possibile determinare il codice sanzione per l''acconto - impossibile caricare la pratica'||
                    ' - Cod.fiscale/Anno: '||a_cod_fiscale||'/'||a_anno;
        raise errore;
     else
        w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione_acc,w_scadenza_acc,w_sequenza_sanz_acc);
        if w_errore is not null then
           RAISE ERRORE;
        end if;
     end if;
     --dbms_output.put_line('Cod. sanzione acconto: '||w_cod_sanzione_acc);
     -- Determinazione della percentuale di sanzione in base al codice
     BEGIN
        select decode(cod_sanzione
                     ,157,round(sanz.percentuale * w_diff_giorni_acc / w_rid_acc,2)
                         ,round(sanz.percentuale / w_rid_acc,2)
                     )
          into w_percentuale_acc
          from sanzioni sanz
         where tipo_tributo   = a_tipo_tributo
           and cod_sanzione   = w_cod_sanzione_acc
           and sequenza = w_sequenza_sanz_acc
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Codice sanzione '||w_cod_sanzione_acc||' non presente';
           raise errore;
     END;
     -- Determinazione della somma delle percentuali di interesse per i
     -- relativi giorni
     w_tot_int_gg_acc := 0;
     for sel_int in (select inte.aliquota
                          , greatest(inte.data_inizio,w_scadenza_acc) dal
                          , least(inte.data_fine,a_data_versamento) al
                      from interessi inte
                     where inte.tipo_tributo      = a_tipo_tributo
                       and inte.data_inizio      <= a_data_versamento
                       and inte.data_fine        >= w_scadenza_acc
                       and inte.tipo_interesse    = 'L'
                     order by 2)
     loop
       w_tot_int_gg_acc := w_tot_int_gg_acc + (sel_int.aliquota * (sel_int.al - sel_int.dal + 1) / 100);
     end loop;
     --dbms_output.put_line('Giorni interessi acconto: '||w_tot_int_gg_acc);
  else
     w_percentuale_acc := 0;
     w_tot_int_gg_acc  := 0;
  end if;
  -- Definizione sanzione per tardivo versamento a saldo
  if a_tipo_versamento in ('S','U') and w_diff_giorni > 0 then
     -- Ravvedimento operoso lungo
     if w_diff_giorni > 730 and
        a_data_versamento >= to_date('01012020','ddmmyyyy') then
        w_cod_sanzione_sal := 168;
        w_rid_sal := 6;
     elsif
        w_diff_giorni > 365 and
        a_data_versamento >= to_date('01012020','ddmmyyyy') then
        w_cod_sanzione_sal := 167;
        w_rid_sal := 7;
     elsif
        (w_diff_giorni > 90 and
         a_data_versamento >= to_date('01012015','ddmmyyyy')) or
        (w_diff_giorni > 30 and
         a_data_versamento < to_date('01012015','ddmmyyyy')) then
        if  sign(2 - w_anno_scadenza + a_anno) < 1 then
           w_cod_sanzione_sal := 156;
           w_rid_sal := 8;
        else
           w_cod_sanzione_sal := 154;
           w_rid_sal := 8;
        end if;
     elsif w_diff_giorni > 30 then
        if  sign(2 - w_anno_scadenza + a_anno) < 1 then
           w_cod_sanzione_sal := 156;
           w_rid_sal := 9;
        else
           w_cod_sanzione_sal := 154;
           w_rid_sal := 9;
        end if;
     else
        if w_diff_giorni <= 15 then
           w_cod_sanzione_sal := 159;
           w_rid_sal          := 10;
        else
           w_cod_sanzione_sal := 160;
           w_rid_sal          := 10;
        end if;
     end if;
     --
     -- (VD - 18/01/2016): Se la pratica e' del 2016 e il versamento e'
     --                    stato effettuato entro 90 gg dalla scadenza,
     --                    la sanzione viene dimezzata (la riduzione
     --                    viene raddoppiata)
     if w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
        w_diff_giorni <= 90 then
        w_rid_sal := w_rid_sal * 2;
     end if;
     --
     if w_cod_sanzione_sal is null then
        w_errore := 'Non è stato possibile determinare il codice sanzione per il saldo - impossibile caricare la pratica'||
                    ' - Cod.fiscale/Anno: '||a_cod_fiscale||'/'||a_anno;
        raise errore;
     else
        w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione_sal,w_scadenza,w_sequenza_sanz_sal);
        if w_errore is not null then
           RAISE ERRORE;
        end if;
     end if;
     --dbms_output.put_line('Cod. sanzione saldo: '||w_cod_sanzione_sal);
     BEGIN
        select decode(cod_sanzione
                     ,159,round(sanz.percentuale * w_diff_giorni / w_rid_sal,2)
                         ,round(sanz.percentuale / w_rid_sal,2)
                     )
          into w_percentuale_sal
          from sanzioni sanz
         where tipo_tributo   = a_tipo_tributo
           and cod_sanzione   = w_cod_sanzione_sal
           and sequenza       = w_sequenza_sanz_sal
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Codice sanzione '||w_cod_sanzione_sal||' non presente';
           raise errore;
     END;
     -- Determinazione della somma delle percentuali di interesse per i
     -- relativi giorni
     w_tot_int_gg_sal := 0;
     for sel_int in (select inte.aliquota
                          , greatest(inte.data_inizio,w_scadenza) dal
                          , least(inte.data_fine,a_data_versamento) al
                      from interessi inte
                     where inte.tipo_tributo      = a_tipo_tributo
                       and inte.data_inizio      <= a_data_versamento
                       and inte.data_fine        >= w_scadenza
                       and inte.tipo_interesse    = 'L'
                     order by 2)
     loop
       w_tot_int_gg_sal := w_tot_int_gg_sal + (sel_int.aliquota * (sel_int.al - sel_int.dal + 1) / 100);
     end loop;
     --dbms_output.put_line('Interessi saldo: '||w_tot_int_gg_sal);
  else
     w_percentuale_sal := 0;
     w_tot_int_gg_sal  := 0;
  end if;
  --dbms_output.put_line('Percentuale_acc: '|| w_percentuale_acc);
  --dbms_output.put_line('w_tot_int_gg_acc: '|| w_tot_int_gg_acc);
  --dbms_output.put_line('Percentuale_sal: '|| w_percentuale_sal);
  --dbms_output.put_line('w_tot_int_gg_sal: '|| w_tot_int_gg_sal);
  --dbms_output.put_line('w_gg_anno: '|| w_gg_anno);
  -- Calcolo imposta, sanzioni, interessi
  t_imposta_acc.delete;
  t_sanzioni_acc.delete;
  t_interessi_acc.delete;
  t_imposta_sal.delete;
  t_sanzioni_sal.delete;
  t_interessi_sal.delete;
  if a_tipo_versamento = 'A' and w_diff_giorni_acc > 0 then
     w_imposta_acc := 0;
     w_sanzioni_acc := 0;
     w_interessi_acc := 0;
     if w_ab_principale + w_rurali + w_terreni_comune + w_terreni_erariale +
        w_aree_comune + w_aree_erariale + w_altri_comune + w_altri_erariale +
        w_fabbricati_d_comune + w_fabbricati_d_erariale + w_fabbricati_merce = 0 then
        -- Gli importi non sono suddivisi per tipologia: si calcola solo il versato
        -- complessivo
        IMPOSTA_SANZIONI_INTERESSI (w_importo_versato, w_percentuale_acc, w_tot_int_gg_acc,
                                    w_gg_anno, w_imposta, w_sanzioni, w_interessi);
        w_imposta_acc    := w_imposta;
        w_sanzioni_acc   := w_sanzioni;
        w_interessi_acc  := w_interessi;
        -- Si annullano gli importi per tipologia
        for w_ind in 1..11
        loop
          t_imposta_acc (w_ind)   := to_number(null);
          t_sanzioni_acc (w_ind)  := to_number(null);
          t_interessi_acc (w_ind) := to_number(null);
        end loop;
     else
        for w_ind in 1..11
        loop
          select decode(w_ind,1,w_ab_principale            -- Abitazione principale (indice = 1)
                             ,2,w_rurali                   -- Fabbricati rurali (indice = 2)
                             ,3,w_terreni_comune           -- Terreni agricoli quota comune (indice = 3 - solo IMU)
                             ,4,w_terreni_erariale         -- Terreni agricoli quota erario (indice = 4)
                             ,5,w_aree_comune              -- Aree fabbricabili quota comune (indice = 5)
                             ,6,w_aree_erariale            -- Aree fabbricabili quota erario (indice = 6)
                             ,7,w_altri_comune             -- Altri fabbricati quota comune (indice = 7)
                             ,8,w_altri_erariale           -- Altri fabbricati quota erario (indice = 8)
                             ,9,w_fabbricati_d_comune      -- Fabbricati di tipo D quota comune (indice = 9)
                             ,10,w_fabbricati_d_erariale   -- Fabbricati di tipo D quota erario (indice = 10)
                             ,11,w_fabbricati_merce        -- Fabbricati merce (indice = 11)
                             ,to_number(null)
                       )
            into w_dep_importo
            from dual;
          IMPOSTA_SANZIONI_INTERESSI (w_dep_importo, w_percentuale_acc, w_tot_int_gg_acc,
                                      w_gg_anno, w_imposta, w_sanzioni, w_interessi);
          t_imposta_acc(w_ind)    := w_imposta;
          t_sanzioni_acc (w_ind)  := w_sanzioni;
          t_interessi_acc (w_ind) := w_interessi;
          -- Totalizzazione per tipologia
          w_imposta_acc   := w_imposta_acc + w_imposta;
          w_sanzioni_acc  := w_sanzioni_acc + w_sanzioni;
          w_interessi_acc := w_interessi_acc + w_interessi;
        end loop;
     end if;
     -- Annullamento dati saldo
     w_imposta_sal   := to_number(null);
     w_sanzioni_sal  := to_number(null);
     w_interessi_sal := to_number(null);
     for w_ind in 1..11
     loop
       t_imposta_sal (w_ind)   := to_number(null);
       t_sanzioni_sal (w_ind)  := to_number(null);
       t_interessi_sal (w_ind) := to_number(null);
     end loop;
  end if;
  if a_tipo_versamento = 'S' and w_diff_giorni > 0 then
     w_imposta_sal := 0;
     w_sanzioni_sal := 0;
     w_interessi_sal := 0;
     if w_ab_principale + w_rurali + w_terreni_comune + w_terreni_erariale +
        w_aree_comune + w_aree_erariale + w_altri_comune + w_altri_erariale +
        w_fabbricati_d_comune + w_fabbricati_d_erariale + w_fabbricati_merce = 0 then
        -- Gli importi non sono suddivisi per tipologia: si calcola solo il versato
        -- complessivo
        IMPOSTA_SANZIONI_INTERESSI (w_importo_versato, w_percentuale_sal, w_tot_int_gg_sal,
                                    w_gg_anno, w_imposta, w_sanzioni, w_interessi);
        w_imposta_sal   := w_imposta;
        w_sanzioni_sal  := w_sanzioni;
        w_interessi_sal := w_interessi;
        -- Si annullano gli importi per tipologia
        for w_ind in 1..11
        loop
          t_imposta_sal (w_ind)   := to_number(null);
          t_sanzioni_sal (w_ind)  := to_number(null);
          t_interessi_sal (w_ind) := to_number(null);
        end loop;
     else
        for w_ind in 1..11
        loop
          select decode(w_ind,1,w_ab_principale            -- Abitazione principale (indice = 1)
                             ,2,w_rurali                   -- Fabbricati rurali (indice = 2)
                             ,3,w_terreni_comune           -- Terreni agricoli quota comune (indice = 3 - solo IMU)
                             ,4,w_terreni_erariale         -- Terreni agricoli quota erario (indice = 4)
                             ,5,w_aree_comune              -- Aree fabbricabili quota comune (indice = 5)
                             ,6,w_aree_erariale            -- Aree fabbricabili quota erario (indice = 6)
                             ,7,w_altri_comune             -- Altri fabbricati quota comune (indice = 7)
                             ,8,w_altri_erariale           -- Altri fabbricati quota erario (indice = 8)
                             ,9,w_fabbricati_d_comune      -- Fabbricati di tipo D quota comune (indice = 9)
                             ,10,w_fabbricati_d_erariale   -- Fabbricati di tipo D quota erario (indice = 10)
                             ,11,w_fabbricati_merce        -- Fabbricati merce (indice = 11)
                             ,to_number(null)
                       )
            into w_dep_importo
            from dual;
          IMPOSTA_SANZIONI_INTERESSI (w_dep_importo, w_percentuale_sal, w_tot_int_gg_sal,
                                      w_gg_anno, w_imposta, w_sanzioni, w_interessi);
          t_imposta_sal(w_ind)    := w_imposta;
          t_sanzioni_sal (w_ind)  := w_sanzioni;
          t_interessi_sal (w_ind) := w_interessi;
          w_imposta_sal   := w_imposta_sal + w_imposta;
          w_sanzioni_sal  := w_sanzioni_sal + w_sanzioni;
          w_interessi_sal := w_interessi_sal + w_interessi;
        end loop;
     end if;
     -- Annullamento dati acconto
     w_imposta_acc   := to_number(null);
     w_sanzioni_acc  := to_number(null);
     w_interessi_acc := to_number(null);
     for w_ind in 1..11
     loop
       t_imposta_acc (w_ind)   := to_number(null);
       t_sanzioni_acc (w_ind)  := to_number(null);
       t_interessi_acc (w_ind) := to_number(null);
     end loop;
  end if;
  if a_tipo_versamento = 'U' then
     w_imposta_acc := 0;
     w_sanzioni_acc := 0;
     w_interessi_acc := 0;
     w_imposta_sal := 0;
     w_sanzioni_sal := 0;
     w_interessi_sal := 0;
     if w_ab_principale + w_rurali + w_terreni_comune + w_terreni_erariale +
        w_aree_comune + w_aree_erariale + w_altri_comune + w_altri_erariale +
        w_fabbricati_d_comune + w_fabbricati_d_erariale + w_fabbricati_merce = 0 then
        -- Gli importi non sono suddivisi per tipologia: si calcola solo il versato
        -- complessivo
        IMPOSTA_SANZIONI_INTERESSI_U (w_importo_versato, w_percentuale_acc, w_tot_int_gg_acc,
                                      w_percentuale_sal, w_tot_int_gg_sal,w_gg_anno,
                                      w_diff_giorni_acc, w_diff_giorni,
                                      w_imposta_a, w_sanzioni_a, w_interessi_a,
                                      w_imposta_s, w_sanzioni_s, w_interessi_s);
        w_imposta_acc   := w_imposta_a;
        w_sanzioni_acc  := w_sanzioni_a;
        w_interessi_acc := w_interessi_a;
        w_imposta_sal   := w_imposta_s;
        w_sanzioni_sal  := w_sanzioni_s;
        w_interessi_sal := w_interessi_s;
        for w_ind in 1..11
        loop
          -- Annullamento importi in acconto per tipologia
          t_imposta_acc (w_ind)   := to_number(null);
          t_sanzioni_acc (w_ind)  := to_number(null);
          t_interessi_acc (w_ind) := to_number(null);
          -- Annullamento importi a saldo per tipologia
          t_imposta_sal (w_ind)   := to_number(null);
          t_sanzioni_sal (w_ind)  := to_number(null);
          t_interessi_sal (w_ind) := to_number(null);
        end loop;
     else
        for w_ind in 1..11
        loop
          select decode(w_ind,1,w_ab_principale            -- Abitazione principale (indice = 1)
                             ,2,w_rurali                   -- Fabbricati rurali (indice = 2)
                             ,3,w_terreni_comune           -- Terreni agricoli quota comune (indice = 3 - solo IMU)
                             ,4,w_terreni_erariale         -- Terreni agricoli quota erario (indice = 4)
                             ,5,w_aree_comune              -- Aree fabbricabili quota comune (indice = 5)
                             ,6,w_aree_erariale            -- Aree fabbricabili quota erario (indice = 6)
                             ,7,w_altri_comune             -- Altri fabbricati quota comune (indice = 7)
                             ,8,w_altri_erariale           -- Altri fabbricati quota erario (indice = 8)
                             ,9,w_fabbricati_d_comune      -- Fabbricati di tipo D quota comune (indice = 9)
                             ,10,w_fabbricati_d_erariale   -- Fabbricati di tipo D quota erario (indice = 10)
                             ,11,w_fabbricati_merce        -- Fabbricati merce (indice = 11)
                             ,to_number(null)
                       )
            into w_dep_importo
            from dual;
          IMPOSTA_SANZIONI_INTERESSI_U (w_dep_importo, w_percentuale_acc, w_tot_int_gg_acc,
                                        w_percentuale_sal, w_tot_int_gg_sal,w_gg_anno,
                                        w_diff_giorni_acc, w_diff_giorni,
                                        w_imposta_a, w_sanzioni_a, w_interessi_a,
                                        w_imposta_s, w_sanzioni_s, w_interessi_s);
          t_imposta_acc( w_ind)   := w_imposta_a;
          t_sanzioni_acc (w_ind)  := w_sanzioni_a;
          t_interessi_acc (w_ind) := w_interessi_a;
          t_imposta_sal (w_ind)   := w_imposta_s;
          t_sanzioni_sal (w_ind)  := w_sanzioni_s;
          t_interessi_sal (w_ind) := w_interessi_s;
          w_imposta_acc   := w_imposta_acc + w_imposta_a;
          w_sanzioni_acc  := w_sanzioni_acc + w_sanzioni_a;
          w_interessi_acc := w_interessi_acc + w_interessi_a;
          w_imposta_sal   := w_imposta_sal + w_imposta_s;
          w_sanzioni_sal  := w_sanzioni_sal + w_sanzioni_s;
          w_interessi_sal := w_interessi_sal + w_interessi_s;
        end loop;
     end if;
  end if;
  -- Quadratura interessi acconto
  if a_tipo_versamento = 'A' then
     if w_interessi_acc <> (w_importo_versato - w_imposta_acc - w_sanzioni_acc) then
        w_interessi_acc := w_importo_versato - w_imposta_acc - w_sanzioni_acc;
     end if;
  end if;
  --dbms_output.put_line('Imposta acc.1: '||w_imposta_acc);
  --dbms_output.put_line('Sanzione acc.1: '||w_sanzioni_acc);
  --dbms_output.put_line('Interessi acc.1: '||w_interessi_acc);
  if a_tipo_versamento = 'S' then
     if w_interessi_sal <> (w_importo_versato - w_imposta_sal - w_sanzioni_sal) then
        w_interessi_sal := w_importo_versato - w_imposta_sal - w_sanzioni_sal;
     end if;
  else
     if w_interessi_sal <> (w_importo_versato - w_imposta_sal - w_sanzioni_sal -
                         w_imposta_acc - w_sanzioni_acc - w_interessi_acc) then
        w_interessi_sal := w_importo_versato - w_imposta_sal - w_sanzioni_sal -
                           w_imposta_acc - w_sanzioni_acc - w_interessi_acc;
     end if;
  end if;
  --dbms_output.put_line('Imposta acc.: '||w_imposta_acc);
  --dbms_output.put_line('Sanzione acc.: '||w_sanzioni_acc);
  --dbms_output.put_line('Interessi acc.: '||w_interessi_acc);
  --dbms_output.put_line('Imposta saldo: '||w_imposta_sal);
  --dbms_output.put_line('Sanzione saldo: '||w_sanzioni_sal);
  --dbms_output.put_line('Interessi saldo: '||w_interessi_sal);
  -- Inserimento sanzione in sanzioni_pratica
  -- Il trattamento viene eseguito 2 volte per gestire il caso di
  -- versamento unico
  if a_tipo_versamento = 'U' then
     w_max_ind := 2;
     w_tipo_versamento := 'A';
  else
     w_max_ind := 1;
     w_tipo_versamento := a_tipo_versamento;
  end if;
  for w_ind in 1..w_max_ind
  loop
    if w_ind = 2 then
       w_tipo_versamento := 'S';
    end if;
    if (w_tipo_versamento = 'A' and w_cod_sanzione_acc is not null and nvl(w_sanzioni_acc,0) <> 0) or
       (w_tipo_versamento = 'S' and w_cod_sanzione_sal is not null and nvl(w_sanzioni_sal,0) <> 0) then
       begin
          insert into sanzioni_pratica
                ( pratica, cod_sanzione, tipo_tributo
                , percentuale, importo
                , ab_principale, rurali
                , terreni_comune, terreni_erariale
                , aree_comune, aree_erariale
                , altri_comune, altri_erariale
                , fabbricati_d_comune, fabbricati_d_erariale
                , fabbricati_merce
                , utente, data_variazione
                , note
                , sequenza_sanz
                )
          values( a_pratica
                , decode(w_tipo_versamento,'A',w_cod_sanzione_acc,w_cod_sanzione_sal)
                , a_tipo_tributo
                , decode(w_tipo_versamento,'A',w_percentuale_acc,w_percentuale_sal)
                , decode(w_tipo_versamento,'A',w_sanzioni_acc,w_sanzioni_sal)
                , decode(w_tipo_versamento,'A',t_sanzioni_acc (1),t_sanzioni_sal (1))           -- ab_principale
                , decode(w_tipo_versamento,'A',t_sanzioni_acc (2),t_sanzioni_sal (2))           -- rurali
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (3),t_sanzioni_sal (3)))   -- terreni_comune
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (4),t_sanzioni_sal (4)))   -- terreni_erariale
                , decode(w_tipo_versamento,'A',t_sanzioni_acc (5),t_sanzioni_sal (5))           -- aree_comune
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (6),t_sanzioni_sal (6)))   -- aree_erariale
                , decode(w_tipo_versamento,'A',t_sanzioni_acc (7),t_sanzioni_sal (7))           -- altri_comune
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (8),t_sanzioni_sal (8)))   -- altri_erariale
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (9),t_sanzioni_sal (9)))   -- fabbricati_d_comune
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (10),t_sanzioni_sal (10))) -- fabbricati_d_erariale
                , decode(a_tipo_tributo,'TASI',to_number(null)
                        ,decode(w_tipo_versamento,'A',t_sanzioni_acc (11),t_sanzioni_sal (11))) -- fabbricati_merce
                , a_utente, trunc(sysdate)
                , 'Ulteriore riduzione di 1/'||to_char(decode(w_tipo_versamento,'A',w_rid_acc,w_rid_sal))||' per ravvedimento operoso'
                , decode(w_tipo_versamento,'A',w_sequenza_sanz_acc,w_sequenza_sanz_sal)
                )
          ;
       exception
         when others then
           w_errore := substr('Ins. SANZIONI_PRATICA - C.F. '||a_cod_fiscale||
                              ', cod.sanzione '||w_cod_sanzione_acc||'/'||w_cod_sanzione_sal||' - '||sqlerrm,1,2000);
           raise errore;
       end;
    end if;
    if (w_tipo_versamento = 'A' and nvl(w_interessi_acc,0) <> 0) or
       (w_tipo_versamento = 'S' and nvl(w_interessi_sal,0) <> 0) then
       -- Determinazione codice sanzione per interessi
       begin
         select cod_sanzione, sequenza
           into w_cod_sanzione, w_sequenza_sanz
           from sanzioni sanz
          where tipo_tributo = a_tipo_tributo
            and tipo_versamento = w_tipo_versamento --decode(a_tipo_versamento,'U','A',a_tipo_versamento)
            and tipo_causale = 'I'
            and cod_sanzione > 100
            and decode(w_tipo_versamento,'A',w_scadenza_acc,w_scadenza)
                between sanz.data_inizio and sanz.data_fine
            ;
            --and nvl(flag_interessi,'S') = 'S';
       exception
         when others then
           w_cod_sanzione := to_number(null);
       end;
       --dbms_output.put_line('Cod. sanzione interessi: '||w_cod_sanzione);
       --
       if w_cod_sanzione is not null then
          begin
             insert into sanzioni_pratica
                   ( pratica, cod_sanzione, tipo_tributo
                   , importo, giorni
                   , ab_principale, rurali
                   , terreni_comune, terreni_erariale
                   , aree_comune, aree_erariale
                   , altri_comune, altri_erariale
                   , fabbricati_d_comune, fabbricati_d_erariale
                   , fabbricati_merce
                   , utente, data_variazione, note, sequenza_sanz
                   )
             values( a_pratica, w_cod_sanzione,a_tipo_tributo
                   , decode(w_tipo_versamento,'A',w_interessi_acc,w_interessi_sal)
                   , decode(w_tipo_versamento,'A',w_diff_giorni_acc,w_diff_giorni)
                   , decode(w_tipo_versamento,'A',t_interessi_acc (1),t_interessi_sal (1))           -- Ab. principale
                   , decode(w_tipo_versamento,'A',t_interessi_acc (2),t_interessi_sal (2))           -- Fabbricati rurali
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (3),t_interessi_sal (3)))   -- Terreni comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (4),t_interessi_sal (4)))   -- Terreni erariale
                   , decode(w_tipo_versamento,'A',t_interessi_acc (5),t_interessi_sal (5))           -- Aree comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (6),t_interessi_sal (6)))   -- Aree erariale
                   , decode(w_tipo_versamento,'A',t_interessi_acc (7),t_interessi_sal (7))           -- Altri comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (8),t_interessi_sal (8)))   -- Altri erariale
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (9),t_interessi_sal (9)))   -- Fabbricati D comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (10),t_interessi_sal (10))) -- Fabbricati D erariale
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_interessi_acc (11),t_interessi_sal (11))) -- Fabbricati merce
                   , a_utente, trunc(sysdate), null, w_sequenza_sanz
                   )
             ;
          exception
            when others then
              w_errore := substr('Ins. SANZIONI_PRATICA - C.F. '||a_cod_fiscale||
                                 ', cod.sanzione '||w_cod_sanzione||' - '||sqlerrm,1,2000);
              raise errore;
          end;
       end if;
    end if;
    if (w_tipo_versamento = 'A' and nvl(w_imposta_acc,0) <> 0) or
       (w_tipo_versamento = 'S' and nvl(w_imposta_sal,0) <> 0) then
       -- Determinazione codice sanzione per imposta
       begin
         select cod_sanzione, sequenza
           into w_cod_sanzione, w_sequenza_sanz
           from sanzioni sanz
          where tipo_tributo = a_tipo_tributo
            and tipo_versamento = w_tipo_versamento --decode(a_tipo_versamento,'U','A',a_tipo_versamento)
            and tipo_causale = 'E'
            and cod_sanzione > 100
            and decode(w_tipo_versamento,'A',w_scadenza_acc,w_scadenza)
                between sanz.data_inizio and sanz.data_fine
            ;
            --and nvl(flag_imposta,'S') = 'S';
       exception
         when others then
           w_cod_sanzione := to_number(null);
       end;
       --dbms_output.put_line('Cod.sanzione imposta: '||w_cod_sanzione);
       --
       if w_cod_sanzione is not null then
          begin
             insert into sanzioni_pratica
                   ( pratica, cod_sanzione, tipo_tributo
                   , importo
                   , ab_principale, rurali
                   , terreni_comune, terreni_erariale
                   , aree_comune, aree_erariale
                   , altri_comune, altri_erariale
                   , fabbricati_d_comune, fabbricati_d_erariale
                   , fabbricati_merce
                   , utente, data_variazione ,note, sequenza_sanz
                   )
             values( a_pratica, w_cod_sanzione,a_tipo_tributo
                   , decode(w_tipo_versamento,'A',w_imposta_acc,w_imposta_sal)
                   , decode(w_tipo_versamento,'A',t_imposta_acc (1),t_imposta_sal (1))            -- Ab. principale
                   , decode(w_tipo_versamento,'A',t_imposta_acc (2),t_imposta_sal (2))            -- Fabbricati rurali
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (3),t_imposta_sal (3)))    -- Terreni comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (4),t_imposta_sal (4)))    -- Terreni erariale
                   , decode(w_tipo_versamento,'A',t_imposta_acc (5),t_imposta_sal (5))           -- Aree comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (6),t_imposta_sal (6)))    -- Aree erariale
                   , decode(w_tipo_versamento,'A',t_imposta_acc (7),t_imposta_sal (7))            -- Altri comune
                           ,decode(a_tipo_tributo,'TASI',to_number(null)
                   , decode(w_tipo_versamento,'A',t_imposta_acc (8),t_imposta_sal (8)))           -- Altri erariale
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (9),t_imposta_sal (9)))    -- Fabbricati D comune
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (10),t_imposta_sal (10)))  -- Fabbricati D erariale
                   , decode(a_tipo_tributo,'TASI',to_number(null)
                           ,decode(w_tipo_versamento,'A',t_imposta_acc (11),t_imposta_sal (11)))  -- Fabbricati Merce
                   , a_utente, trunc(sysdate), null, w_sequenza_sanz
                   )
             ;
          exception
            when others then
              w_errore := substr('Ins. SANZIONI_PRATICA - C.F. '||a_cod_fiscale||
                                 ', cod.sanzione '||w_cod_sanzione||' - '||sqlerrm,1,2000);
              raise errore;
          end;
       end if;
    end if;
  end loop;
  --
  -- Se la pratica appena inserita non contiene sanzioni viene cancellata,
  -- non si esegue la numerazione e si restituisce null
  --
  begin
    select sum(nvl(importo,0))
         , count(*)
      into w_conta_sanzioni
         , w_importo_sanzioni
      from sanzioni_pratica
     where pratica = a_pratica
     group by pratica;
  exception
    when others then
      w_conta_sanzioni := 0;
  end;
  --
  if w_conta_sanzioni = 0 or w_importo_sanzioni = 0 then
     begin
       delete from pratiche_tributo
        where pratica = a_pratica;
     exception
       when others then
         w_errore := 'Errore in eliminazione pratica ravv. priva di sanzioni per '||a_cod_fiscale;
         raise errore;
     end;
     a_pratica := to_number(null);
  else
     -- Numerazione pratica
     begin
       select valore
         into w_numera
         from installazione_parametri
        where parametro = 'N_AUTO_RAV'
       ;
     EXCEPTION
       WHEN OTHERS THEN
          w_numera := 'N';
     end;
     if w_numera = 'S' then
        -- (VD - 07/06/2021): modificato passaggio data pratica
        numera_pratiche( a_tipo_tributo, 'V', null, a_cod_fiscale, a_anno, a_anno
                       , least(trunc(sysdate),a_data_versamento)
                       , least(trunc(sysdate),a_data_versamento));
     end if;
     -- Se la pratica e' stata generata da un versamento, si aggiorna
     -- la pratica sul versamento
     if a_sequenza_vers is not null then
        begin
          update versamenti
             set pratica = a_pratica
           where tipo_tributo = a_tipo_tributo
             and cod_fiscale = a_cod_fiscale
             and anno = a_anno
             and sequenza = a_sequenza_vers;
        exception
          when others then
            w_errore := substr('Upd. VERSAMENTI - '||a_cod_fiscale||', Sequenza '||
                               a_sequenza_vers||':'|| sqlerrm,1,2000);
            raise errore;
        end;
     end if;
  end if;
  if w_errore is not null then
     a_pratica := null;
     raise errore;
  end if;
  --dbms_output.put_line('Pratica inserita: '||a_pratica);
EXCEPTION
   WHEN ERRORE THEN
      --ROLLBACK;
      a_messaggio := w_errore;
      -- RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      --ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CREA_RAVVEDIMENTO_DA_VERS */
/
