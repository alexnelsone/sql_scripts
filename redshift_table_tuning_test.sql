CREATE SCHEMA redshift_test;

CREATE TABLE redshift_test.part
(
  p_partkey     INTEGER NOT NULL,
  p_name        VARCHAR(22) NOT NULL,
  p_mfgr        VARCHAR(6) NOT NULL,
  p_category    VARCHAR(7) NOT NULL,
  p_brand1      VARCHAR(9) NOT NULL,
  p_color       VARCHAR(11) NOT NULL,
  p_type        VARCHAR(25) NOT NULL,
  p_size        INTEGER NOT NULL,
  p_container   VARCHAR(10) NOT NULL
);

CREATE TABLE redshift_test.supplier
(
  s_suppkey   INTEGER NOT NULL,
  s_name      VARCHAR(25) NOT NULL,
  s_address   VARCHAR(25) NOT NULL,
  s_city      VARCHAR(10) NOT NULL,
  s_nation    VARCHAR(15) NOT NULL,
  s_region    VARCHAR(12) NOT NULL,
  s_phone     VARCHAR(15) NOT NULL
);

CREATE TABLE redshift_test.customer
(
  c_custkey      INTEGER NOT NULL,
  c_name         VARCHAR(25) NOT NULL,
  c_address      VARCHAR(25) NOT NULL,
  c_city         VARCHAR(10) NOT NULL,
  c_nation       VARCHAR(15) NOT NULL,
  c_region       VARCHAR(12) NOT NULL,
  c_phone        VARCHAR(15) NOT NULL,
  c_mktsegment   VARCHAR(10) NOT NULL
);

CREATE TABLE redshift_test.dwdate
(
  d_datekey            INTEGER NOT NULL,
  d_date               VARCHAR(19) NOT NULL,
  d_dayofweek          VARCHAR(10) NOT NULL,
  d_month              VARCHAR(10) NOT NULL,
  d_year               INTEGER NOT NULL,
  d_yearmonthnum       INTEGER NOT NULL,
  d_yearmonth          VARCHAR(8) NOT NULL,
  d_daynuminweek       INTEGER NOT NULL,
  d_daynuminmonth      INTEGER NOT NULL,
  d_daynuminyear       INTEGER NOT NULL,
  d_monthnuminyear     INTEGER NOT NULL,
  d_weeknuminyear      INTEGER NOT NULL,
  d_sellingseason      VARCHAR(13) NOT NULL,
  d_lastdayinweekfl    VARCHAR(1) NOT NULL,
  d_lastdayinmonthfl   VARCHAR(1) NOT NULL,
  d_holidayfl          VARCHAR(1) NOT NULL,
  d_weekdayfl          VARCHAR(1) NOT NULL
);

CREATE TABLE redshift_test.lineorder
(
  lo_orderkey          INTEGER NOT NULL,
  lo_linenumber        INTEGER NOT NULL,
  lo_custkey           INTEGER NOT NULL,
  lo_partkey           INTEGER NOT NULL,
  lo_suppkey           INTEGER NOT NULL,
  lo_orderdate         INTEGER NOT NULL,
  lo_orderpriority     VARCHAR(15) NOT NULL,
  lo_shippriority      VARCHAR(1) NOT NULL,
  lo_quantity          INTEGER NOT NULL,
  lo_extendedprice     INTEGER NOT NULL,
  lo_ordertotalprice   INTEGER NOT NULL,
  lo_discount          INTEGER NOT NULL,
  lo_revenue           INTEGER NOT NULL,
  lo_supplycost        INTEGER NOT NULL,
  lo_tax               INTEGER NOT NULL,
  lo_commitdate        INTEGER NOT NULL,
  lo_shipmode          VARCHAR(10) NOT NULL
);


copy redshift_test.customer from 's3://awssampledbuswest2/ssbgz/customer'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip compupdate off region 'us-west-2';

copy redshift_test.dwdate from 's3://awssampledbuswest2/ssbgz/dwdate'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip compupdate off region 'us-west-2';


copy redshift_test.lineorder from 's3://awssampledbuswest2/ssbgz/lineorder'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip compupdate off region 'us-west-2';

copy redshift_test.part from 's3://awssampledbuswest2/ssbgz/part'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip compupdate off region 'us-west-2';

copy redshift_test.supplier from 's3://awssampledbuswest2/ssbgz/supplier'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip compupdate off region 'us-west-2';


