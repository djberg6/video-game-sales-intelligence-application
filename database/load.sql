DROP TABLE IF EXISTS vgsales_staging;

CREATE TABLE vgsales_staging (
	rank		TEXT,
	name		TEXT,
	platform	TEXT,
	year		TEXT,
	genre		TEXT,
	publisher	TEXT,
	na_sales	TEXT,
	eu_sales	TEXT,
	jp_sales	TEXT,
	other_sales	TEXT,
	global_sales	TEXT
);

\copy vgsales_staging FROM 'vgsales.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

UPDATE vgsales_staging
SET publisher = 'Unknown'
WHERE publisher IS NULL OR publisher = 'N/A';

INSERT INTO Publisher (publisher_id, publisher_name)
SELECT ROW_NUMBER() OVER (ORDER BY publisher), publisher
FROM (SELECT DISTINCT publisher FROM vgsales_staging) p;

INSERT INTO Platform (platform_id, platform_name)
SELECT ROW_NUMBER() OVER (ORDER BY platform), platform
FROM (SELECT DISTINCT platform FROM vgsales_staging) p;

INSERT INTO Genre (genre_id, genre_name)
SELECT ROW_NUMBER() OVER (ORDER BY genre), genre
FROM (SELECT DISTINCT genre FROM vgsales_staging) g;

INSERT INTO Region (region_id, region_name) VALUES
	(1, 'North America'),
	(2, 'Europe'),
	(3, 'Japan'),
	(4, 'Other');

INSERT INTO Game (game_id, title, game_rank, release_year, publisher_id, genre_id)
SELECT ROW_NUMBER() OVER (ORDER BY best.game_rank),
	best.name,
	best.game_rank,
	yr.release_year,
	pub.publisher_id,
	gen.genre_id
FROM (
	SELECT DISTINCT ON (name)
		name, rank::INTEGER AS game_rank, publisher, genre
	FROM vgsales_staging
	ORDER BY name, rank::INTEGER
) best
JOIN (
	SELECT name, MIN(NULLIF(year, 'N/A')::INTEGER) AS release_year
	FROM vgsales_staging
	GROUP BY name
) yr ON yr.name = best.name
JOIN Publisher pub ON pub.publisher_name = best.publisher
JOIN Genre gen ON gen.genre_name = best.genre;

INSERT INTO GamePlatform (game_platform_id, release_year, game_id, platform_id)
SELECT ROW_NUMBER() OVER (ORDER BY g.game_id, pl.platform_id),
	s.release_year,
	g.game_id,
	pl.platform_id
FROM (
	SELECT name, platform, MIN(NULLIF(year, 'N/A')::INTEGER) AS release_year
	FROM vgsales_staging
	GROUP BY name, platform
) s
JOIN Game g ON g.title = s.name
JOIN Platform pl ON pl.platform_name = s.platform;

INSERT INTO Sales (sales_id, units_million, game_platform_id, region_id)
SELECT ROW_NUMBER() OVER (ORDER BY gp.game_platform_id, r.region_id),
	r.units,
	gp.game_platform_id,
	r.region_id
FROM (
	SELECT name, platform,
		SUM(na_sales::NUMERIC) AS na,
		SUM(eu_sales::NUMERIC) AS eu,
		SUM(jp_sales::NUMERIC) AS jp,
		SUM(other_sales::NUMERIC) AS other
	FROM vgsales_staging
	GROUP BY name, platform
) s
JOIN Game g ON g.title = s.name
JOIN Platform pl ON pl.platform_name = s.platform
JOIN GamePlatform gp ON gp.game_id = g.game_id AND gp.platform_id = pl.platform_id
CROSS JOIN LATERAL (VALUES
	(1, s.na),
	(2, s.eu),
	(3, s.jp),
	(4, s.other)
) AS r(region_id, units);

DROP TABLE vgsales_staging;