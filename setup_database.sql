DROP DATABASE test;
DELETE FROM mysql.user WHERE host <> 'localhost' or user = '';
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('testtest');
CREATE DATABASE my_database DEFAULT CHARACTER SET utf8;
CREATE DATABASE my_database DEFAULT CHARACTER SET utf8;
