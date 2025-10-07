--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_determina_tipo_evento stripComments:false runOnChange:true 
 
CREATE OR REPLACE FUNCTION     F_DETERMINA_TIPO_EVENTO
(a_pratica IN NUMBER)
  RETURN VARCHAR2 IS

  w_tipo_violazione VARCHAR2(2);

BEGIN

  select coalesce(
                  -- Omessa/Infedele denuncia
                  prtr.tipo_violazione,
                  -- Tardiva denuncia
                  (select decode(count(*), 0, null, 'TD')
                     from sanzioni_pratica sapr, sanzioni sanz
                    where sapr.cod_sanzione = sanz.cod_sanzione
                      and sapr.sequenza_sanz = sanz.sequenza
                      and sapr.tipo_tributo = sanz.tipo_tributo
                      and sapr.pratica = prtr.pratica
                      and prtr.tipo_violazione is null
                      and sanz.tipo_causale = 'T'
                      and prtr.tipo_evento in ('U', 'T')),
                  -- Omesso/Parziale versamento
                  (select decode(count(*), 0, null, 'OV')
                     from sanzioni_pratica sapr, sanzioni sanz
                    where sapr.cod_sanzione = sanz.cod_sanzione
                      and sapr.sequenza_sanz = sanz.sequenza
                      and sapr.tipo_tributo = sanz.tipo_tributo
                      and sapr.pratica = prtr.pratica
                      and prtr.tipo_violazione is null
                      and sanz.tipo_causale = 'O'),
                  -- Tardivo versamento
                  (select decode(count(*), 0, null, 'TV')
                     from sanzioni_pratica sapr, sanzioni sanz
                    where sapr.cod_sanzione = sanz.cod_sanzione
                      and sapr.sequenza_sanz = sanz.sequenza
                      and sapr.tipo_tributo = sanz.tipo_tributo
                      and sapr.pratica = prtr.pratica
                      and prtr.tipo_violazione is null
                      and sanz.tipo_causale in ('T', 'TP30')
                      and prtr.tipo_evento = 'A'),
                  'AL')
    into w_tipo_violazione
    from pratiche_tributo prtr
   where prtr.pratica = a_pratica;

  RETURN w_tipo_violazione;
END;
/* End Function: F_DETERMINA_TIPO_EVENTO */
/
