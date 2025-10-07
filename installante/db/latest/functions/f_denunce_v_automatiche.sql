--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_denunce_v_automatiche stripComments:false runOnChange:true 
 
create or replace function F_DENUNCE_V_AUTOMATICHE
(a_tipo_tributo         IN varchar2,
 a_anno                 IN number,
 a_cod_via              IN number,
 a_data_denuncia        IN date,
 a_data_decorrenza      IN date,
 a_tributo              IN number,
 a_da_categoria         IN number,
 a_a_categoria          IN number,
 a_da_tariffa           IN number,
 a_a_tariffa            IN number,
 a_cod_fiscale          IN varchar2,
 a_utente               IN varchar2,
 a_messaggio            IN OUT varchar2
) return number
/******************************************************************************
 NOME:        F_DENUNCE_V_AUTOMATICHE
 DESCRIZIONE: Crea Denunce di Variazione Automatiche

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   18/04/2023  RV      #Issue55400
                           Prima emissione, basatta su DENUNCE_V_AUTOMATICHE
******************************************************************************/
IS
 DENUNCIA   CONSTANT VARCHAR2(1) := 'D';
 errore         exception;
 no_tari        exception;
 ric_tari       exception;
 w_errore       varchar2(2000);
 w_check        number(1);
 w_a_tariffa    number(2);
 --
 w_contatore    number;
 w_elaborati    number;
 w_messaggio    varchar2(2000);
 w_retcode      number;
 --
CURSOR sel_ogva(p_tipo_tributo IN varchar2, p_tributo IN number,
       p_da_categoria IN number, p_da_tariffa IN number,
       p_data_decorrenza IN date, p_cod_via IN number,
       p_cod_fiscale IN varchar2)
 IS
    select ogpr.pratica,
       ogpr.oggetto_pratica,
       ogpr.tipo_tariffa,
       ogva.cod_fiscale,
       ogva.oggetto_pratica_rif
     from oggetti_validita ogva
        , oggetti ogge
        , oggetti_pratica ogpr
        , pratiche_tributo prtr
      where nvl(ogge.cod_via,0)           = decode(p_cod_via,-1,nvl(ogge.cod_via,0),p_cod_via)
        and ogge.oggetto              = ogpr.oggetto
        and ogpr.tipo_tariffa       = nvl(p_da_tariffa,ogpr.tipo_tariffa)
        and ogpr.categoria       = p_da_categoria
        and ogpr.tributo       = p_tributo
   and prtr.pratica            = ogva.pratica
   and nvl(ogva.dal,to_date('01/01/1900','dd/mm/yyyy')) <= p_data_decorrenza
   and nvl(ogva.al, to_date('31/12/9999','dd/mm/yyyy')) > p_data_decorrenza
   and ogva.tipo_pratica ||''   in ('D','A')
   and decode(ogva.tipo_pratica,'D','S',ogva.flag_denuncia) = 'S'
   and nvl(ogva.stato_accertamento,'D')   = 'D'
   and (    trunc(sysdate) - nvl(prtr.data_notifica,trunc(sysdate))   > 60
               and prtr.flag_adesione      is NULL
               or  decode(ogva.tipo_pratica,'D','S',prtr.flag_adesione)     is not NULL
       )
   and ogva.tipo_tributo||''   = p_tipo_tributo
   and nvl(ogva.tipo_occupazione,'P') = 'P'
   and ogva.oggetto_pratica    = ogpr.oggetto_pratica
        and ogva.cod_fiscale        like nvl(p_cod_fiscale,'%')
      order by ogva.cod_fiscale,ogva.pratica asc
    ;
--
-- f_insert_prtr
--
FUNCTION f_insert_prtr(
   p_pratica   IN OUT NUMBER,
   p_pratica_rif    IN NUMBER,
   p_anno      IN NUMBER,
   p_data      IN DATE,
   p_utente   IN VARCHAR2) RETURN number
   IS
   EVENTO      CONSTANT VARCHAR2(1) := 'V';
   CURSOR sel_prtr(p_pratica number)
   IS
   select  cod_fiscale, tipo_tributo, tipo_carica,
      denunciante, indirizzo_den, cod_pro_den,
      cod_com_den, cod_fiscale_den, partita_iva_den,
      pratica_rif, p_utente
      from pratiche_tributo
     where pratica = p_pratica
   ;
   BEGIN
      p_pratica := NULL;
      pratiche_tributo_nr(p_pratica);
      FOR rec_prtr IN sel_prtr(p_pratica_rif) LOOP
         BEGIN
            insert into PRATICHE_TRIBUTO
            (pratica, cod_fiscale, tipo_tributo, anno, tipo_pratica, tipo_evento,
             data, tipo_carica, denunciante, indirizzo_den, cod_pro_den,
             cod_com_den, cod_fiscale_den, partita_iva_den,
             pratica_rif, utente, note)
             VALUES (p_pratica, rec_prtr.cod_fiscale, rec_prtr.tipo_tributo, p_anno,
               DENUNCIA, EVENTO, p_data, rec_prtr.tipo_carica,
               rec_prtr.denunciante, rec_prtr.indirizzo_den, rec_prtr.cod_pro_den,
                rec_prtr.cod_com_den, rec_prtr.cod_fiscale_den, rec_prtr.partita_iva_den,
                null, p_utente, 'Variazione Automatica del '||to_char(sysdate,'dd/mm/yyyy'))
            ;
         EXCEPTION
            WHEN OTHERS THEN
                RAISE;
                 RETURN -1;
         END;
      END LOOP;
      RETURN 0;
