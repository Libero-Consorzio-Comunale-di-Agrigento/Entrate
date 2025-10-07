--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dato_dett_fattura stripComments:false runOnChange:true 
 
create or replace function F_DATO_DETT_FATTURA
(p_anno                    in     number
,p_ni                      in     number --MAI USATO
,p_cod_fiscale             in     varchar2
,p_dal                     in     date
,p_al                      in     date
,p_tributo                 in     number
,p_categoria               in     number
,p_tipo_tariffa            in     number --MAI USATO
,p_tariffa_domestica       in     number
,p_tariffa_non_domestica   in     number
,p_flag_domestica          in     varchar2
,p_flag_ab_principale      in     varchar2
,p_consistenza             in     number
,p_perc_possesso           in     number
,p_imposta                 in     number
,p_dato                    in     varchar2
) return number is
nMax_Fam_Coeff                    number;
nConta                            number;
nGiro                             number;
nCoeff1                           number;
nCoeff2                           number;
nPeriodo                          number;
nImporto                          number;
nDep_Imp                          number;
dDal                              date;
dAl                               date;
cursor sel_faso is
select decode(p_flag_ab_principale
                                 ,'S', codo.coeff_adattamento
                                     , nvl(codo.coeff_adattamento_no_ap,codo.coeff_adattamento)
             )  coeff_adattamento
     , decode(p_flag_ab_principale
                                 ,'S', codo.coeff_produttivita
                                     , nvl(codo.coeff_produttivita_no_ap,codo.coeff_produttivita)
             ) coeff_produttivita
      , codo.numero_familiari
      , greatest(nvl(p_dal,to_date('2222222','j')),faso.dal,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')) dal
      , least(nvl(p_al,to_date('3333333','j')),nvl(faso.al,to_date('3333333','j')),to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')) al
  from coefficienti_domestici codo
      ,familiari_soggetto     faso
      ,contribuenti           cont
 where codo.anno                  = p_anno
   and (    codo.numero_familiari = faso.numero_familiari
        or  codo.numero_familiari = nMax_fam_coeff
        and not exists
           (select 1
              from coefficienti_domestici cod3
             where cod3.anno      = p_anno
               and cod3.numero_familiari
                                  = faso.numero_familiari
           )
       )
   and faso.dal                  <= nvl(p_al,to_date('3333333','j'))
   and nvl(faso.al,to_date('3333333','j'))
                                 >= nvl(p_dal,to_date('2222222','j'))
   and faso.anno                  = p_anno
   and nvl(to_char(faso.al,'yyyy'),9999)
                                 >= p_anno
   and faso.ni                    = cont.ni
   and cont.cod_fiscale           = p_cod_fiscale
;
BEGIN
   if p_flag_domestica = 'S' then
      if p_flag_ab_principale = 'S' then
         nConta := 0;
      else
         select count(*)
           into nConta
           from componenti_superficie cosu
          where cosu.anno = p_anno
         ;
      end if;
      if nConta = 0 then
         BEGIN
            select max(numero_familiari)
              into nMax_fam_coeff
              from coefficienti_domestici
             where anno   = p_anno
            ;
         EXCEPTION
            WHEN others THEN
               return 0;
         END;
         nGiro    := 0;
         nImporto := 0;
         nCoeff1 := 0;
         nCoeff2 := 0;
         FOR rec_faso IN sel_faso
         LOOP
            nGiro     := nGiro + 1;
            nCoeff1   := rec_faso.coeff_adattamento;
            nCoeff2   := rec_faso.coeff_produttivita;
            dDal      := rec_faso.dal;
            dAl       := rec_faso.al;
            nMax_fam_coeff := rec_faso.numero_familiari;
            nPeriodo := round(months_between(dAl + 1,dDal));
            if nPeriodo < 0 then
               nPeriodo := 0;
            end if;
--dbms_output.put_line('Dal '||to_char(dDal,'dd/mm/yyyy')||' Al '||to_char(dAl,'dd/mm/yyyy')||' Periodo '||to_char(nPeriodo));
--dbms_output.put_line('Tar. Dom. '||to_char(p_tariffa_domestica)||' Consistenza '||to_char(p_consistenza));
--dbms_output.put_line('Coeff. '||to_char(nCoeff1)||' % Possesso '||to_char(p_perc_posesso));
--
-- Calcolo della parte fissa.
--
            nDep_Imp := (p_tariffa_domestica * p_consistenza * nCoeff1)
                        * nPeriodo / 12 * nvl(p_perc_possesso,100) / 100;
            if p_dato = 'I1' then
               nImporto := nImporto + round(nDep_Imp,2);
            elsif p_dato = 'I2' then
               nImporto := nImporto + p_imposta - round(nDep_Imp,2);
            else
               nImporto := 0;
            end if;
--dbms_output.put_line('Dep Imp = '||to_char(nDep_Imp)||' - Importo = '||to_char(nImporto));
         END LOOP;
      else --nConta != 0
         nImporto := 0;
         nCoeff1 := 0;
         nCoeff2 := 0;
         BEGIN
            select max(cosu.numero_familiari)
              into nMax_fam_coeff
              from componenti_superficie cosu
              where p_consistenza between nvl(cosu.da_consistenza,0)
                                     and nvl(cosu.a_consistenza,9999999)
               and cosu.anno           = p_anno
             group by 1
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               BEGIN
                  select max(cosu.numero_familiari)
                    into nMax_fam_coeff
                    from componenti_superficie cosu
                   where cosu.anno   = p_anno
                   group by 1
                  ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     nMax_fam_coeff := 0;
               END;
         END;
--
-- Contrariamente ai familiari soggetto, non ci si trova in presenza di un archivio
-- storico per cui la query per determinare i coefficienti ha come interrogazione
-- una unica registrazione.
--
         BEGIN
            select nvl(codo.coeff_adattamento_no_ap,codo.coeff_adattamento)
                  ,nvl(codo.coeff_produttivita_no_ap,codo.coeff_produttivita)
             into nCoeff1
                 ,nCoeff2
             from coefficienti_domestici codo
            where codo.anno                  = p_anno
              and codo.numero_familiari      = nMax_fam_coeff
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               nCoeff1 := 0;
               nCoeff2 := 0;
         END;
         dDal := greatest(nvl(p_dal,to_date('2222222','j')),to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
         dAl  := least(nvl(p_al,to_date('3333333','j')),to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
         nPeriodo := round(months_between(dAl + 1,dDal));
--dbms_output.put_line('Dal '||to_char(dDal,'dd/mm/yyyy')||' Al '||to_char(dAl,'dd/mm/yyyy')||' Periodo '||to_char(nPeriodo));
--dbms_output.put_line('Tar. Dom. '||to_char(p_tariffa_domestica)||' Consistenza '||to_char(p_consistenza));
--dbms_output.put_line('Coeff. '||to_char(nCoeff1)||' % Possesso '||to_char(p_perc_posesso));
         if nPeriodo < 0 then
            nPeriodo := 0;
         end if;
         nDep_Imp := (p_tariffa_domestica * p_consistenza * nCoeff1)
                      * nPeriodo / 12 * nvl(p_perc_possesso,100) / 100;
         if p_dato = 'I1' then
            nImporto := nImporto + round(nDep_Imp,2);
         elsif p_dato = 'I2' then
            nImporto := nImporto + p_imposta - round(nDep_Imp,2);
         else
            nImporto := 0;
         end if;
--dbms_output.put_line('Dep Imp = '||to_char(nDep_Imp)||' - Importo = '||to_char(nImporto));
      end if;
   else --p_flag_domestica != 'S'
      nMax_fam_coeff := null;
      nImporto := 0;
      BEGIN
         select coeff_potenziale, coeff_produzione
           into nCoeff1, nCoeff2
           from coefficienti_non_domestici
          where anno        = p_anno
            and tributo     = p_tributo
            and categoria   = p_categoria
         ;
      EXCEPTION
         WHEN others THEN
            Return 0;
      END;
      dDal     := greatest(nvl(dDal,to_date('2222222','j')),to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
      dAl      := least(nvl(dAl,to_date('3333333','j'))
                        ,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
      nPeriodo := round(months_between(dAl + 1,dDal));
      if nPeriodo < 0 then
         nPeriodo := 0;
      end if;
--dbms_output.put_line('Dal '||to_char(dDal,'dd/mm/yyyy')||' Al '||to_char(dAl,'dd/mm/yyyy')||' Periodo '||to_char(nPeriodo));
--dbms_output.put_line('Tar. Dom. '||to_char(p_tariffa_non_domestica)||' Consistenza '||to_char(p_consistenza));
--dbms_output.put_line('Coeff. '||to_char(nCoeff1)||' % Possesso '||to_char(p_perc_posesso));
      nDep_Imp := (p_tariffa_non_domestica * p_consistenza * nCoeff1)
                   * nPeriodo / 12 * nvl(p_perc_possesso,100) / 100;
      if p_dato = 'I1' then
         nImporto := nImporto + round(nDep_Imp,2);
      elsif p_dato = 'I2' then
         nImporto := nImporto + p_imposta - round(nDep_Imp,2);
      else
         nImporto := 0;
      end if;
--dbms_output.put_line('Dep Imp = '||to_char(nDep_Imp)||' - Importo = '||to_char(nImporto));
   end if;--if p_flag_domestica = 'S' then
   if p_dato = 'C1' then
      Return nCoeff1;
   elsif p_dato = 'C2' then
      Return nCoeff2;
   elsif p_dato = 'NF' then
      Return nMax_fam_coeff;
   elsif p_dato = 'I1' then
      Return nImporto;
   elsif p_dato = 'I2' then
      Return nImporto;
   else
      Return null;
   end if;
END;
/* End Function: F_DATO_DETT_FATTURA */
/

