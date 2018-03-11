create table datapoints(pid INTEGER, x float, y float, primary key(pid));
create table centroids(cid INTEGER, x float, y float, primary key(cid));
create table kmeans(pid INTEGER, cid INTEGER,distance float, foreign key(pid) references datapoints(pid));


insert into datapoints values (1,1.0,1.0),(2,1.5,2.0),(3,3.0,4.0),(4,5.0,7.0),(5,3.5,5.0),(6,4.5,5.0),(7,3.5,4.5);



create or replace function centroids_initialize(k INTEGER) returns void as
$$
DECLARE
	count INTEGER := 1 ;
	temp1 datapoints%ROWTYPE;
	temp2 centroids%ROWTYPE;
BEGIN
	delete from centroids;
	for iter in 1..k LOOP
		insert into centroids values (iter, (select random()*(max(d.x)-min(d.x))+1 from datapoints d) ,(select random()*((max(d1.y)-min(d1.y))+1) from datapoints d1) );
		
		
		
		
	END LOOP;
	
	delete from kmeans;
		for temp1 in select * from datapoints LOOP
		insert into kmeans values (temp1.pid,0,0);
		end loop;
	
	
END
$$ language plpgsql;

create or replace function kmeans(k INTEGER) returns void as
$$
DECLARE
	point datapoints%ROWTYPE;
	cent centroids%ROWTYPE;
	
	dist FLOAT;
	
BEGIN
	perform centroids_initialize(k);
	for iter in 1..20 LOOP
	for point in select * from datapoints LOOP
	dist:= ((point.x - (select x from centroids where cid=1))^2 + (point.y - (select y from centroids where cid=1))^2)^0.5;
		for cent in select * from centroids LOOP
		if (((point.x - cent.x)^2 + (point.y-cent.y)^2)^0.5 <= dist) then
		dist:= ((point.x - cent.x)^2 + (point.y-cent.y)^2)^0.5;
		update kmeans set cid= cent.cid, distance=dist where pid= point.pid;
		end if;
		END LOOP;
	END LOOP;

	for cent1 in 1..k LOOP
	if((select count(pid) from kmeans where cid=cent1) > 0) then
	update centroids set x = (select avg(d.x) from datapoints d, kmeans k1 where d.pid = k1.pid and k1.cid=cent1 ), y= (select avg(d.y) from datapoints d, kmeans k1 where d.pid=k1.pid and k1.cid=cent1) where cid = cent1;
	end if;
	END LOOP;
	END LOOP;
	
END;
$$ LANGUAGE plpgsql; 

select * from kmeans(3);
select * from kmeans; 