create table graph(sour integer,target integer,weight integer);
create table paths(target integer,distance integer);
create table inter(tar integer,dis integer);
insert into graph values (0,1,2),(0,4,10),(1,2,3),(1,4,7),(2,3,4),(3,4,5),(4,2,6);
drop function dijkstras(item integer);
create or replace function dijkstras(item integer) returns table(targ1 integer, dist1 integer) as
$$
DECLARE

u integer:=item;
du integer:=0;
minimum integer;
d integer;
x graph%rowtype;
maxdistance float;
temp1 integer;
BEGIN
delete from paths;
delete from inter;
select sum(weight) from graph into maxdistance;
for temp1 in (select distinct sour from graph union select distinct g1.target from graph g1 ) loop
	insert into inter values (temp1,maxdistance+1);
end loop;
insert into paths values (u,0); 
LOOP
	delete from inter where tar = u;
	for x in select * from graph where sour = u loop
		select dis into d from inter where tar = x.target;
		if(d < du + x.weight) then
			minimum = d;
    	else 
    		minimum = du + x.weight;
		end if;

		update inter set dis = minimum where tar = x.target;
	end loop;

	select tar into u from inter where dis = (select min(dis) from inter);
	select min(dis) into du from inter;
	if (select not exists(select * from inter)) then
		exit;
	end if;
	insert into paths values (u,du);		 
END LOOP;
update paths set distance =NULL where distance= maxdistance+1; 
return query select * from paths;
END;
$$ language plpgsql;

select * from dijkstras(0);