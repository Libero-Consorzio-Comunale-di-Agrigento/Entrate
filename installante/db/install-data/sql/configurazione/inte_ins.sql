--liquibase formatted sql
--changeset dmarotta:20250326_152438_inte_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE interessi DISABLE ALL TRIGGERS;

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 8, to_date('01-01-2011', 'dd-mm-yyyy'), to_date('31-12-2011', 'dd-mm-yyyy'), 3.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 10, to_date('01-01-2008', 'dd-mm-yyyy'), to_date('31-12-2009', 'dd-mm-yyyy'), 5.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 7, to_date('01-01-2010', 'dd-mm-yyyy'), to_date('31-12-2010', 'dd-mm-yyyy'), 3.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 5, to_date('01-01-2007', 'dd-mm-yyyy'), to_date('31-12-2007', 'dd-mm-yyyy'), 4.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 6, to_date('01-01-2004', 'dd-mm-yyyy'), to_date('31-12-2006', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 3, to_date('01-01-1996', 'dd-mm-yyyy'), to_date('31-12-2001', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 4, to_date('01-01-2002', 'dd-mm-yyyy'), to_date('31-12-2003', 'dd-mm-yyyy'), 3.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 11, to_date('01-01-2012', 'dd-mm-yyyy'), to_date('31-12-2012', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 12, to_date('01-01-2013', 'dd-mm-yyyy'), to_date('31-12-2013', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 13, to_date('01-01-2014', 'dd-mm-yyyy'), to_date('31-12-2014', 'dd-mm-yyyy'), 1.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 14, to_date('01-01-2015', 'dd-mm-yyyy'), to_date('31-12-2015', 'dd-mm-yyyy'), 0.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 15, to_date('01-01-2016', 'dd-mm-yyyy'), to_date('31-12-2016', 'dd-mm-yyyy'), 0.2000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 16, to_date('01-01-2017', 'dd-mm-yyyy'), to_date('31-12-2017', 'dd-mm-yyyy'), 0.1000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 17, to_date('01-01-2018', 'dd-mm-yyyy'), to_date('31-12-2018', 'dd-mm-yyyy'), 0.3000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 19, to_date('01-01-2020', 'dd-mm-yyyy'), to_date('31-12-2020', 'dd-mm-yyyy'), 0.0500, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 18, to_date('01-01-2019', 'dd-mm-yyyy'), to_date('31-12-2019', 'dd-mm-yyyy'), 0.8000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 20, to_date('01-01-2015', 'dd-mm-yyyy'), to_date('31-12-2015', 'dd-mm-yyyy'), 0.5000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 21, to_date('01-01-2016', 'dd-mm-yyyy'), to_date('31-12-2016', 'dd-mm-yyyy'), 0.2000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 22, to_date('01-01-2017', 'dd-mm-yyyy'), to_date('31-12-2017', 'dd-mm-yyyy'), 0.1000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 23, to_date('01-01-2018', 'dd-mm-yyyy'), to_date('31-12-2018', 'dd-mm-yyyy'), 0.3000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 24, to_date('01-01-2019', 'dd-mm-yyyy'), to_date('31-12-2019', 'dd-mm-yyyy'), 0.8000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 25, to_date('01-01-2020', 'dd-mm-yyyy'), to_date('31-12-2020', 'dd-mm-yyyy'), 0.0500, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 26, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 29, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 30, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 31, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 9, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2025', 'dd-mm-yyyy'), 2.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 10, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2025', 'dd-mm-yyyy'), 2.0000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 33, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 36, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2025', 'dd-mm-yyyy'), 2.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 37, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2025', 'dd-mm-yyyy'), 2.0000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 27, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 1, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 2, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 7, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 8, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 34, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 35, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 28, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('ICI', 32, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 3, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'L');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 4, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 5, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('CUNI', 6, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 1, to_date('01-01-1994', 'dd-mm-yyyy'), to_date('30-06-1998', 'dd-mm-yyyy'), 7.0000, 'S');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 3, to_date('01-07-1998', 'dd-mm-yyyy'), to_date('31-12-1998', 'dd-mm-yyyy'), 5.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 9, to_date('01-01-2018', 'dd-mm-yyyy'), to_date('31-12-2018', 'dd-mm-yyyy'), 0.3000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 13, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 4, to_date('01-01-2012', 'dd-mm-yyyy'), to_date('31-12-2013', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 5, to_date('01-01-2014', 'dd-mm-yyyy'), to_date('31-12-2014', 'dd-mm-yyyy'), 1.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 6, to_date('01-01-2015', 'dd-mm-yyyy'), to_date('31-12-2015', 'dd-mm-yyyy'), 0.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 7, to_date('01-01-2016', 'dd-mm-yyyy'), to_date('31-12-2016', 'dd-mm-yyyy'), 0.2000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 8, to_date('01-01-2017', 'dd-mm-yyyy'), to_date('31-12-2017', 'dd-mm-yyyy'), 0.1000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 10, to_date('01-01-2019', 'dd-mm-yyyy'), to_date('31-12-2019', 'dd-mm-yyyy'), 0.8000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 11, to_date('01-01-2020', 'dd-mm-yyyy'), to_date('31-12-2020', 'dd-mm-yyyy'), 0.0500, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 15, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2100', 'dd-mm-yyyy'), 2.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 12, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 14, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 28, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 29, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'G');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 30, to_date('01-01-2024', 'dd-mm-yyyy'), to_date('31-12-2024', 'dd-mm-yyyy'), 2.5000, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 16, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2100', 'dd-mm-yyyy'), 2.0000, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 17, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 18, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 19, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 20, to_date('01-01-2020', 'dd-mm-yyyy'), to_date('31-12-2020', 'dd-mm-yyyy'), 0.0500, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 21, to_date('01-01-2019', 'dd-mm-yyyy'), to_date('31-12-2019', 'dd-mm-yyyy'), 0.8000, 'D');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 22, to_date('01-01-2019', 'dd-mm-yyyy'), to_date('31-12-2019', 'dd-mm-yyyy'), 0.8000, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 23, to_date('01-01-2020', 'dd-mm-yyyy'), to_date('31-12-2020', 'dd-mm-yyyy'), 0.0500, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 24, to_date('01-01-2021', 'dd-mm-yyyy'), to_date('31-12-2021', 'dd-mm-yyyy'), 0.0100, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 25, to_date('01-01-2022', 'dd-mm-yyyy'), to_date('31-12-2022', 'dd-mm-yyyy'), 1.2500, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 26, to_date('01-01-2023', 'dd-mm-yyyy'), to_date('31-12-2023', 'dd-mm-yyyy'), 5.0000, 'R');

insert into interessi (TIPO_TRIBUTO, SEQUENZA, DATA_INIZIO, DATA_FINE, ALIQUOTA, TIPO_INTERESSE)
values ('TARSU', 27, to_date('01-01-2025', 'dd-mm-yyyy'), to_date('31-12-2100', 'dd-mm-yyyy'), 2.0000, 'R');

ALTER TABLE interessi ENABLE ALL TRIGGERS;
