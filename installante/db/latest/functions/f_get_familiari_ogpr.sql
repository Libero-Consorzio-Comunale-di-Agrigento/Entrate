--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_familiari_ogpr stripComments:false runOnChange:true 
 
create or replace function F_GET_FAMILIARI_OGPR
(p_ogpr            in number
,p_flag_ab_princ   in varchar2
,p_anno            in number
,p_tributo         in number
,p_categoria       in number
,p_consistenza     in number
)
  return varchar2
is
  w_str_fam_ogim       varchar2(2000) := '';
  w_ni                 number;
  w_esiste_cosu        varchar2(1);
  w_fdom               char;
  w_max_fam_coeff      number;
  w_tari               number;
  w_tari2              number;
  w_coeff1             number;
  w_coeff2             number;
  w_giro               number;
  w_dal                date;
  w_al                 date;
  w_numero_familiari   number;
  w_fam_coeff          number;
  cursor sel_faso
  is
      select decode(p_flag_ab_princ
                   ,'S', codo.coeff_adattamento
                   ,nvl(codo.coeff_adattamento_no_ap, codo.coeff_adattamento)
                   )
               coeff_adattamento
            ,decode(p_flag_ab_princ
                   ,'S', codo.coeff_produttivita
                   ,nvl(codo.coeff_produttivita_no_ap, codo.coeff_produttivita)
                   )
               coeff_produttivita
            ,greatest(nvl(to_date('01/01/' || p_anno, 'dd/mm/yyyy')
                         ,to_date('2222222', 'j')
                         )
                     ,faso.dal
                     ,to_date('0101' || lpad(to_char(p_anno), 4, '0')
                             ,'ddmmyyyy'
                             )
                     )
               dal
            ,least(nvl(to_date('31/12/' || p_anno, 'dd/mm/yyyy')
                      ,to_date('3333333', 'j')
                      )
                  ,nvl(faso.al, to_date('3333333', 'j'))
                  ,to_date('3112' || lpad(to_char(p_anno), 4, '0'), 'ddmmyyyy')
                  )
               al
            ,faso.numero_familiari numero_familiari
        from coefficienti_domestici codo, familiari_soggetto faso
       where codo.anno = p_anno
         and (codo.numero_familiari = faso.numero_familiari
           or codo.numero_familiari = w_max_fam_coeff
          and not exists
                (select 1
                   from coefficienti_domestici cod3
                  where cod3.anno = p_anno
                    and cod3.numero_familiari = faso.numero_familiari))
         and faso.dal <=
               nvl(to_date('31/12/' || p_anno, 'dd/mm/yyyy')
                  ,to_date('3333333', 'j')
                  )
         and nvl(faso.al, to_date('3333333', 'j')) >=
               nvl(to_date('01/01/' || p_anno, 'dd/mm/yyyy')
                  ,to_date('2222222', 'j')
                  )
         and faso.anno = p_anno
         -- Riga aggiunta per non considerare dei periodi dell'anno precedente
         and nvl(to_char(faso.al, 'yyyy'), 9999) >= p_anno
         and faso.ni = w_ni
    order by 3;
