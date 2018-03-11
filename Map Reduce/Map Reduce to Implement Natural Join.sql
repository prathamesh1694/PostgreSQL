create type temp_array as (rel TEXT, col INTEGER);
create table R(A integer, B integer);
create table S(B integer, C integer);
insert into R values (1,2),(3,4);
insert into S values (2,3),(4,5);
create or replace function map(k integer, tablename text) returns table(key integer, value temp_array) as
$$
DECLARE
	temp1 temp_array;
BEGIN
	select tablename into temp1.rel;
    if(tablename='R') then
		select a into temp1.col from R where b=k;   
    end if;
    if(tablename='S') then
    	select c into temp1.col from S where b=k;
     end if;
     return query select k, temp1;
END;
$$ language plpgsql;


create or replace function reduce1(key integer, values1 temp_array[]) returns table(a integer, b integer, c integer) as 
$$
DECLARE
	temp1 temp_array;
    rec record;
    i int:=0;
    a int;
    b int;
    
BEGIN
	
    for rec in select * from unnest(values1) loop
    	if rec.rel='R' then
        	a=rec.col;   
        else 
        	c=rec.col;
        end if;
        i=i+1;
    end loop;
    if i>1 then
    return  query select a,key,c;
    end if;
END;
$$ language plpgsql;


--MAP PHASE

drop table if exists output_map;
select x.key as key, x.value as values1 into output_map 
			from ((select t1.key,t1.value from R r , LATERAL(select m1.key,m1.value from map(r.b,'R')m1)t1) 
                  union 
                  (select t2.key,t2.value from S s, LATERAL(select m2.key,m2.value from map(s.b,'S')m2)t2))x;
--GROUP PHASE

drop table if exists input_reduce;

select distinct m.key as key, (select array(select m2.values1 from output_map m2 where m2.key=m.key)) as values1 into input_reduce 
					from output_map m;
                    
--REDUCE PHASE
select x.a,x.b,x.c from input_reduce r, LATERAL(select r1.a,r1.b,r1.c from reduce1(r.key,r.values1)r1)x;