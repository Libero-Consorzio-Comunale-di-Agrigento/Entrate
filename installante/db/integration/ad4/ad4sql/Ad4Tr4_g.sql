--liquibase formatted sql
--changeset dmarotta:20250326_152438_Ad4Tr4_g stripComments:false
--validCheckSum: 1:any

grant all on AD4_BANCHE to ${targetUsername};
grant all on AD4_COMUNI to ${targetUsername};
grant all on AD4_COMUNI_TOTALI to ${targetUsername};
grant all on AD4_CONSOLATI to ${targetUsername};
grant all on AD4_DIRITTI_ACCESSO to ${targetUsername};
grant all on AD4_DISABILITAZIONI to ${targetUsername};
grant all on AD4_ENTI to ${targetUsername};
grant all on AD4_GRUPPI_LINGUISTICI to ${targetUsername};
grant all on AD4_ISTANZE to ${targetUsername};
grant all on AD4_MODULI to ${targetUsername};
grant all on AD4_PERSONALIZZAZIONI to ${targetUsername};
grant all on AD4_PROGETTI to ${targetUsername};
grant all on AD4_PROVINCIE to ${targetUsername};
grant all on AD4_PROVINCE to ${targetUsername};
grant all on AD4_RAGGRUPPAMENTI_STATI to ${targetUsername};
grant all on AD4_REGIONI to ${targetUsername};
grant all on AD4_RUOLI to ${targetUsername};
grant all on AD4_SPORTELLI to ${targetUsername};
grant all on AD4_STATI_TERRITORI to ${targetUsername};
grant all on AD4_UTENTI to ${targetUsername};
grant all on AD4_UTENTI_GRUPPO to ${targetUsername};
grant all on AD4_VISTA_COMUNI_STORICI to ${targetUsername};
