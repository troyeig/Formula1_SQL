-- 1. What tracks have hosted the most grand prix since 1950?
SELECT circuits.name, COUNT(1) AS count
FROM races
INNER JOIN circuits ON races."circuitId" = circuits."circuitId"
GROUP BY circuits.name
ORDER BY count DESC;

-- 2. What constructors have participated in the most championships?
CREATE VIEW constructors_total_seasons AS -- Exclude this line to see results
SELECT "constructorRef", COUNT(1) AS total_seasons
FROM (SELECT year, "constructorRef", COUNT(1) AS total_races
FROM (SELECT *
FROM constructor_results
INNER JOIN races ON constructor_results."raceId" = races."raceId"
INNER JOIN constructors ON constructor_results."constructorId" = constructors."constructorId") AS temp1
GROUP BY year, "constructorRef") AS temp2
GROUP BY "constructorRef"
ORDER BY total_seasons DESC;

-- 3. What drivers have raced in the most grand prix?
CREATE VIEW drivers_total_races AS -- Exclude this line to see results
SELECT "driverRef", COUNT(1) AS total_races
FROM results
INNER JOIN drivers ON results."driverId" = drivers."driverId"
GROUP BY "driverRef"
ORDER BY total_races DESC

-- 4. What drivers have the best average race position?
CREATE VIEW drivers_average_finish AS -- Exclude this line to see results
SELECT "driverRef", AVG(CAST(position AS INT)) as average_finish
FROM results
INNER JOIN drivers ON results."driverId" = drivers."driverId"
WHERE position != '\N'
GROUP BY "driverRef"
ORDER BY average_finish ASC;
-- Excluding drivers with 10 or less races
SELECT drivers_average_finish."driverRef", drivers_average_finish.average_finish
FROM drivers_average_finish
INNER JOIN drivers_total_races ON drivers_average_finish."driverRef" = drivers_total_races."driverRef"
WHERE drivers_total_races.total_races > 10
ORDER BY drivers_average_finish.average_finish ASC;

-- 5. What constructors have the highest average finishing position in the constructor's championship?
CREATE VIEW constructors_average_championship_finish AS -- Exclude this line to see results
SELECT "constructorRef", AVG(rank) AS average_championship_finish
FROM (SELECT year, "constructorRef", SUM(points) as point_total, RANK() OVER (PARTITION BY year ORDER BY SUM(points) DESC) AS rank
FROM (SELECT *
FROM constructor_results
INNER JOIN races ON constructor_results."raceId" = races."raceId"
INNER JOIN constructors ON constructor_results."constructorId" = constructors."constructorId") AS temp1
GROUP BY year, "constructorRef"
ORDER BY year DESC, point_total DESC) AS temp2
GROUP BY "constructorRef"
ORDER BY average_championship_finish ASC;
-- Excluding constructors with 5 or less seasons
SELECT constructors_average_championship_finish."constructorRef", constructors_average_championship_finish.average_championship_finish
FROM constructors_total_seasons
INNER JOIN constructors_average_championship_finish ON constructors_total_seasons."constructorRef" = constructors_average_championship_finish."constructorRef"
WHERE constructors_total_seasons.total_seasons > 5
ORDER BY average_championship_finish ASC;

-- 6. What drivers have the highest average finishing position in the driver's championship?
SELECT "driverRef", AVG(rank) as average_championship_finish
FROM (SELECT "driverRef", year, SUM(CAST(points AS FLOAT)) as point_total, RANK() OVER (PARTITION BY year ORDER BY SUM(CAST(points AS FLOAT)) DESC) AS rank
FROM (SELECT *
FROM results
INNER JOIN races ON results."raceId" = races."raceId"
INNER JOIN drivers ON results."driverId" = drivers."driverId") AS temp1
WHERE position != '\N'
GROUP BY "driverRef", year
ORDER BY year DESC, rank ASC) AS temp2
GROUP BY "driverRef"
ORDER BY average_championship_finish ASC;

-- 7. Who has the most constructor's championships?
SELECT "constructorRef", COUNT(1) AS championships
FROM (SELECT year, "constructorRef", point_total
FROM (SELECT year, "constructorRef", SUM(points) as point_total, RANK() OVER (PARTITION BY year ORDER BY SUM(points) DESC) AS rank
FROM (SELECT *
FROM constructor_results
INNER JOIN races ON constructor_results."raceId" = races."raceId"
INNER JOIN constructors ON constructor_results."constructorId" = constructors."constructorId") AS temp1
GROUP BY year, "constructorRef"
ORDER BY year DESC, point_total DESC) AS temp2
WHERE rank = 1) AS temp3
GROUP BY "constructorRef"
ORDER BY championships DESC;

-- 8. Who has the most driver's championships?
SELECT "driverRef", COUNT(1) as total_championships
FROM (SELECT "driverRef", year, SUM(CAST(points AS FLOAT)) as point_total, RANK() OVER (PARTITION BY year ORDER BY SUM(CAST(points AS FLOAT)) DESC) AS rank
FROM (SELECT *
FROM results
INNER JOIN races ON results."raceId" = races."raceId"
INNER JOIN drivers ON results."driverId" = drivers."driverId") AS temp1
WHERE position != '\N'
GROUP BY "driverRef", year
ORDER BY year DESC, rank ASC) AS temp2
WHERE rank = 1
GROUP BY "driverRef"
ORDER BY total_championships DESC;
