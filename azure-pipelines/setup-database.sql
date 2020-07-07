CREATE USER 'root' IDENTIFIED BY 'petclinic';
GRANT ALL PRIVILEGES ON petclinic.* TO 'root';
CALL mysql.az_load_timezone();
SELECT name FROM mysql.time_zone_name;
