--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_ultimo_ruolo stripComments:false runOnChange:true 
 
create or replace function F_GET_ULTIMO_RUOLO
(p_cod_fiscale       varchar2,
 p_anno              number,
 p_titr              varchar2,
 p_tipo_emissione    varchar2,
 p_tipo_ruolo        varchar2 default 'S',
 p_check_data_invio  varchar2 default null,
 p_specie_ruolo      number default null)
   RETURN NUMBER
IS
/******************************************************************************
   Ritorna (se esiste) il ruolo piu' recente con lo stesso tipo emissione.
   Prima del 2013 e per ruoli in acconto restituisce null.
   Se specificato il codice fiscale, cerca solo tra i ruoli di quel
   contribuente.
   Non controlla la data di invio perchè si tratta di una funzione
   utilizzata da eliminazione_ruolo e si possono eliminare solo
   ruoli non inviati.
   P_COD_FISCALE: % = tutti i contribuenti
 Rev.    Date         Author      Note
 004     08/05/2023   VM          Aggiunto controllo su specie ruolo
 003     17/12/2020   VD          Aggiunto controllo su tipo ruolo e tipo
                                  emissione: se tipo ruolo = 'S' (suppletivo)
                                  occorre considerare solo i ruoli aventi lo
                                  stesso tipo emissione del ruolo passato;
                                  se tipo ruolo = 'P' (principale) occorre
                                  considerare solo i ruoli principali con
                                  tipo emissione 'T' o 'A'.
 002     24/11/2020   VD          Aggiunto parametro per indicare se controllare
                                  la data invio consorzio oppure no.
                                  La funzione ora viene utilizzata anche nel
                                  passaggio a PAGOPA, quindi serve sapere
                                  l'ultimo ruolo inviato.
                                  Se p_check_data_invio = 'S' occorre verificare
                                  solo i ruoli con invio_consorzio non nulla.
 001     20/04/2015   VD          Aggiunta condizione di where sul tipo tributo
                                  in entrambi i cursori utilizzati
******************************************************************************/
   w_ruolo            NUMBER;
   w_tipo_emissione   VARCHAR2 (1) := NVL (p_tipo_emissione, 'T');
   w_tipo_ruolo       VARCHAR2 (1) := nvl (p_tipo_ruolo, 'S');
   CURSOR sel_ruolo_cf (
      a_tipo_emissione    VARCHAR2,
      a_tipo_ruolo        VARCHAR2,
      a_check_data_invio  VARCHAR2)
   IS
        SELECT ruoli.ruolo
          FROM ruoli, ruoli_contribuente ruco
         WHERE ((a_tipo_ruolo = 'P' and NVL(ruoli.tipo_emissione,'T') in ('A','T')) or
                (a_tipo_ruolo = 'S' and NVL (ruoli.tipo_emissione, 'T') = a_tipo_emissione))
               AND ruoli.ruolo = ruco.ruolo
               AND ruco.cod_fiscale = p_cod_fiscale
               AND ruoli.anno_ruolo = p_anno
               AND ruoli.tipo_tributo = p_titr
               AND (a_check_data_invio is null or
                   (a_check_data_invio = 'S' and ruoli.invio_consorzio is not null))
               AND nvl(p_specie_ruolo, ruoli.specie_ruolo) = ruoli.specie_ruolo
      ORDER BY ruoli.data_emissione DESC;
   CURSOR sel_ruolo (
      a_tipo_emissione    VARCHAR2,
      a_tipo_ruolo        VARCHAR2,
      a_check_data_invio  VARCHAR2)
   IS
        SELECT ruoli.ruolo
          FROM ruoli
         WHERE ((a_tipo_ruolo = 'P' and NVL(ruoli.tipo_emissione,'T') in ('A','T')) or
                (a_tipo_ruolo = 'S' and NVL (ruoli.tipo_emissione, 'T') = a_tipo_emissione))
               AND ruoli.anno_ruolo = p_anno
               AND ruoli.tipo_tributo = p_titr
               AND (a_check_data_invio is null or
                   (a_check_data_invio = 'S' and ruoli.invio_consorzio is not null))
               AND nvl(p_specie_ruolo, ruoli.specie_ruolo) = ruoli.specie_ruolo
      ORDER BY ruoli.data_emissione DESC
             , ruoli.ruolo desc;
BEGIN
   w_ruolo := NULL;
   IF p_titr = 'TARSU' AND p_anno >= 2013 AND w_tipo_emissione != 'A'
   THEN
      /* ho bisogno di estrarre un solo ruolo totale (se c'è) e vorrei estrarre
         l'ultimo emesso. Per questo ho usato un cursore da cui leggo solo la prima
         riga, in questo modo evito una subquery per estrarre la max data
        Prima del 2013 dobbiamo prendere tutti i ruoli perchè il ruolo totale
        non esisteva
      */
      IF p_cod_fiscale IS NULL
      THEN
         OPEN sel_ruolo (w_tipo_emissione, w_tipo_ruolo, p_check_data_invio);
         FETCH sel_ruolo INTO w_ruolo;
         CLOSE sel_ruolo;
      ELSE
         OPEN sel_ruolo_cf (w_tipo_emissione, w_tipo_ruolo, p_check_data_invio);
         FETCH sel_ruolo_cf INTO w_ruolo;
         CLOSE sel_ruolo_cf;
      END IF;
   END IF;
   RETURN w_ruolo;
END;
/* End Function: F_GET_ULTIMO_RUOLO */
/