begin
  begin
    select ni
      into w_ni
      from contribuenti
     where cod_fiscale = (select cod_fiscale
                            from oggetti_contribuente ogco
                           where ogco.oggetto_pratica = p_ogpr);
  end;
  begin
    select flag_domestica
      into w_fdom
      from categorie
     where tributo = p_tributo
       and categoria = p_categoria;
  end;
  if p_flag_ab_princ = 'S' then
    w_esiste_cosu :=   'N';
  else
    begin
      select decode(count(*), 0, 'N', 'S')
        into w_esiste_cosu
        from componenti_superficie
       where anno = p_anno;
    end;
  end if;
  --
  -- Se e` indicata una tariffa a quota fissa nei parametri di input, questa
  -- viene applicata in luogo della tariffa domestica o non domestica.
  --
  begin
    select decode(w_fdom, 'S', tariffa_domestica, tariffa_non_domestica)
      into w_tari
      from carichi_tarsu
     where anno = p_anno;
  end;
  begin
    select tari.tariffa
      into w_tari2
      from tariffe tari, oggetti_pratica ogpr
     where ogpr.oggetto_pratica = p_ogpr
       and tari.tipo_tariffa = ogpr.tipo_tariffa
       and tari.categoria + 0 = ogpr.categoria
       and tari.tributo = ogpr.tributo
       and nvl(tari.anno, 0) = p_anno;
  end;
  if w_fdom = 'S' then
    if w_esiste_cosu = 'N' then
      --
      -- Se non esistono componenti per superficie nell`anno si opera attraverso i familiari soggetto.
      --
      begin
        select max(numero_familiari)
          into w_max_fam_coeff
          from coefficienti_domestici
         where anno = p_anno;
      end;
      w_giro :=               0;
      --      w_stringa_familiari :=   '';
      w_numero_familiari :=   -9999;
      w_al :=                 to_date('01011900', 'ddmmyyyy');
      w_str_fam_ogim :=       null;
      for rec_faso in sel_faso loop
        w_giro :=               w_giro + 1;
        if w_giro = 1 then
          w_dal :=   rec_faso.dal;
          w_al :=    rec_faso.al;
        else
          if w_numero_familiari = rec_faso.numero_familiari
         and w_al + 1 = rec_faso.dal then
            w_al :=   rec_faso.al;
          else
            if w_str_fam_ogim is null then
                w_str_fam_ogim      :=
                     'Familiari: '
                  || w_numero_familiari
                  || ' Dal: '
                  || to_char(w_dal, 'dd/mm/yy')
                  || ' al: '
                  || to_char(w_al, 'dd/mm/yy')
                  || '[a_capo'
                  || lpad(' ', 20)
                  || ' (Ka. '
                  || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,7
                         ,' '
                         )
                  || ' Tariffa '
                  || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,13
                         ,' '
                         )
                  || ') [a_capo'
                  || lpad(' ', 20)
                  || ' (Kb. '
                  || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,7
                         ,' '
                         )
                  || ' Tariffa '
                  || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,13
                         ,' '
                         )
                  || ')';
            else
                w_str_fam_ogim      :=
                     w_str_fam_ogim
                  || '[a_capo'
                  || lpad(' ', 21)
                  || 'Familiari: '
                  || w_numero_familiari
                  || ' Dal: '
                  || to_char(w_dal, 'dd/mm/yy')
                  || ' al: '
                  || to_char(w_al, 'dd/mm/yy')
                  || '[a_capo'
                  || lpad(' ', 20)
                  || ' (Ka. '
                  || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,7
                         ,' '
                         )
                  || ' Tariffa '
                  || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,13
                         ,' '
                         )
                  || ') [a_capo'
                  || lpad(' ', 20)
                  || ' (Kb. '
                  || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,7
                         ,' '
                         )
                  || ' Tariffa '
                  || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                                       ,'.,'
                                       ,',.'
                                       )
                             ,' '
                             )
                         ,13
                         ,' '
                         )
                  || ')';
              end if;
            --dbms_output.put_line('('||to_char(w_giro)||') tariffa1 '||to_char(w_tari)||' consistenza '||
            --' coeff1 '||to_char(w_coeff1)||' tariffa2 '||' coeff2 '||to_char(w_coeff2));
            w_dal :=   rec_faso.dal;
            w_al :=    rec_faso.al;
          end if;
        end if;                                                  -- w_giro = 1
        w_numero_familiari :=   rec_faso.numero_familiari;
        w_coeff1 :=             rec_faso.coeff_adattamento;
        w_coeff2 :=             rec_faso.coeff_produttivita;
      end loop;
      if w_str_fam_ogim is null then
            w_str_fam_ogim      :=
            'Familiari: '
            || w_numero_familiari
            || ' Dal: '
            || to_char(w_dal, 'dd/mm/yy')
            || ' al: '
            || to_char(w_al, 'dd/mm/yy')
            || '[a_capo'
            || lpad(' ', 20)
            || ' (Ka. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ') [a_capo'
            || lpad(' ', 20)
            || ' (Kb. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ')';
      else
          w_str_fam_ogim      :=
               w_str_fam_ogim
            || '[a_capo'
            || lpad(' ', 21)
            || 'Familiari: '
            || w_numero_familiari
            || ' Dal: '
            || to_char(w_dal, 'dd/mm/yy')
            || ' al: '
            || to_char(w_al, 'dd/mm/yy')
            || '[a_capo'
            || lpad(' ', 20)
            || ' (Ka. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ') [a_capo'
            || lpad(' ', 20)
            || ' (Kb. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ')';
      end if;
    --
    -- Caso di presenza di componenti per superficie.
    -- Analogamente a quanto fatto per i familiari soggetto, se non esiste una registrazione
    -- per componenti superficie relativa alla consistenza dell`oggetto in esame, si fa
    -- riferimento al numero massimo dei familiari previsto per l`anno.
    --
    else
      select nvl(numero_familiari,0)
        into w_fam_coeff
        from oggetti_pratica
       where oggetto_pratica = p_ogpr;
      if w_fam_coeff = 0 then
          begin
              select max(cosu.numero_familiari)
                into w_max_fam_coeff
                from componenti_superficie cosu
               where cosu.anno = p_anno
            group by 1;
          -- dbms_output.put_line('Trovato Massimo '||to_char(w_max_fam_coeff));
          exception
            when no_data_found then
              -- dbms_output.put_line('Non Trovato Nulla');
              w_max_fam_coeff :=   0;
          end;
        dbms_output.put_line('w_max_fam_coeff '||w_max_fam_coeff);
          begin
              select max(cosu.numero_familiari)
                into w_fam_coeff
                from componenti_superficie cosu
               where p_consistenza between nvl(cosu.da_consistenza, 0)
                                       and nvl(cosu.a_consistenza, 9999999)
                 and cosu.anno = p_anno
            group by 1;
                dbms_output.put_line(' 1 w_fam_coeff '||w_fam_coeff);
          -- dbms_output.put_line('Trovato '||to_char(w_max_fam_coeff));
          exception
            when no_data_found then
              -- dbms_output.put_line('Non Trovato');
              w_fam_coeff :=   w_max_fam_coeff;
          end;
      end if;
    dbms_output.put_line('w_fam_coeff '||w_fam_coeff);
      --
      -- Contrariamente ai familiari soggetto, non ci si trova in presenza di un archivio
      -- storico per cui la query per determinare i coefficienti ha come interrogazione
      -- una unica registrazione.
      --
      begin
        select nvl(codo.coeff_adattamento_no_ap, codo.coeff_adattamento)
              ,nvl(codo.coeff_produttivita_no_ap, codo.coeff_produttivita)
          into w_coeff1, w_coeff2
          from coefficienti_domestici codo
         where codo.anno = p_anno
           and codo.numero_familiari = w_fam_coeff;
      exception
        when no_data_found then
          w_coeff1 :=   0;
          w_coeff2 :=   0;
      end;
    dbms_output.put_line('w_coeff1 '||w_coeff1);
    dbms_output.put_line('w_coeff2 '||w_coeff2);
      w_dal      :=
        greatest(nvl(to_date('01/01/' || p_anno, 'dd/mm/yyyy')
                    ,to_date('2222222', 'j')
                    )
                ,to_date('0101' || lpad(to_char(p_anno), 4, '0'), 'ddmmyyyy')
                );
      w_al      :=
        least(nvl(to_date('31/12/' || p_anno, 'dd/mm/yyyy')
                 ,to_date('3333333', 'j')
                 )
             ,to_date('3112' || lpad(to_char(p_anno), 4, '0'), 'ddmmyyyy')
             );
      if w_str_fam_ogim is null then
        w_str_fam_ogim      :=
        'Familiari: '
        || w_fam_coeff
        || ' Dal: '
        || to_char(w_dal, 'dd/mm/yy')
        || ' al: '
        || to_char(w_al, 'dd/mm/yy')
        || '[a_capo'
        || lpad(' ', 20)
        || ' (Ka. '
        || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                             ,'.,'
                             ,',.'
                             )
                   ,' '
                   )
               ,7
               ,' '
               )
        || ' Tariffa '
        || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                             ,'.,'
                             ,',.'
                             )
                   ,' '
                   )
               ,13
               ,' '
               )
        || ') [a_capo'
        || lpad(' ', 20)
        || ' (Kb. '
        || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                             ,'.,'
                             ,',.'
                             )
                   ,' '
                   )
               ,7
               ,' '
               )
        || ' Tariffa '
        || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                             ,'.,'
                             ,',.'
                             )
                   ,' '
                   )
               ,13
               ,' '
               )
        || ')';
      else
          w_str_fam_ogim      :=
               w_str_fam_ogim
            || '[a_capo'
            || lpad(' ', 21)
            || 'Familiari: '
            || w_fam_coeff
            || ' Dal: '
            || to_char(w_dal, 'dd/mm/yy')
            || ' al: '
            || to_char(w_al, 'dd/mm/yy')
            || '[a_capo'
            || lpad(' ', 20)
            || ' (Ka. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ') [a_capo'
            || lpad(' ', 20)
            || ' (Kb. '
            || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,7
                   ,' '
                   )
            || ' Tariffa '
            || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                                 ,'.,'
                                 ,',.'
                                 )
                       ,' '
                       )
                   ,13
                   ,' '
                   )
            || ')';
      end if;
    --         dbms_output.put_line('tariffa1 '||to_char(w_tari)||' consistenza '||to_char(b_consistenza)||
    --         ' coeff1 '||to_char(w_coeff1)||' tariffa2 '||to_char(a_tariffa)||' coeff2 '||to_char(w_coeff2)||
    --         ' periodo '||to_char(w_periodo)||' perc_possesso '||to_char(a_perc_possesso)||' importo '||to_char(w_importo));
    end if;
  else
    begin
      select coeff_potenziale, coeff_produzione
        into w_coeff1, w_coeff2
        from coefficienti_non_domestici
       where anno = p_anno
         and tributo = p_tributo
         and categoria = p_categoria;
    end;
    w_dal      := to_date('01/01/' || p_anno, 'dd/mm/yyyy');
    w_al       := to_date('31/12/' || p_anno, 'dd/mm/yyyy');
    if w_str_fam_ogim is null then
        w_str_fam_ogim      :=
          'Dal: '
          || to_char(w_dal, 'dd/mm/yy')
          || ' al: '
          || to_char(w_al, 'dd/mm/yy')
          || '[a_capo'
          || lpad(' ', 20)
          || ' (Kc. '
          || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000')), '.,', ',.')
                     ,' '
                     )
                 ,7
                 ,' '
                 )
          || ' Tariffa '
          || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                               ,'.,'
                               ,',.'
                               )
                     ,' '
                     )
                 ,13
                 ,' '
                 )
          || ') [a_capo'
          || lpad(' ', 20)
          || ' (Kd. '
          || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000')), '.,', ',.')
                     ,' '
                     )
                 ,7
                 ,' '
                 )
          || ' Tariffa '
          || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                               ,'.,'
                               ,',.'
                               )
                     ,' '
                     )
                 ,13
                 ,' '
                 )
          || ')';
    else
        w_str_fam_ogim      :=
             w_str_fam_ogim
          || '[a_capo'
          || lpad(' ', 21)
          || 'Dal: '
          || to_char(w_dal, 'dd/mm/yy')
          || ' al: '
          || to_char(w_al, 'dd/mm/yy')
          || '[a_capo'
          || lpad(' ', 20)
          || ' (Kc. '
          || lpad(nvl(translate(ltrim(to_char(w_coeff1, '90.0000')), '.,', ',.')
                     ,' '
                     )
                 ,7
                 ,' '
                 )
          || ' Tariffa '
          || lpad(nvl(translate(ltrim(to_char(w_tari, '999,990.00000'))
                               ,'.,'
                               ,',.'
                               )
                     ,' '
                     )
                 ,13
                 ,' '
                 )
          || ') [a_capo'
          || lpad(' ', 20)
          || ' (Kd. '
          || lpad(nvl(translate(ltrim(to_char(w_coeff2, '90.0000')), '.,', ',.')
                     ,' '
                     )
                 ,7
                 ,' '
                 )
          || ' Tariffa '
          || lpad(nvl(translate(ltrim(to_char(w_tari2, '999,990.00000'))
                               ,'.,'
                               ,',.'
                               )
                     ,' '
                     )
                 ,13
                 ,' '
                 )
          || ')';
      end if;
  end if;
  --[a_capo viene convertito in Carriage Return da PowerBuilder
  return (w_str_fam_ogim);
end;
/* End Function: F_GET_FAMILIARI_OGPR */
/

