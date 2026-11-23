CREATE TABLE Publisher (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name VARCHAR(100)
);

CREATE TABLE Platform (
    platform_id INTEGER PRIMARY KEY,
    platform_name VARCHAR(50)
);

CREATE TABLE Genre (
    genre_id INTEGER PRIMARY KEY,
    genre_name VARCHAR(150)
);

CREATE TABLE Region (
    region_id INTEGER PRIMARY KEY,
    region_name VARCHAR(100)
);

CREATE TABLE Game (
    game_id INTEGER PRIMARY KEY,
    title VARCHAR(255),
    game_rank INTEGER,
    release_year INTEGER,
    publisher_id INTEGER NOT NULL,
    genre_id INTEGER,
    FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id),
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id) 
);

CREATE TABLE GamePlatform (
    game_platform_id INTEGER PRIMARY KEY,
    release_year INTEGER,
    game_id INTEGER,
    platform_id INTEGER,
    UNIQUE (game_id, platform_id),
    FOREIGN KEY (game_id) REFERENCES Game(game_id),
    FOREIGN KEY (platform_id) REFERENCES Platform(platform_id)
);

CREATE TABLE Sales (
    sales_id INTEGER PRIMARY KEY,
    units_million NUMERIC,
    game_platform_id INTEGER NOT NULL,
    region_id INTEGER NOT NULL,
    UNIQUE (game_platform_id, region_id),
    FOREIGN KEY (game_platform_id) REFERENCES GamePlatform(game_platform_id),
    FOREIGN KEY (region_id) REFERENCES Region(region_id)
);