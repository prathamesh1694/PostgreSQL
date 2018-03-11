create table R(a integer);
create table S(b integer);


insert into R values (1),(2),(3);
insert into S values (2),(3),(4);

create or replace function map(key integer, value text) returns table(key1 integer, value1 text) as
$$
DECLARE
BEGIN
	return query select key,value;
END;
$$ language plpgsql;


create or replace function reduce(key integer, values1 text[]) returns table(key2 integer) as
$$
DECLARE

BEGIN
	if (select 'R' in (select * from unnest(values1)))  and (select 'S' not in (select * from unnest(values1))) then
       return query select key;
    end if;
END;
$$ language plpgsql;
       
       
--Map Phase
drop table if exists output_map;
select x.key1 as key,x.value1 as value into output_map
       from ((select distinct t1.key1, t1.value1 from R r , LATERAL(select k.key1, k.value1 from map(r.a,'R')k)t1 )
             union
            	(select distinct t2.key1,t2.value1 from S s, LATERAL(select k1.key1,k1.value1 from map(s.b,'S')k1)t2))x;
--Group Phase
drop table if exists input_reduce;
select distinct var.key as key, (select array(select a.value from output_map a where a.key=var.key)) as values1 into input_reduce
       from output_map var;
       
--Reduce Phase
select var.key2 from input_reduce i, LATERAL(select * from reduce(i.key,i.values1))var order by var.key2;