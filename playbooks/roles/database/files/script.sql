DROP TABLE IF EXISTS vm2data;
CREATE TABLE vm2data(
    message VARCHAR(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO vm2data (message) VALUES ('Hello World!');