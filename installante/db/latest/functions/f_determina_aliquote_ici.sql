--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_determina_aliquote_ici stripComments:false runOnChange:true 
 
create or replace function F_DETERMINA_ALIQUOTE_ICI
(a_anno_rif                   in     number
,a_aliquota_base              in out number
,a_aliquota_base_prec         in out number
,a_aliquota_base_erar         in out number
,a_tipo_al_base               in out number
,a_tipo_al_base_prec          in out number
,a_al_ab_principale           in out number
,a_al_ab_principale_prec      in out number
,a_al_ab_principale_erar      in out number
,a_tipo_al_ab_principale      in out number
,a_tipo_al_ab_principale_prec in out number
,a_al_affittato               in out number
,a_al_affittato_prec          in out number
,a_al_affittato_erar          in out number
,a_tipo_al_affittato          in out number
,a_tipo_al_affittato_prec     in out number
,a_al_non_affittato           in out number
,a_al_non_affittato_prec      in out number
,a_al_non_affittato_erar      in out number
,a_tipo_al_non_affittato      in out number
,a_tipo_al_non_affittato_prec in out number
,a_al_seconda_casa            in out number
,a_al_seconda_casa_prec       in out number
,a_al_seconda_casa_erar       in out number
,a_tipo_al_seconda_casa       in out number
,a_tipo_al_seconda_casa_prec  in out number
,a_al_negozio                 in out number
,a_al_negozio_prec            in out number
,a_al_negozio_erar            in out number
,a_tipo_al_negozio            in out number
,a_tipo_al_negozio_prec       in out number
,a_al_d                 in out number
,a_al_d_prec            in out number
,a_al_d_erar            in out number
,a_tipo_al_d            in out number
,a_tipo_al_d_prec       in out number
,a_al_d10                 in out number
,a_al_d10_prec            in out number
,a_al_d10_erar            in out number
,a_tipo_al_d10            in out number
,a_tipo_al_d10_prec       in out number
,a_al_terreni                 in out number
,a_al_terreni_prec            in out number
,a_al_terreni_erar            in out number
,a_tipo_al_terreni            in out number
,a_tipo_al_terreni_prec       in out number
,a_al_terreni_rid             in out number
,a_al_terreni_rid_prec        in out number
,a_al_terreni_rid_erar        in out number
,a_tipo_al_terreni_rid        in out number
,a_tipo_al_terreni_rid_prec   in out number
,a_al_aree                    in out number
,a_al_aree_prec               in out number
,a_al_aree_erar               in out number
,a_tipo_al_aree               in out number
,a_tipo_al_aree_prec          in out number
,a_aliquota_base_std          in out number
,a_al_ab_principale_std       in out number
,a_al_affittato_std           in out number
,a_al_non_affittato_std       in out number
,a_al_seconda_casa_std        in out number
,a_al_negozio_std             in out number
,a_al_d_std                   in out number
,a_al_d10_std                 in out number
,a_al_terreni_rid_std         in out number
,a_perc_acconto               in out number
,a_errore                     in out varchar2
) return number is
errore                       exception;
w_errore                     varchar2(200);
w_aliquota_base              number;
w_aliquota_base_prec         number;
w_aliquota_base_b            number;
w_aliquota_base_erar         number;
w_tipo_al_base               number := 1;
w_tipo_al_base_prec          number := 1;
w_al_ab_principale           number;
w_al_ab_principale_prec      number;
w_al_ab_principale_b         number;
w_al_ab_principale_erar      number;
w_tipo_al_ab_principale      number := 2;
w_tipo_al_ab_principale_prec number := 2;
w_al_affittato               number;
w_al_affittato_prec          number;
w_al_affittato_b             number;
w_al_affittato_erar          number;
w_tipo_al_affittato          number := 3;
w_tipo_al_affittato_prec     number := 3;
w_al_non_affittato           number;
w_al_non_affittato_prec      number;
w_al_non_affittato_b         number;
w_al_non_affittato_erar      number;
w_tipo_al_non_affittato      number := 4;
w_tipo_al_non_affittato_prec number := 4;
w_al_seconda_casa            number;
w_al_seconda_casa_prec       number;
w_al_seconda_casa_b          number;
w_al_seconda_casa_erar       number;
w_tipo_al_seconda_casa       number := 10;
w_tipo_al_seconda_casa_prec  number := 10;
w_al_negozio                 number;
w_al_negozio_prec            number;
w_al_negozio_b               number;
w_al_negozio_erar            number;
w_tipo_al_negozio            number := 5;
w_tipo_al_negozio_prec       number := 5;
w_al_d                   number;
w_al_d_prec              number;
w_al_d_b                 number;
w_al_d_erar              number;
w_tipo_al_d              number := 9;
w_tipo_al_d_prec         number := 9;
w_al_d10                 number;
w_al_d10_prec            number;
w_al_d10_b               number;
w_al_d10_erar            number;
w_tipo_al_d10            number := 11;
w_tipo_al_d10_prec       number := 11;
w_al_terreni                 number;
w_al_terreni_prec            number;
w_al_terreni_b               number;
w_al_terreni_erar            number;
w_tipo_al_terreni            number := 51;
w_tipo_al_terreni_Prec       number := 51;
w_al_terreni_rid             number;
w_al_terreni_rid_Prec        number;
w_al_terreni_rid_b           number;
w_al_terreni_rid_erar        number;
w_tipo_al_terreni_rid        number := 52;
w_tipo_al_terreni_rid_prec   number := 52;
w_al_aree                    number;
w_al_aree_prec               number;
w_al_aree_b                  number;
w_al_aree_erar               number;
w_tipo_al_aree               number := 53;
w_tipo_al_aree_prec          number := 53;
w_perc_acconto               number;
w_aliquota_base_std          number;
w_al_ab_principale_std       number;
w_al_affittato_std           number;
w_al_non_affittato_std       number;
w_al_seconda_casa_std        number;
w_al_negozio_std             number;
w_al_d_std                   number;
w_al_d10_std                 number;
w_al_terreni_rid_std         number;
BEGIN
   BEGIN
      select aliquota
           , aliquota_base
           , aliquota_erariale
           , aliquota_std
        into w_aliquota_base
           , w_aliquota_base_b
           , w_aliquota_base_erar
           , w_aliquota_base_std
        from aliquote
       where tipo_aliquota   = 1
         and anno            = a_anno_rif
         and tipo_tributo    = 'ICI'
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Base per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_aliquota_base_prec
           from aliquote
          where tipo_aliquota   = 1
            and anno            = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Base per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
      END;
   else
      w_aliquota_base_prec := w_aliquota_base;
   end if;
   w_aliquota_base_prec := nvl(w_aliquota_base_b,w_aliquota_base_prec);
   BEGIN
      select aliquota
           , aliquota_base
           , aliquota_erariale
           , aliquota_std
        into w_al_ab_principale
           , w_al_ab_principale_b
           , w_al_ab_principale_erar
           , w_al_ab_principale_std
        from aliquote
       where flag_ab_principale   is not null
         and anno                    = a_anno_rif
         and tipo_tributo    = 'ICI'
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Ab. Principale per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_al_ab_principale_prec
           from aliquote
          where flag_ab_principale   is not null
            and anno                  = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Ab. Principale per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
      END;
   else
      w_al_ab_principale_prec := w_al_ab_principale;
   end if;
   w_al_ab_principale_prec := nvl(w_al_ab_principale_b,w_al_ab_principale_prec);
