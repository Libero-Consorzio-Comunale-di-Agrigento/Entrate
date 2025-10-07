--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ricalcolo_tasi_per_affitto stripComments:false runOnChange:true 
 
create or replace function F_RICALCOLO_TASI_PER_AFFITTO
(  p_tipo_tributo                        VARCHAR2,
   p_tipo_rapporto                       VARCHAR2,
   p_oggetto_pratica                     NUMBER,
   p_immobile_occupato                   VARCHAR2,
   p_ravvedimento                        VARCHAR2,
   p_cod_fiscale                         VARCHAR2,
   p_anno_rif                            NUMBER,
   p_percentuale                IN OUT   NUMBER,
   p_imposta                    IN OUT   NUMBER,
   p_imposta_acconto            IN OUT   NUMBER,
   p_imposta_erariale           IN OUT   NUMBER,
   p_imposta_erariale_acconto   IN OUT   NUMBER
)
   RETURN BOOLEAN
AS
   p_ricalcolata   BOOLEAN := FALSE;
   errore                        exception;
   w_errore                      varchar2(2000);
BEGIN
/* Calcola gli imposti passati per reference se il tipo tributo è TASI
e se si tratta di un occupante o di un proprietario il cui immobile è stato
affittato durante p_anno_rif */
   IF p_tipo_tributo = 'TASI'
   THEN
      IF p_tipo_rapporto = 'A'
      THEN
         p_ricalcolata := TRUE;
      ELSE
-- 30/04/2014 SC calcolo solo su indicazione forzata di immobile occupato.
         IF /*f_get_mesi_affitto (p_oggetto_pratica,
                                p_cod_fiscale,
                                p_anno_rif,
                                p_ravvedimento
                               ) > 0 or */ nvl(p_immobile_occupato, 'N') = 'S'
         THEN
            p_ricalcolata := TRUE;
            p_percentuale := (100 - p_percentuale);
         END IF;
      END IF;
   END IF;
   IF p_ricalcolata
   THEN
      p_imposta := ROUND (p_imposta * p_percentuale / 100, 2);
      p_imposta_acconto := ROUND (p_imposta_acconto * p_percentuale / 100, 2);
      p_imposta_erariale :=
                          ROUND (p_imposta_erariale * p_percentuale / 100, 2);
      p_imposta_erariale_acconto :=
                  ROUND (p_imposta_erariale_acconto * p_percentuale / 100, 2);
   END IF;
   return p_ricalcolata;
END;
/* End Function: F_RICALCOLO_TASI_PER_AFFITTO */
/