END f_insert_prtr;
--
-- f_insert_ogpr
--
FUNCTION f_insert_ogpr(
   p_ogpr      IN OUT NUMBER,
   p_pratica   IN NUMBER,
   p_anno          IN NUMBER,
   p_cate_nuova    IN NUMBER,
   p_tari_nuova    IN NUMBER,
   p_ogpr_rif      IN NUMBER,
   p_ogpr_da       IN NUMBER,
   p_utente   IN VARCHAR2) RETURN number
IS
   CURSOR sel_ogpr(p_ogpr number)
   IS
      select  *
         from oggetti_pratica
        where oggetto_pratica = p_ogpr
      ;
BEGIN
      p_ogpr := NULL;
      oggetti_pratica_nr(p_ogpr);
      FOR rec_ogpr IN sel_ogpr(p_ogpr_da) LOOP
         BEGIN
           insert into OGGETTI_PRATICA
               (oggetto_pratica,oggetto,pratica,tributo,categoria,anno,
                tipo_tariffa,num_ordine,imm_storico,
                categoria_catasto,classe_catasto,valore,flag_provvisorio,
                flag_valore_rivalutato,titolo,estremi_titolo,modello,
                flag_firma,fonte,consistenza_reale,consistenza,
                locale,coperta,scoperta,settore,flag_uip_principale,
                reddito,classe_sup,imposta_base,imposta_dovuta,
                flag_domicilio_fiscale,num_concessione,data_concessione,
                inizio_concessione,fine_concessione,larghezza,profondita,
                cod_pro_occ,cod_com_occ,indirizzo_occ,da_chilometro,
                a_chilometro,lato,tipo_occupazione,flag_contenzioso,
                oggetto_pratica_rif,utente,note,tipo_oggetto,
                titolo_occupazione,natura_occupazione,destinazione_uso,
                assenza_estremi_catasto, data_anagrafe_tributaria,
                numero_familiari,flag_dati_metrici,perc_riduzione_sup,
                flag_nulla_osta,quantita,qualita,tipo_qualita)
           VALUES (p_ogpr,rec_ogpr.oggetto,p_pratica,rec_ogpr.tributo,p_cate_nuova,p_anno,
               nvl(p_tari_nuova,rec_ogpr.tipo_tariffa),rec_ogpr.num_ordine,rec_ogpr.imm_storico,
               rec_ogpr.categoria_catasto,rec_ogpr.classe_catasto,rec_ogpr.valore,rec_ogpr.flag_provvisorio,
               rec_ogpr.flag_valore_rivalutato,rec_ogpr.titolo,rec_ogpr.estremi_titolo,rec_ogpr.modello,
               rec_ogpr.flag_firma,rec_ogpr.fonte,rec_ogpr.consistenza_reale,rec_ogpr.consistenza,
               rec_ogpr.locale,rec_ogpr.coperta,rec_ogpr.scoperta,rec_ogpr.settore,rec_ogpr.flag_uip_principale,
               rec_ogpr.reddito,rec_ogpr.classe_sup,rec_ogpr.imposta_base,rec_ogpr.imposta_dovuta,
               rec_ogpr.flag_domicilio_fiscale,rec_ogpr.num_concessione,rec_ogpr.data_concessione,
               rec_ogpr.inizio_concessione,rec_ogpr.fine_concessione,rec_ogpr.larghezza,rec_ogpr.profondita,
               rec_ogpr.cod_pro_occ,rec_ogpr.cod_com_occ,rec_ogpr.indirizzo_occ,rec_ogpr.da_chilometro,
               rec_ogpr.a_chilometro,rec_ogpr.lato,rec_ogpr.tipo_occupazione,rec_ogpr.flag_contenzioso,
               p_ogpr_rif,p_utente,'Variazione Automatica del '||to_char(sysdate,'dd/mm/yyyy'),
               rec_ogpr.tipo_oggetto, rec_ogpr.titolo_occupazione,rec_ogpr.natura_occupazione,
               rec_ogpr.destinazione_uso,rec_ogpr.assenza_estremi_catasto,rec_ogpr.data_anagrafe_tributaria,
               rec_ogpr.numero_familiari, rec_ogpr.flag_dati_metrici, rec_ogpr.perc_riduzione_sup,
               rec_ogpr.flag_nulla_osta,rec_ogpr.quantita,rec_ogpr.qualita,rec_ogpr.tipo_qualita)
            ;
         EXCEPTION
            WHEN OTHERS THEN
                 RAISE;
                 RETURN -1;
         END;
      END LOOP;
      RETURN 0;
