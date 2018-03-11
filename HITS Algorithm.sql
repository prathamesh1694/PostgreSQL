create table graph(source integer, target integer);
create table hubs(page integer, hub_score float);
create table authorities(page integer, auth_score float);
insert into graph values (1,3),(2,3),(2,1),(3,5),(5,3),(3,4),(3,8);

create or replace function hub_and_auth_initialize() returns void as
$$
DECLARE

	temp1 INTEGER;
    temp2 INTEGER;

BEGIN
	delete from hubs;
    delete from authorities;
	for temp1 in (select distinct source from graph) LOOP
		insert into hubs values (temp1, 1); 
	END LOOP;
    for temp2 in (select distinct target from graph) loop
    	insert into authorities values (temp2,1);
    end loop;
    

END;
$$Language plpgsql;


create or replace function hubs_and_authorities() returns void as
$$
DECLARE
	norm FLOAT;
	temporary1 INTEGER;
	temporary2 INTEGER;
	temporary3 INTEGER;
	temporary4 INTEGER;
    i integer;
BEGIN
	perform hub_and_auth_initialize();
	for i in 1..20 LOOP
		norm:=0;
		for temporary1 in select page from authorities loop
			update authorities set auth_score =  (select sum(hub_score) from hubs where page in (select source from graph where target=temporary1)) where page=temporary1;
		end loop;
		select sum(auth_score^2) from authorities into norm;
		norm:=norm^0.5;
		for temporary2 in select page from authorities loop
			update authorities set auth_score= ((select auth_score from authorities where page=temporary2)/norm) where page=temporary2;
		end loop;
		norm:=0;
		for temporary3 in select page from hubs loop
			update hubs set hub_score = (select sum(auth_score )from authorities where page in (select target from graph where source=temporary3)) where page=temporary3;
		end loop;
		select sum(hub_score^2) from hubs into norm;
		norm:=norm^0.5;
		for temporary4 in select page from hubs loop
			update hubs set hub_score =((select hub_score from hubs where page=temporary4)/norm) where page=temporary4;
		end loop;
	END LOOP;
END;
$$Language plpgsql;

select * from hubs_and_authorities();
select * from hubs;
select * from authorities;