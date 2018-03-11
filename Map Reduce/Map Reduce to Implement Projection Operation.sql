CREATE TABLE R (A integer, B integer); 
insert into R values(1,2),(2,3),(1,4),(2,5),(3,5);
select * from R;


CREATE OR REPLACE FUNCTION Map(A int, B int) RETURNS TABLE (A1 integer, A2 integer) AS 
$$
	SELECT A, A;
$$ LANGUAGE SQL; 

CREATE OR REPLACE FUNCTION Reduce(col1 integer, bags integer[]) 
RETURNS TABLE(A integer, value integer) AS 
$$
	SELECT col1, col1; 
$$ LANGUAGE SQL;

--MAP PHASE
drop table if exists mapresult;
select s.A1 as a, s.A2 as b
into mapresult from R, LATERAL(select t.A1, t.A2 from Map(R.A,R.B)t)s;

--GROUP PHASE
DROP TABLE IF EXISTS groupresult;
SELECT distinct t.A AS A, (select array(select s.B 
                               from  mapresult s
                               where t.A = s.A)) as list
INTO groupresult FROM mapresult t;

--REDUCE PHASE
SELECT q.A AS result
FROM groupresult g1, LATERAL(SELECT * 
                        FROM reduce(g1.A,g1.list)) q order by q.A;