END f_insert_ogpr;
--
-- f_insert_ogco
--
FUNCTION f_insert_ogco(
   p_ogpr      IN NUMBER,
   p_cod_fiscale   IN VARCHAR2,
   p_anno      IN NUMBER,
   p_data_dec      IN DATE,
   p_ogpr_rif   IN NUMBER,
   p_utente   IN VARCHAR2) RETURN number
    IS
      CURSOR sel_ogco(p_ogpr number, p_cod_fiscale varchar2)
      IS
      select  *
         from oggetti_contribuente
        where oggetto_pratica = p_ogpr
          and cod_fiscale    = p_cod_fiscale
      ;
    BEGIN
      FOR rec_ogco IN sel_ogco(p_ogpr_rif,p_cod_fiscale) LOOP
         BEGIN
            insert into OGGETTI_CONTRIBUENTE
            (cod_fiscale,oggetto_pratica,anno,tipo_rapporto,
             inizio_occupazione,data_decorrenza,
             perc_possesso,mesi_possesso,mesi_possesso_1sem,
             mesi_esclusione,mesi_riduzione,mesi_aliquota_ridotta,
             detrazione,flag_possesso,flag_esclusione,
             flag_riduzione,flag_ab_principale,flag_al_ridotta,
             utente,note)
                VALUES (p_cod_fiscale,p_ogpr,p_anno,rec_ogco.tipo_rapporto,
               p_data_dec,p_data_dec,
               rec_ogco.perc_possesso,rec_ogco.mesi_possesso,rec_ogco.mesi_possesso_1sem,
               rec_ogco.mesi_esclusione,rec_ogco.mesi_riduzione,rec_ogco.mesi_aliquota_ridotta,
               rec_ogco.detrazione,rec_ogco.flag_possesso,rec_ogco.flag_esclusione,
               rec_ogco.flag_riduzione,rec_ogco.flag_ab_principale,rec_ogco.flag_al_ridotta,
               p_utente, 'Variazione Automatica del '||to_char(sysdate,'dd/mm/yyyy'))
            ;
         EXCEPTION
            WHEN OTHERS THEN
                RAISE;
                 RETURN -1;
         END;
      END LOOP;
      RETURN 0;
END f_insert_ogco;
--
-- f_insert_paog
--
FUNCTION f_insert_paog(
   p_ogpr      IN NUMBER,
   p_ogpr_rif   IN NUMBER
 ) RETURN number
    IS
      CURSOR sel_paog(p_ogpr number)
      IS
      select  *
         from partizioni_oggetto_pratica
        where oggetto_pratica = p_ogpr
      ;
    BEGIN
      FOR rec_paog IN sel_paog(p_ogpr_rif) LOOP
         BEGIN
             insert into partizioni_oggetto_pratica
            values  (p_ogpr,
                    rec_paog.SEQUENZA  ,
                    rec_paog.TIPO_AREA         ,
                    rec_paog.NUMERO             ,
                    rec_paog.CONSISTENZA_REALE  ,
                    rec_paog.CONSISTENZA       ,
                    rec_paog.FLAG_ESENZIONE     ,
                    rec_paog.NOTE )
            ;
         EXCEPTION
            WHEN OTHERS THEN
                RAISE;
                 RETURN -1;
         END;
      END LOOP;
      RETURN 0;
END f_insert_paog;
--
-- f_exists_tari
--
FUNCTION f_exists_tari(p_anno number, p_tributo number, p_categoria number, p_tipo_tariffa number)
  RETURN number
   IS
   w_dummy      number;
    BEGIN
      select 1 into w_dummy
        from tariffe
       where TRIBUTO      = p_tributo
         and CATEGORIA   = p_categoria
         and anno      = p_anno
         and tipo_tariffa   = p_tipo_tariffa
      ;
      RETURN 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
           RETURN 0;
      WHEN OTHERS THEN
          RAISE;
           RETURN -1;
END f_exists_tari;
--
-- insert_variazioni
--
procedure insert_variazioni (
   p_pratica                NUMBER,
   p_oggetto_pratica        NUMBER,
   p_oggetto_pratica_rif    NUMBER,
   p_anno                   NUMBER,
   p_data_denuncia          DATE,
   p_data_decorrenza        DATE,
   p_cod_fiscale            VARCHAR2,
   p_a_categoria            NUMBER,
   p_a_tariffa              NUMBER,
   p_utente                 VARCHAR2
)
IS
 w_new_prtr   number;
 w_new_ogpr   number;
