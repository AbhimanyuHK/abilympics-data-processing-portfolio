-- Sample dataset for Travel Reservation & Data Management System
-- Canonical clean baseline for Access, LibreOffice Base, and SQL practice.
-- Status domains are normalized into reference tables.

INSERT INTO country (country_id, country_code, country_name) VALUES
(1,'IND','India'),
(2,'FIN','Finland'),
(3,'DEU','Germany'),
(4,'JPN','Japan'),
(5,'FRA','France'),
(6,'USA','United States');

INSERT INTO member_status (status_id, status_code, status_name) VALUES
(1,'ACTIVE','Active'),
(2,'INACTIVE','Inactive');

INSERT INTO reservation_status (status_id, status_code, status_name) VALUES
(1,'RESERVED','Reserved'),
(2,'CANCELLED','Cancelled'),
(3,'COMPLETED','Completed');

INSERT INTO member (member_id, first_name, last_name, email, country_id, membership_date, status_id) VALUES
(1001,'Ananya','Rao','ananya.rao@example.org',1,'2024-01-15',1),
(1002,'Daniel','Klein','daniel.klein@example.org',3,'2023-08-20',1),
(1003,'Mika','Korhonen','mika.korhonen@example.org',2,'2022-05-10',1),
(1004,'Yuki','Tanaka','yuki.tanaka@example.org',4,'2024-03-12',1),
(1005,'Claire','Martin','claire.martin@example.org',5,'2021-11-01',2),
(1006,'Noah','Williams','noah.williams@example.org',6,'2023-02-18',1),
(1007,'Kiran','Shah','kiran.shah@example.org',1,'2025-01-05',1),
(1008,'Sofia','Laurent','sofia.laurent@example.org',5,'2025-04-21',1);

INSERT INTO travel (travel_id, destination, country_id, departure_date, return_date, price) VALUES
(2001,'Helsinki',2,'2027-05-06','2027-05-14',1450.00),
(2002,'Berlin',3,'2027-06-10','2027-06-16',980.00),
(2003,'Tokyo',4,'2027-07-03','2027-07-14',1650.00),
(2004,'Paris',5,'2027-08-11','2027-08-18',1200.00),
(2005,'New York',6,'2027-09-02','2027-09-12',1850.00),
(2006,'Mumbai',1,'2027-10-05','2027-10-09',620.00);

INSERT INTO airline (airline_id, airline_name, country_id) VALUES
(3001,'Finnair',2),
(3002,'Lufthansa',3),
(3003,'Japan Airlines',4),
(3004,'Air France',5),
(3005,'Delta Air Lines',6),
(3006,'Air India',1);

INSERT INTO schedule (schedule_id, travel_id, airline_id, departure_time, arrival_time, gate) VALUES
(4001,2001,3001,'2027-05-06 09:00:00','2027-05-06 15:30:00','A12'),
(4002,2002,3002,'2027-06-10 10:15:00','2027-06-10 17:05:00','B04'),
(4003,2003,3003,'2027-07-03 11:30:00','2027-07-04 06:20:00','C21'),
(4004,2004,3004,'2027-08-11 08:45:00','2027-08-11 14:10:00','D08'),
(4005,2005,3005,'2027-09-02 13:00:00','2027-09-02 21:45:00','E15'),
(4006,2006,3006,'2027-10-05 07:20:00','2027-10-05 09:15:00','F02');

INSERT INTO reservation (reservation_id, member_id, schedule_id, reservation_date, status_id, seat_number) VALUES
(5001,1001,4001,'2026-09-10',1,'12A'),
(5002,1002,4002,'2026-09-11',1,'08C'),
(5003,1003,4001,'2026-09-12',3,'03B'),
(5004,1004,4003,'2026-09-15',1,'14D'),
(5005,1005,4004,'2026-09-16',2,'22A'),
(5006,1006,4005,'2026-09-17',1,'18F'),
(5007,1007,4006,'2026-09-18',1,'05A'),
(5008,1008,4004,'2026-09-19',3,'09C'),
(5009,1001,4003,'2026-09-20',1,'16B'),
(5010,1002,4005,'2026-09-21',2,'20D'),
(5011,1007,4001,'2026-09-22',1,'11C'),
(5012,1006,4002,'2026-09-23',3,'07A');
