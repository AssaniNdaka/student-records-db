-- Student Records Management System (MySQL 8.0+)
-- Schema-only script: creates database, tables, and relationship constraints.
-- Author: Assani Ndaka
-- Date: 2025-09-02

-- (Optional) Re-run safety during local testing:
-- DROP DATABASE IF EXISTS student_records_db;

CREATE DATABASE IF NOT EXISTS student_records_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE student_records_db;

-- ==============================
-- 1) Reference Tables
-- ==============================

CREATE TABLE departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(10) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_departments_name (name),
  UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE programs (
  program_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  level ENUM('Certificate','Diploma','Bachelors','Masters','PhD') NOT NULL,
  duration_years TINYINT UNSIGNED NOT NULL DEFAULT 4,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_programs_dept_name (department_id, name),
  CONSTRAINT fk_programs_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (duration_years BETWEEN 1 AND 8)
) ENGINE=InnoDB;

-- ==============================
-- 2) Core Entities
-- ==============================

CREATE TABLE students (
  student_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_number VARCHAR(20) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  gender ENUM('M','F','Other') DEFAULT NULL,
  date_of_birth DATE,
  program_id INT NOT NULL,
  enrollment_year YEAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_students_student_number (student_number),
  UNIQUE KEY uq_students_email (email),
  KEY idx_students_program (program_id),
  CONSTRAINT fk_students_program
    FOREIGN KEY (program_id) REFERENCES programs(program_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (enrollment_year >= 1950)
) ENGINE=InnoDB;

-- One-to-One example with students
CREATE TABLE student_profiles (
  student_id BIGINT PRIMARY KEY,
  national_id VARCHAR(30) UNIQUE,
  address VARCHAR(255),
  emergency_contact_name VARCHAR(100),
  emergency_contact_phone VARCHAR(20),
  CONSTRAINT fk_profiles_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE instructors (
  instructor_id INT AUTO_INCREMENT PRIMARY KEY,
  staff_number VARCHAR(20) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  department_id INT NOT NULL,
  hire_date DATE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_instructors_staff_number (staff_number),
  UNIQUE KEY uq_instructors_email (email),
  KEY idx_instructors_department (department_id),
  CONSTRAINT fk_instructors_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  code VARCHAR(20) NOT NULL,
  title VARCHAR(150) NOT NULL,
  credits TINYINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_courses_code (code),
  KEY idx_courses_department (department_id),
  CONSTRAINT fk_courses_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (credits BETWEEN 1 AND 10)
) ENGINE=InnoDB;

-- Many-to-Many between instructors and courses
CREATE TABLE course_instructors (
  course_id INT NOT NULL,
  instructor_id INT NOT NULL,
  PRIMARY KEY (course_id, instructor_id),
  CONSTRAINT fk_ci_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ci_instructor FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Many-to-Many between students and courses via enrollments
CREATE TABLE enrollments (
  enrollment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  course_id INT NOT NULL,
  academic_year YEAR NOT NULL,
  term ENUM('1','2','3') NOT NULL COMMENT '1=Term 1, 2=Term 2, 3=Term 3',
  enrolled_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  status ENUM('ENROLLED','DROPPED','COMPLETED') NOT NULL DEFAULT 'ENROLLED',
  UNIQUE KEY uq_enrollment (student_id, course_id, academic_year, term),
  KEY idx_enrollments_student (student_id),
  KEY idx_enrollments_course (course_id),
  CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- One-to-One with enrollments to record a final grade
CREATE TABLE grades (
  enrollment_id BIGINT PRIMARY KEY,
  grade ENUM('A','B','C','D','E','F','I') NOT NULL,
  score DECIMAL(5,2) CHECK (score >= 0 AND score <= 100),
  graded_on DATE,
  CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==============================
-- (Optional) Sample seed data for local testing
-- Comment out if your lecturer requires schema only
-- ==============================
/*
INSERT INTO departments (name, code) VALUES
('Computer Science', 'CS'),
('Mathematics', 'MATH');

INSERT INTO programs (department_id, name, level, duration_years) VALUES
(1, 'BSc Computer Science', 'Bachelors', 4),
(2, 'BSc Mathematics', 'Bachelors', 4);

INSERT INTO students (student_number, first_name, last_name, email, program_id, enrollment_year)
VALUES
('S2025-0001', 'Amina', 'Khan', 'amina.khan@example.edu', 1, 2025),
('S2025-0002', 'John', 'Otieno', 'john.otieno@example.edu', 2, 2025);

INSERT INTO instructors (staff_number, first_name, last_name, email, department_id) VALUES
('T-100', 'Grace', 'Mwangi', 'grace.mwangi@example.edu', 1),
('T-101', 'Peter', 'Mutua', 'peter.mutua@example.edu', 2);

INSERT INTO courses (department_id, code, title, credits) VALUES
(1, 'CS101', 'Intro to Programming', 4),
(2, 'MATH101', 'Calculus I', 4);

INSERT INTO course_instructors (course_id, instructor_id) VALUES
(1, 1),
(2, 2);

INSERT INTO enrollments (student_id, course_id, academic_year, term, status) VALUES
(1, 1, 2025, '1', 'ENROLLED'),
(2, 2, 2025, '1', 'ENROLLED');

INSERT INTO grades (enrollment_id, grade, score, graded_on) VALUES
(1, 'A', 92.50, '2025-06-30');
*/