--
 BEGIN
   a_messaggio := '';
   --
   w_retcode := f_insert_prtr(w_new_prtr,p_pratica,p_anno,p_data_denuncia,p_utente);
       IF 0 > w_retcode THEN
          w_errore := 'Errore in Inserimento in Pratiche Tributo '||'('||SQLERRM||')';
          RAISE errore;
       ELSE  -- Si inserisce il contribuente in RAPPORTI_TRIBUTO
       -- dbms_output.put_line ('Nuova pratica : ' || w_new_prtr);
          --
          BEGIN
            INSERT INTO RAPPORTI_TRIBUTO(PRATICA, COD_FISCALE, TIPO_RAPPORTO)
                   VALUES (w_new_prtr, p_cod_fiscale, DENUNCIA)
            ;
          EXCEPTION
            WHEN OTHERS THEN
                 w_errore := 'Errore in Inserimento Rapporti Tributi  '||'('||SQLERRM||')';
                 RAISE errore;
          END;
          w_retcode := f_insert_ogpr(w_new_ogpr,w_new_prtr,p_anno,p_a_categoria,p_a_tariffa,
                                                    p_oggetto_pratica_rif,p_oggetto_pratica,p_utente);
             IF 0 > w_retcode THEN
                  w_errore := 'Errore in Inserimento Oggetto Pratica'||'('||SQLERRM||')';
                      RAISE errore;
             ELSE
                     w_retcode := f_insert_ogco(w_new_ogpr,p_cod_fiscale,p_anno,p_data_decorrenza,
                     p_oggetto_pratica,p_utente);
               IF 0 > w_retcode THEN
               w_errore := 'Errore in Inserimento Oggetto Contribuente'||'('||SQLERRM||')';
                     RAISE errore;
               ELSE
                    w_retcode := f_insert_paog(w_new_ogpr,p_oggetto_pratica);
                     IF 0 > w_retcode THEN
                            w_errore := 'Errore in Inserimento Partizioni Oggetto'||'('||SQLERRM||')';
                     RAISE errore;
                     END IF;
               END IF;
             END IF;
       END IF;
    END;
-----------------------------------------------------------
-- F_DENUNCE_V_AUTOMATICHE
-----------------------------------------------------------
BEGIN
   w_messaggio := '';
   w_retcode := 0;
   --
   w_contatore := 0;
   w_elaborati := 0;
   --
   for rec_ogva in sel_ogva(a_tipo_tributo, a_tributo, a_da_categoria, a_da_tariffa,
                             a_data_decorrenza, a_cod_via, a_cod_fiscale)
      LOOP
      w_contatore := w_contatore + 1;
      --
   -- dbms_output.put_line ('Variazione oggetto '||w_contatore);
      --
      w_a_tariffa := nvl(a_a_tariffa,rec_ogva.tipo_tariffa);
      w_check := f_exists_tari(a_anno, a_tributo, a_a_categoria, w_a_tariffa);
         IF w_check = 1 THEN
            insert_variazioni (rec_ogva.pratica, rec_ogva.oggetto_pratica,
                               rec_ogva.oggetto_pratica_rif,
                               a_anno, a_data_denuncia, a_data_decorrenza, rec_ogva.cod_fiscale,
                               a_a_categoria, a_a_tariffa, a_utente);
            w_elaborati := w_elaborati + 1;
         ELSIF w_check = 0 THEN
             RAISE no_tari;
         ELSE
             RAISE ric_tari;
         END IF;
    END LOOP;
  --
  w_messaggio := 'Elaborato '||w_contatore||' su '||w_elaborati||' oggetti.';
  a_messaggio := w_messaggio;
  --
--dbms_output.put_line(w_messaggio);
  --
  return w_retcode;
  --
EXCEPTION
  WHEN no_tari THEN
    w_errore := 'Errore non esiste la tariffa: '||a_a_tariffa||' per l''anno: '||a_anno
      ||' categoria: '||a_a_categoria||' e tributo: '||a_tributo;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore,TRUE);
  WHEN ric_tari THEN
    w_errore := 'Errore nella ricerca della tariffa: '||a_a_tariffa||' per l''anno: '||a_anno
      ||' categoria: '||a_a_categoria||' e tributo: '||a_tributo||' ('||SQLERRM||')';
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore,TRUE);
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore,TRUE);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR
   (-20999,'Errore in VARIAZIONI_AUTOMATICHE '||'('||SQLERRM||')',TRUE);
END;
/* End Function: F_DENUNCE_V_AUTOMATICHE */
/
