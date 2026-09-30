CREATE TABLE country (
    country_id INTEGER PRIMARY KEY,
    country_code CHAR(3) NOT NULL UNIQUE,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE member_status (
    status_id SMALLINT PRIMARY KEY,
    status_code VARCHAR(20) NOT NULL UNIQUE,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE reservation_status (
    status_id SMALLINT PRIMARY KEY,
    status_code VARCHAR(20) NOT NULL UNIQUE,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE member (
    member_id INTEGER PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    country_id INTEGER NOT NULL REFERENCES country(country_id),
    membership_date DATE NOT NULL,
    status_id SMALLINT NOT NULL REFERENCES member_status(status_id)
);

CREATE TABLE travel (
    travel_id INTEGER PRIMARY KEY,
    destination VARCHAR(120) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES country(country_id),
    departure_date DATE NOT NULL,
    return_date DATE NOT NULL,
    price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    CHECK (return_date >= departure_date)
);

CREATE TABLE airline (
    airline_id INTEGER PRIMARY KEY,
    airline_name VARCHAR(120) NOT NULL UNIQUE,
    country_id INTEGER NOT NULL REFERENCES country(country_id)
);

CREATE TABLE schedule (
    schedule_id INTEGER PRIMARY KEY,
    travel_id INTEGER NOT NULL REFERENCES travel(travel_id),
    airline_id INTEGER NOT NULL REFERENCES airline(airline_id),
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    gate VARCHAR(20),
    CHECK (arrival_time > departure_time)
);

CREATE TABLE reservation (
    reservation_id INTEGER PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES member(member_id),
    schedule_id INTEGER NOT NULL REFERENCES schedule(schedule_id),
    reservation_date DATE NOT NULL,
    status_id SMALLINT NOT NULL REFERENCES reservation_status(status_id),
    seat_number VARCHAR(10)
);

CREATE INDEX idx_member_country ON member(country_id);
CREATE INDEX idx_member_status ON member(status_id);
CREATE INDEX idx_travel_country ON travel(country_id);
CREATE INDEX idx_schedule_travel ON schedule(travel_id);
CREATE INDEX idx_schedule_airline ON schedule(airline_id);
CREATE INDEX idx_reservation_member ON reservation(member_id);
CREATE INDEX idx_reservation_schedule ON reservation(schedule_id);
CREATE INDEX idx_reservation_status ON reservation(status_id);
