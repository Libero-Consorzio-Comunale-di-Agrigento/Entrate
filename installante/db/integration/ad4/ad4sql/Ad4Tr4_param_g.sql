--liquibase formatted sql
--changeset dmarotta:20250904_121251_Ad4Tr4_param_g stripComments:false runOnChange:true

grant all on registro to ${targetUsername};
grant execute on key_error_log_pkg to ${targetUsername};
grant execute on AD4_REGISTRO_UTILITY to ${targetUsername};