/*
   Le seguenti Aliquote e Tipi Aliquota se non indicate si riferiscono alla base.
*/
   BEGIN
      select aliquota
           , aliquota_base
           , aliquota_erariale
           , aliquota_std
        into w_al_affittato
           , w_al_affittato_b
           , w_al_affittato_erar
           , w_al_affittato_std
        from aliquote
       where tipo_aliquota   = 3
         and anno            = a_anno_rif
         and tipo_tributo    = 'ICI'
      ;
   EXCEPTION
      WHEN no_data_found then
         w_al_affittato      := w_aliquota_base;
         w_tipo_al_affittato := w_tipo_al_base;
         w_al_affittato_b    := w_aliquota_base_b;
         w_al_affittato_erar := w_aliquota_base_erar;
         w_al_affittato_std  := w_aliquota_base_std;
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Abitazione Affittata per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_al_affittato_prec
           from aliquote
          where tipo_aliquota   = 3
            and anno            = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN no_data_found then
            w_al_affittato_prec      := w_aliquota_base_prec;
            w_tipo_al_affittato_prec := w_tipo_al_base_prec;
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Abitazione Affittata per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
      END;
   else
      w_al_affittato_prec      := w_al_affittato;
      w_tipo_al_affittato_prec := w_tipo_al_affittato;
   end if;
   w_al_affittato_prec := nvl(w_al_affittato_b,w_al_affittato_prec);
   BEGIN
      select aliquota
           , aliquota_base
           , aliquota_erariale
           , aliquota_std
        into w_al_non_affittato
           , w_al_non_affittato_b
           , w_al_non_affittato_erar
           , w_al_non_affittato_std
        from aliquote
       where tipo_aliquota   = 4
         and anno            = a_anno_rif
         and tipo_tributo    = 'ICI'
      ;
   EXCEPTION
      WHEN no_data_found then
         w_al_non_affittato      := w_aliquota_base;
         w_tipo_al_non_affittato := w_tipo_al_base;
         w_al_non_affittato_b    := w_aliquota_base_b;
         w_al_non_affittato_erar := w_aliquota_base_erar;
         w_al_non_affittato_std  := w_aliquota_base_std;
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Abitazione Non Affittata per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_al_non_affittato_prec
           from aliquote
          where tipo_aliquota   = 4
            and anno            = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN no_data_found then
            w_al_non_affittato_prec      := w_aliquota_base_prec;
            w_tipo_al_non_affittato_prec := w_tipo_al_base_prec;
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Abitazione Non Affittata per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
      END;
   else
      w_al_non_affittato_prec      := w_al_non_affittato;
      w_tipo_al_non_affittato_prec := w_tipo_al_non_affittato;
   end if;
   w_al_non_affittato_prec := nvl(w_al_non_affittato_b,w_al_non_affittato_prec);
   BEGIN
      select aliquota
           , aliquota_base
           , aliquota_erariale
           , aliquota_std
        into w_al_seconda_casa
           , w_al_seconda_casa_b
           , w_al_seconda_casa_erar
           , w_al_seconda_casa_std
        from aliquote
       where tipo_aliquota        = 10
         and anno                 = a_anno_rif
         and tipo_tributo    = 'ICI'
      ;
   EXCEPTION
      WHEN no_data_found then
         w_al_seconda_casa      := w_aliquota_base;
         w_tipo_al_seconda_casa := w_tipo_al_base;
         w_al_seconda_casa_b    := w_aliquota_base_b;
         w_al_seconda_casa_erar := w_aliquota_base_erar;
         w_al_seconda_casa_std  := w_aliquota_base_std;
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Seconda Abitazione per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
          select aliquota
            into w_al_seconda_casa_prec
            from aliquote
           where tipo_aliquota   = 10
             and anno            = a_anno_rif - 1
             and tipo_tributo    = 'ICI'
          ;
      EXCEPTION
          WHEN no_data_found then
             w_al_seconda_casa_prec      := w_aliquota_base_prec;
             w_tipo_al_seconda_casa_prec := w_tipo_al_base_prec;
          WHEN others THEN
             w_errore := 'Errore in ricerca Aliquota Seconda Abitazione per Anno '||
                         to_char(a_anno_rif - 1);
             RAISE errore;
      END;
   else
      w_al_seconda_casa_prec      := w_al_seconda_casa;
      w_tipo_al_seconda_casa_prec := w_tipo_al_seconda_casa;
   end if;
   w_al_seconda_casa_prec := nvl(w_al_seconda_casa_b,w_al_seconda_casa_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
            , aliquota_std
         into w_al_negozio
            , w_al_negozio_b
            , w_al_negozio_erar
            , w_al_negozio_std
         from aliquote
        where tipo_aliquota   = 5
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
       WHEN no_data_found then
          w_al_negozio      := w_aliquota_base;
          w_tipo_al_negozio := w_tipo_al_base;
          w_al_negozio_b    := w_aliquota_base_b;
          w_al_negozio_erar := w_aliquota_base_erar;
          w_al_negozio_std  := w_aliquota_base_std;
       WHEN others THEN
          w_errore := 'Errore in ricerca Aliquota Negozi per Anno '||
                      to_char(a_anno_rif);
          RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
          select aliquota
            into w_al_negozio_prec
            from aliquote
           where tipo_aliquota   = 5
             and anno            = a_anno_rif - 1
             and tipo_tributo    = 'ICI'
          ;
      EXCEPTION
          WHEN no_data_found then
             w_al_negozio_prec      := w_aliquota_base_prec;
             w_tipo_al_negozio_prec := w_tipo_al_base_prec;
          WHEN others THEN
             w_errore := 'Errore in ricerca Aliquota Negozi per Anno '||
                         to_char(a_anno_rif - 1);
             RAISE errore;
      END;
   else
      w_al_negozio_prec      := w_al_negozio;
      w_tipo_al_negozio_prec := w_tipo_al_negozio;
   end if;
   w_al_negozio_prec := nvl(w_al_negozio_b,w_al_negozio_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
            , aliquota_std
         into w_al_d
            , w_al_d_b
            , w_al_d_erar
            , w_al_d_std
         from aliquote
        where tipo_aliquota   = 9
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
       WHEN no_data_found then
          w_al_d      := w_aliquota_base;
          w_tipo_al_d := w_tipo_al_base;
          w_al_d_b    := w_aliquota_base_b;
          w_al_d_erar := w_aliquota_base_erar;
          w_al_d_std  := w_aliquota_base_std;
       WHEN others THEN
          w_errore := 'Errore in ricerca Aliquota Fabbricati D per Anno '||
                      to_char(a_anno_rif);
          RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
          select aliquota
            into w_al_d_prec
            from aliquote
           where tipo_aliquota   = 9
             and anno            = a_anno_rif - 1
             and tipo_tributo    = 'ICI'
          ;
      EXCEPTION
          WHEN no_data_found then
             w_al_d_prec      := w_aliquota_base_prec;
             w_tipo_al_d_prec := w_tipo_al_base_prec;
          WHEN others THEN
             w_errore := 'Errore in ricerca Aliquota Fabbricati D per Anno '||
                         to_char(a_anno_rif - 1);
             RAISE errore;
      END;
   else
      w_al_d_prec      := w_al_d;
      w_tipo_al_d_prec := w_tipo_al_d;
   end if;
   w_al_d_prec := nvl(w_al_d_b,w_al_d_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
            , aliquota_std
         into w_al_d10
            , w_al_d10_b
            , w_al_d10_erar
            , w_al_d10_std
         from aliquote
        where tipo_aliquota   = 11
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
       WHEN no_data_found then
          w_al_d10      := w_aliquota_base;
          w_tipo_al_d10 := w_tipo_al_base;
          w_al_d10_b    := w_aliquota_base_b;
          w_al_d10_erar := w_aliquota_base_erar;
          w_al_d10_std  := w_aliquota_base_std;
       WHEN others THEN
          w_errore := 'Errore in ricerca Aliquota Fabbricati D10 per Anno '||
                      to_char(a_anno_rif);
          RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
          select aliquota
            into w_al_d10_prec
            from aliquote
           where tipo_aliquota   = 11
             and anno            = a_anno_rif - 1
             and tipo_tributo    = 'ICI'
          ;
      EXCEPTION
          WHEN no_data_found then
             w_al_d10_prec      := w_aliquota_base_prec;
             w_tipo_al_d10_prec := w_tipo_al_base_prec;
          WHEN others THEN
             w_errore := 'Errore in ricerca Aliquota Fabbricati D10 per Anno '||
                         to_char(a_anno_rif - 1);
             RAISE errore;
      END;
   else
      w_al_d10_prec      := w_al_d10;
      w_tipo_al_d10_prec := w_tipo_al_d10;
   end if;
   w_al_d10_prec := nvl(w_al_d10_b,w_al_d10_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
         into w_al_terreni
            , w_al_terreni_b
            , w_al_terreni_erar
         from aliquote
        where tipo_aliquota   = 51
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
       WHEN no_data_found then
          w_al_terreni      := w_aliquota_base;
          w_tipo_al_terreni := w_tipo_al_base;
          w_al_terreni_b    := w_aliquota_base_b;
          w_al_terreni_erar := w_aliquota_base_erar;
       WHEN others THEN
          w_errore := 'Errore in ricerca Aliquota Terreni per Anno '||
                      to_char(a_anno_rif);
          RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
          select aliquota
            into w_al_terreni_prec
            from aliquote
           where tipo_aliquota   = 51
             and anno            = a_anno_rif - 1
             and tipo_tributo    = 'ICI'
          ;
      EXCEPTION
          WHEN no_data_found then
             w_al_terreni_prec      := w_aliquota_base_prec;
             w_tipo_al_terreni_prec := w_tipo_al_base_prec;
          WHEN others THEN
             w_errore := 'Errore in ricerca Aliquota Terreni per Anno '||
                         to_char(a_anno_rif - 1);
             RAISE errore;
      END;
   end if;
   w_al_terreni_prec := nvl(w_al_terreni_b,w_al_terreni_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
            , aliquota_std
         into w_al_terreni_rid
            , w_al_terreni_rid_b
            , w_al_terreni_rid_erar
            , w_al_terreni_rid_std
         from aliquote
        where tipo_aliquota   = 52
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
       WHEN no_data_found then
          w_al_terreni_rid      := w_al_terreni;
          w_tipo_al_terreni_rid := w_tipo_al_terreni;
          w_al_terreni_rid_b    := w_al_terreni_b;
          w_al_terreni_rid_erar := w_al_terreni_erar;
          w_al_terreni_rid_std  := null;
       WHEN others THEN
          w_errore := 'Errore in ricerca Aliquota Terreni Ridotti per Anno '||
                      to_char(a_anno_rif);
          RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_al_terreni_rid_prec
           from aliquote
          where tipo_aliquota   = 52
            and anno            = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN no_data_found then
            w_al_terreni_rid_prec      := w_al_terreni_prec;
            w_tipo_al_terreni_rid_prec := w_tipo_al_terreni_prec;
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Terreni Ridotti per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
       END;
   end if;
   w_al_terreni_rid_prec := nvl(w_al_terreni_rid_b,w_al_terreni_rid_prec);
   BEGIN
       select aliquota
            , aliquota_base
            , aliquota_erariale
         into w_al_aree
            , w_al_aree_b
            , w_al_aree_erar
         from aliquote
        where tipo_aliquota   = 53
          and anno            = a_anno_rif
          and tipo_tributo    = 'ICI'
       ;
   EXCEPTION
      WHEN no_data_found then
         w_al_aree      := w_aliquota_base;
         w_tipo_al_aree := w_tipo_al_base;
         w_al_aree_b    := w_aliquota_base_b;
         w_al_aree_erar := w_aliquota_base_erar;
      WHEN others THEN
         w_errore := 'Errore in ricerca Aliquota Aree per Anno '||
                     to_char(a_anno_rif);
         RAISE errore;
   END;
   if a_anno_rif > 2000 then
      BEGIN
         select aliquota
           into w_al_aree_prec
           from aliquote
          where tipo_aliquota   = 53
            and anno            = a_anno_rif - 1
            and tipo_tributo    = 'ICI'
         ;
      EXCEPTION
         WHEN no_data_found then
            w_al_aree_prec      := w_aliquota_base_prec;
            w_tipo_al_aree_prec := w_tipo_al_base_prec;
         WHEN others THEN
            w_errore := 'Errore in ricerca Aliquota Aree per Anno '||
                        to_char(a_anno_rif - 1);
            RAISE errore;
       END;
   else
       w_al_aree_prec      := w_al_aree;
       w_tipo_al_aree_prec := w_tipo_al_aree;
   end if;
   w_al_aree_prec := nvl(w_al_aree_b,w_al_aree_prec);
    if a_anno_rif > 2000 then
       w_perc_acconto := 100;
    else
       w_perc_acconto := 90;
    end if;
    a_aliquota_base              := w_aliquota_base;
    a_aliquota_base_prec         := w_aliquota_base_prec;
    a_aliquota_base_erar         := w_aliquota_base_erar;
    a_tipo_al_base               := w_tipo_al_base;
    a_tipo_al_base_prec          := w_tipo_al_base_prec;
    a_al_ab_principale           := w_al_ab_principale;
    a_al_ab_principale_prec      := w_al_ab_principale_prec;
    a_al_ab_principale_erar      := w_al_ab_principale_erar;
    a_al_ab_principale_std       := w_al_ab_principale_std;
    a_tipo_al_ab_principale      := w_tipo_al_ab_principale;
    a_tipo_al_ab_principale_prec := w_tipo_al_ab_principale_prec;
    a_al_affittato               := w_al_affittato;
    a_al_affittato_prec          := w_al_affittato_prec;
    a_al_affittato_erar          := w_al_affittato_erar;
    a_tipo_al_affittato          := w_tipo_al_affittato;
    a_tipo_al_affittato_prec     := w_tipo_al_affittato_prec;
    a_al_non_affittato           := w_al_non_affittato;
    a_al_non_affittato_prec      := w_al_non_affittato_prec;
    a_al_non_affittato_erar      := w_al_non_affittato_erar;
    a_tipo_al_non_affittato      := w_tipo_al_non_affittato;
    a_tipo_al_non_affittato_prec := w_tipo_al_non_affittato_prec;
    a_al_seconda_casa            := w_al_seconda_casa;
    a_al_seconda_casa_prec       := w_al_seconda_casa_prec;
    a_al_seconda_casa_erar       := w_al_seconda_casa_erar;
    a_tipo_al_seconda_casa       := w_tipo_al_seconda_casa;
    a_tipo_al_seconda_casa_prec  := w_tipo_al_seconda_casa_prec;
    a_al_negozio                 := w_al_negozio;
    a_al_negozio_prec            := w_al_negozio_prec;
    a_al_negozio_erar            := w_al_negozio_erar;
    a_tipo_al_negozio            := w_tipo_al_negozio;
    a_tipo_al_negozio_prec       := w_tipo_al_negozio_prec;
    a_al_d                 := w_al_d;
    a_al_d_prec            := w_al_d_prec;
    a_al_d_erar            := w_al_d_erar;
    a_al_d_std             := w_al_d_std;
    a_tipo_al_d            := w_tipo_al_d;
    a_tipo_al_d_prec       := w_tipo_al_d_prec;
    a_al_d10                 := w_al_d10;
    a_al_d10_prec            := w_al_d10_prec;
    a_al_d10_erar            := w_al_d10_erar;
    a_tipo_al_d10            := w_tipo_al_d10;
    a_tipo_al_d10_prec       := w_tipo_al_d10_prec;
    a_al_terreni                 := w_al_terreni;
    a_al_terreni_prec            := w_al_terreni_prec;
    a_al_terreni_erar            := w_al_terreni_erar;
    a_tipo_al_terreni            := w_tipo_al_terreni;
    a_tipo_al_terreni_prec       := w_tipo_al_terreni_prec;
    a_al_terreni_rid             := w_al_terreni_rid;
    a_al_terreni_rid_Prec        := w_al_terreni_rid_prec;
    a_al_terreni_rid_erar        := w_al_terreni_rid_erar;
    a_al_terreni_rid_std         := w_al_terreni_rid_std;
    a_tipo_al_terreni_rid        := w_tipo_al_terreni_rid;
    a_tipo_al_terreni_rid_prec   := w_tipo_al_terreni_rid_prec;
    a_al_aree                    := w_al_aree;
    a_al_aree_prec               := w_al_aree_prec;
    a_al_aree_erar               := w_al_aree_erar;
    a_tipo_al_aree               := w_tipo_al_aree;
    a_tipo_al_aree_Prec          := w_tipo_al_aree_Prec;
    a_aliquota_base_std          := w_aliquota_base_std;
    a_al_ab_principale_std       := w_al_ab_principale_std;
    a_al_affittato_std           := w_al_affittato_std;
    a_al_non_affittato_std       := w_al_non_affittato_std;
    a_al_seconda_casa_std        := w_al_seconda_casa_std;
    a_al_negozio_std             := w_al_negozio_std;
    a_al_d_std                   := w_al_d_std;
    a_al_d10_std                 := w_al_d10_std;
    a_al_terreni_rid_std         := w_al_terreni_rid_std;
    a_perc_acconto               := w_perc_acconto;
    a_errore                     := w_errore;
    Return 0;
EXCEPTION
   WHEN ERRORE THEN
      a_errore := w_errore;
      Return -1;
   WHEN OTHERS THEN
      Return -2;
END;
/* End Function: F_DETERMINA_ALIQUOTE_ICI */
/

