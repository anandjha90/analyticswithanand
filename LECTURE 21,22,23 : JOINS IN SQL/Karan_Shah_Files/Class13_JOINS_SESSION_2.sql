USE DATABASE JOINS_IN_SQL;

USE SCHEMA JOINS_SCHEMA;


-- PRAC1
CREATE TABLE IF NOT EXISTS Employee (
    empId INT PRIMARY KEY,
    name VARCHAR(50),
    supervisor INT,
    salary INT
);

-- Inserting values into the Employee table
INSERT INTO Employee (empId, name, supervisor, salary)
VALUES
(3, 'Brad', NULL, 4000),
(1, 'John', 3, 1000),
(2, 'Dan', 3, 2000),
(4, 'Thomas', 3, 4000);



CREATE TABLE IF NOT EXISTS Bonus (
    empId INT PRIMARY KEY,
    bonus INT
);

-- Inserting values into the Bonus table
INSERT INTO Bonus (empId, bonus)
VALUES
(2, 500),
(4, 2000);










-- changing the dataset
CREATE TABLE IF NOT EXISTS course
(
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    course_desc VARCHAR(100),
    course_tag VARCHAR(20)
);

-- Inserting values into the course table
INSERT INTO course (course_id, course_name, course_desc, course_tag)
VALUES
(101, 'Mathematics', 'Advanced Mathematics Course', 'Math'),
(102, 'Physics', 'Basics of Physics', 'Physics'),
(103, 'Chemistry', 'Chemistry for Beginners', 'Chemistry'),
(104, 'Biology', 'Introduction to Biology', 'Biology'),
(105, 'Computer Science', 'Learn Programming', 'CS'),
(106, 'English Literature', 'Shakespearean Studies', 'English');


CREATE TABLE IF NOT EXISTS student
(
    student_id INT PRIMARY KEY, 
    student_name VARCHAR(50),
    student_mobile BIGINT, 
    student_course_enroll VARCHAR(50),
    student_course_id INT
);

-- Inserting values into the student table
INSERT INTO student (student_id, student_name, student_mobile, student_course_enroll, student_course_id)
VALUES
(201, 'Alice', 9876543210, 'Mathematics', 101),
(202, 'Bob', 9123456789, 'Physics', 102),
(203, 'Charlie', 9988776655, 'Computer Science', 105),
(204, 'David', 9112233445, 'Mathematics', 101),
(205, 'Eve', 9876654321, 'Biology', 104),
(206, 'Frank', 9543212345, 'Philosophy', NULL), -- Student enrolled in non-existent course
(207, 'Grace', 9898989898, 'Chemistry', 103);


CREATE TABLE IF NOT EXISTS instructor
(
    instructor_id INT PRIMARY KEY,
    instructor_name VARCHAR(50),
    course_id INT -- References course.course_id
);

-- Inserting values into the instructor table
INSERT INTO instructor (instructor_id, instructor_name, course_id)
VALUES
(301, 'Dr. Smith', 101),
(302, 'Dr. Johnson', 102),
(303, 'Dr. Lee', 103),
(304, 'Dr. White', 104),
(305, 'Prof. Davis', 105);





-- SELF JOIN UNDERSTANDING
CREATE TABLE IF NOT EXISTS Weather (
    id INT PRIMARY KEY,
    recordDate DATE,
    temperature INT
);

-- Inserting values into the Weather table
INSERT INTO Weather (id, recordDate, temperature)
VALUES
(1, '2015-01-01', 10),
(2, '2015-01-02', 25),
(3, '2015-01-03', 20),
(4, '2015-01-04', 30);




