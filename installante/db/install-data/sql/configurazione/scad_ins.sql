--liquibase formatted sql
--changeset dmarotta:20250326_152438_scad_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE scadenze DISABLE ALL TRIGGERS;

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('TARSU', 2025, 1, 'D', null, null, to_date('30-06-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('TARSU', 2024, 1, 'D', null, null, to_date('30-06-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('TARSU', 2024, 2, 'R', null, null, to_date('30-06-2029', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('TARSU', 2025, 2, 'R', null, null, to_date('30-06-2030', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2022, 1, 'V', 0, null, to_date('31-05-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2022, 2, 'V', 1, null, to_date('31-05-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2022, 3, 'V', 2, null, to_date('30-11-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2021, 2, 'V', 1, null, to_date('31-07-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2021, 3, 'V', 2, null, to_date('30-11-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2022, 4, 'R', null, null, to_date('31-05-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2021, 4, 'R', null, null, to_date('31-05-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2024, 1, 'R', null, null, to_date('30-05-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2024, 2, 'V', 0, null, to_date('31-05-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2024, 3, 'V', 1, null, to_date('31-05-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2024, 4, 'V', 2, null, to_date('30-11-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2023, 1, 'R', null, null, to_date('30-05-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2023, 2, 'V', 0, null, to_date('31-05-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2023, 3, 'V', 1, null, to_date('31-05-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2023, 4, 'V', 2, null, to_date('30-11-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2021, 1, 'V', 0, null, to_date('31-07-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 1, 'V', 0, null, to_date('31-05-2025', 'dd-mm-yyyy'), '111111', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 2, 'V', 2, null, to_date('01-12-2025', 'dd-mm-yyyy'), '111111', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 3, 'V', 0, null, to_date('31-05-2025', 'dd-mm-yyyy'), '222222', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 4, 'V', 2, null, to_date('01-12-2025', 'dd-mm-yyyy'), '222222', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 5, 'R', null, null, to_date('30-05-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 6, 'V', 0, null, to_date('31-05-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 7, 'V', 1, null, to_date('31-05-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 8, 'V', 2, null, to_date('01-12-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 9, 'V', 1, null, to_date('31-05-2025', 'dd-mm-yyyy'), '111111', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('CUNI', 2025, 10, 'V', 1, null, to_date('31-05-2025', 'dd-mm-yyyy'), '222222', null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2013, 3, 'D', null, null, to_date('30-06-2014', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2011, 1, 'D', null, null, to_date('30-06-2012', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2011, 2, 'V', null, 'A', to_date('16-06-2011', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2011, 3, 'V', null, 'S', to_date('16-12-2011', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2002, 3, 'D', null, null, to_date('01-07-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2003, 3, 'D', null, null, to_date('30-06-2003', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2004, 1, 'D', null, null, to_date('30-06-2004', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2004, 2, 'V', null, 'A', to_date('30-06-2004', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2004, 3, 'V', null, 'S', to_date('20-12-2004', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1998, 1, 'V', null, 'A', to_date('30-06-1998', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1993, 1, 'V', null, 'A', to_date('30-06-1993', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1993, 2, 'V', null, 'S', to_date('20-12-1993', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1994, 1, 'V', null, 'U', to_date('30-06-1994', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1993, 3, 'D', null, null, to_date('30-06-1994', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1994, 2, 'V', null, 'S', to_date('20-12-1994', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1994, 3, 'D', null, null, to_date('30-06-1995', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1995, 2, 'V', null, 'S', to_date('20-12-1995', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1995, 3, 'D', null, null, to_date('30-06-1996', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1996, 1, 'V', null, 'A', to_date('01-07-1996', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1996, 2, 'V', null, 'S', to_date('22-12-1996', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1997, 1, 'V', null, 'A', to_date('30-06-1997', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1996, 3, 'D', null, null, to_date('01-07-1997', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1997, 2, 'V', null, 'S', to_date('22-12-1997', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1997, 3, 'D', null, null, to_date('30-06-1998', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1998, 3, 'D', null, null, to_date('01-07-1999', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1998, 4, 'V', null, 'S', to_date('20-12-1998', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1995, 4, 'V', null, 'A', to_date('30-06-1995', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2005, 3, 'D', null, null, to_date('30-06-2005', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1999, 1, 'V', null, 'S', to_date('20-12-1999', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1999, 2, 'V', null, 'A', to_date('30-06-1999', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2000, 1, 'V', null, 'S', to_date('20-12-2000', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2000, 2, 'V', null, 'A', to_date('30-06-2000', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2000, 3, 'D', null, null, to_date('01-07-2001', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1999, 3, 'D', null, null, to_date('01-07-2000', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2001, 1, 'V', null, 'A', to_date('02-07-2001', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2001, 2, 'V', null, 'S', to_date('20-12-2001', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2001, 3, 'D', null, null, to_date('01-07-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2002, 1, 'V', null, 'S', to_date('20-12-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2002, 2, 'V', null, 'A', to_date('01-07-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2003, 1, 'V', null, 'A', to_date('30-06-2003', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2003, 2, 'V', null, 'S', to_date('22-12-2003', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2007, 3, 'D', null, null, to_date('30-06-2007', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2005, 1, 'V', null, 'A', to_date('30-06-2005', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2005, 2, 'V', null, 'S', to_date('20-12-2005', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2008, 3, 'D', null, null, to_date('30-06-2008', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2009, 1, 'D', null, null, to_date('30-06-2009', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2006, 1, 'D', null, null, to_date('30-06-2006', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2006, 2, 'V', null, 'A', to_date('30-06-2006', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2006, 3, 'V', null, 'S', to_date('20-12-2006', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2010, 1, 'D', null, null, to_date('30-06-2010', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2010, 2, 'V', null, 'A', to_date('16-06-2010', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2010, 3, 'V', null, 'S', to_date('16-12-2010', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2007, 1, 'V', null, 'A', to_date('18-06-2007', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2007, 2, 'V', null, 'S', to_date('17-12-2007', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2008, 1, 'V', null, 'A', to_date('16-06-2008', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2008, 2, 'V', null, 'S', to_date('16-12-2008', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2009, 2, 'V', null, 'A', to_date('16-06-2009', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2009, 3, 'V', null, 'S', to_date('16-12-2009', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2012, 1, 'V', null, 'S', to_date('17-12-2012', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2012, 3, 'D', null, null, to_date('30-06-2013', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2012, 2, 'V', null, 'A', to_date('17-06-2012', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2013, 1, 'V', null, 'A', to_date('17-06-2013', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2013, 2, 'V', null, 'S', to_date('16-12-2013', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2015, 1, 'D', null, null, to_date('30-06-2016', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2015, 2, 'V', null, 'A', to_date('16-06-2015', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2015, 3, 'V', null, 'S', to_date('16-12-2015', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2016, 1, 'V', null, 'A', to_date('16-06-2016', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2016, 2, 'V', null, 'S', to_date('16-12-2016', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2016, 3, 'D', null, null, to_date('30-06-2017', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2018, 1, 'D', null, null, to_date('31-12-2019', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2018, 2, 'V', null, 'A', to_date('16-06-2018', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2018, 3, 'V', null, 'S', to_date('17-12-2018', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2014, 1, 'D', null, null, to_date('30-06-2015', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2014, 2, 'V', null, 'A', to_date('17-06-2014', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2014, 3, 'V', null, 'S', to_date('16-12-2014', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2017, 1, 'V', null, 'A', to_date('16-06-2017', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2017, 2, 'V', null, 'S', to_date('18-12-2017', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2017, 3, 'D', null, null, to_date('30-06-2018', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2019, 4, 'R', null, null, to_date('31-12-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2019, 1, 'V', null, 'A', to_date('17-06-2019', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2019, 2, 'V', null, 'S', to_date('16-12-2019', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2019, 3, 'D', null, null, to_date('31-12-2020', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2020, 1, 'V', null, 'A', to_date('16-06-2020', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2020, 2, 'V', null, 'S', to_date('16-12-2020', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2020, 3, 'D', null, null, to_date('30-06-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2020, 4, 'R', null, null, to_date('31-12-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1992, 1, 'R', null, null, to_date('30-06-1994', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1993, 4, 'R', null, null, to_date('30-06-1995', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1994, 4, 'R', null, null, to_date('30-06-1996', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1995, 5, 'R', null, null, to_date('01-07-1997', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1996, 4, 'R', null, null, to_date('30-06-1998', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1997, 4, 'R', null, null, to_date('01-07-1999', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1998, 5, 'R', null, null, to_date('01-07-2000', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 1999, 4, 'R', null, null, to_date('01-07-2001', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2000, 4, 'R', null, null, to_date('01-07-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2001, 4, 'R', null, null, to_date('01-07-2002', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2002, 4, 'R', null, null, to_date('30-06-2003', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2003, 4, 'R', null, null, to_date('30-06-2004', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2004, 4, 'R', null, null, to_date('30-06-2005', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2005, 4, 'R', null, null, to_date('30-06-2006', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2006, 4, 'R', null, null, to_date('30-06-2007', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2007, 4, 'R', null, null, to_date('30-06-2008', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2008, 4, 'R', null, null, to_date('30-06-2009', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2009, 4, 'R', null, null, to_date('30-06-2010', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2010, 4, 'R', null, null, to_date('30-06-2012', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2011, 4, 'R', null, null, to_date('30-06-2013', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2012, 4, 'R', null, null, to_date('30-06-2014', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2013, 4, 'R', null, null, to_date('30-06-2015', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2014, 4, 'R', null, null, to_date('30-06-2016', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2015, 4, 'R', null, null, to_date('31-03-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2016, 4, 'R', null, null, to_date('31-12-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2017, 4, 'R', null, null, to_date('31-12-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2018, 4, 'R', null, null, to_date('31-12-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2025, 1, 'D', null, null, to_date('30-06-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2025, 2, 'R', null, null, to_date('31-12-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2025, 3, 'V', null, 'U', to_date('16-06-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2025, 4, 'V', null, 'A', to_date('16-06-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2025, 5, 'V', null, 'S', to_date('16-12-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2022, 1, 'D', null, null, to_date('30-06-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2022, 2, 'V', null, 'A', to_date('16-06-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2022, 3, 'V', null, 'S', to_date('16-12-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2022, 4, 'R', null, null, to_date('31-12-2027', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2023, 5, 'V', null, 'U', to_date('16-06-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2022, 5, 'V', null, 'U', to_date('16-06-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2021, 5, 'V', null, 'U', to_date('16-06-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2020, 5, 'V', null, 'U', to_date('16-06-2020', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2024, 1, 'D', null, null, to_date('30-06-2025', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2024, 2, 'R', null, null, to_date('31-12-2029', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2024, 3, 'V', null, 'U', to_date('17-06-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2024, 4, 'V', null, 'A', to_date('17-06-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2024, 5, 'V', null, 'S', to_date('16-12-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2021, 1, 'D', null, null, to_date('30-06-2022', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2021, 2, 'R', null, null, to_date('31-12-2026', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2021, 3, 'V', null, 'A', to_date('16-06-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2021, 4, 'V', null, 'S', to_date('16-12-2021', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2023, 1, 'D', null, null, to_date('30-06-2024', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2023, 2, 'R', null, null, to_date('31-12-2028', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2023, 3, 'V', null, 'A', to_date('16-06-2023', 'dd-mm-yyyy'), null, null);

insert into scadenze (TIPO_TRIBUTO, ANNO, SEQUENZA, TIPO_SCADENZA, RATA, TIPO_VERSAMENTO, DATA_SCADENZA, GRUPPO_TRIBUTO, TIPO_OCCUPAZIONE)
values ('ICI', 2023, 4, 'V', null, 'S', to_date('16-12-2023', 'dd-mm-yyyy'), null, null);

ALTER TABLE scadenze ENABLE ALL TRIGGERS;