select stv_tbl_perm.name as table, count(*) as mb
from stv_blocklist, stv_tbl_perm
where stv_blocklist.tbl = stv_tbl_perm.id
and stv_blocklist.slice = stv_tbl_perm.slice
and stv_tbl_perm.name in ('lineorder','part','customer','dwdate','supplier')
group by stv_tbl_perm.name
order by 1 asc;

set enable_result_cache_for_session to off;

select sum(lo_extendedprice*lo_discount) as revenue
from redshift_test.lineorder, redshift_test.dwdate
where lo_orderdate = d_datekey
and d_year = 1997
and lo_discount between 1 and 3
and lo_quantity < 24;

select sum(lo_revenue), d_year, p_brand1
from redshift_test.lineorder, redshift_test.dwdate, redshift_test.part, redshift_test.supplier
where lo_orderdate = d_datekey
and lo_partkey = p_partkey
and lo_suppkey = s_suppkey
and p_category = 'MFGR#12'
and s_region = 'AMERICA'
group by d_year, p_brand1
order by d_year, p_brand1;


select c_city, s_city, d_year, sum(lo_revenue) as revenue
from redshift_test.customer, redshift_test.lineorder, redshift_test.supplier, redshift_test.dwdate
where lo_custkey = c_custkey
and lo_suppkey = s_suppkey
and lo_orderdate = d_datekey
and (c_city='UNITED KI1' or
c_city='UNITED KI5')
and (s_city='UNITED KI1' or
s_city='UNITED KI5')
and d_yearmonth = 'Dec1997'
group by c_city, s_city, d_year
order by d_year asc, revenue desc;

explain
select sum(lo_revenue), d_year, p_brand1
from redshift_test.lineorder, redshift_test.dwdate, redshift_test.part, redshift_test.supplier
where lo_orderdate = d_datekey
and lo_partkey = p_partkey
and lo_suppkey = s_suppkey
and p_category = 'MFGR#12'
and s_region = 'AMERICA'
group by d_year, p_brand1
order by d_year, p_brand1;

select col, max(blocknum)
from stv_blocklist b, stv_tbl_perm p
where (b.tbl=p.id) and name ='lineorder'
and col < 17
group by name, col
order by col;

create table redshift_test.encodingshipmode (
moderaw varchar(22) encode raw,
modebytedict varchar(22) encode bytedict,
modelzo varchar(22) encode lzo,
moderunlength varchar(22) encode runlength,
modetext255 varchar(22) encode text255,
modetext32k varchar(22) encode text32k);


insert into redshift_test.encodingshipmode
select lo_shipmode as moderaw, lo_shipmode as modebytedict, lo_shipmode as modelzo,
lo_shipmode as moderunlength, lo_shipmode as modetext255,
lo_shipmode as modetext32k
from redshift_test.lineorder where lo_orderkey < 200000000;


select col, max(blocknum)
from stv_blocklist b, stv_tbl_perm p
where (b.tbl=p.id) and name = 'encodingshipmode'
and col < 6
group by name, col
order by col;


analyze compression redshift_test.lineorder;

drop table redshift_test.part cascade;
drop table redshift_test.supplier cascade;
drop table redshift_test.customer cascade;
drop table redshift_test.dwdate cascade;
drop table redshift_test.lineorder cascade;


-- RECREATE THE TABLES USING SQL ABOVE

copy redshift_test.customer from 's3://awssampledbuswest2/ssbgz/customer'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip region 'us-west-2';

copy redshift_test.dwdate from 's3://awssampledbuswest2/ssbgz/dwdate'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip region 'us-west-2';


copy redshift_test.lineorder from 's3://awssampledbuswest2/ssbgz/lineorder'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip region 'us-west-2';

copy redshift_test.part from 's3://awssampledbuswest2/ssbgz/part'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip region 'us-west-2';

copy redshift_test.supplier from 's3://awssampledbuswest2/ssbgz/supplier'
iam_role 'arn:aws:iam::763946354916:role/medbia-redshift-s3-role'
gzip region 'us-west-2';


select trim(name) as table, slice, sum(num_values) as rows, min(minvalue), max(maxvalue)
from svv_diskusage
where name in ('customer', 'part', 'supplier', 'dwdate', 'lineorder')
and col =0
group by name, slice
order by name, slice;
