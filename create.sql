CREATE TABLE med_org (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT,
    date_open DATE NOT NULL,
    date_close DATE
);

CREATE TABLE department (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT,
    parent_department_fk INT REFERENCES department(id),
    med_org_fk INT NOT NULL REFERENCES med_org(id),
    date_open DATE NOT NULL,
    date_close DATE
);

CREATE TABLE document_category (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    date_open DATE NOT NULL,
    date_close DATE
);

CREATE TABLE document_type (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    priority INT NOT NULL,
    category_fk INT NOT NULL REFERENCES document_category(id),
    date_open DATE NOT NULL,
    date_close DATE
);

CREATE TABLE patient (
    id INT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    birth_date DATE NOT NULL
);

CREATE TABLE medical_case (
    id INT PRIMARY KEY,
    card_number TEXT NOT NULL,
    patient_fk INT NOT NULL REFERENCES patient(id),
    department_fk INT NOT NULL REFERENCES department(id),
    med_org_fk INT NOT NULL REFERENCES med_org(id),
    date_open DATE NOT NULL,
    date_close DATE NOT NULL,
    CHECK (date_close >= date_open)
);

CREATE TABLE document (
    id INT PRIMARY KEY,
    series TEXT,
    number TEXT NOT NULL,
    type_fk INT NOT NULL REFERENCES document_type(id),
    patient_fk INT NOT NULL REFERENCES patient(id),
    date_open DATE NOT NULL,
    date_close DATE,
    CHECK (date_close IS NULL OR date_close >= date_open)
);

CREATE TABLE accounts (
    id INT PRIMARY KEY,
    med_org_fk INT NOT NULL REFERENCES med_org(id),
    departments INT[] NOT NULL,
    date_open DATE NOT NULL,
    date_close DATE NOT NULL,
    CHECK (date_close >= date_open)
);

CREATE TABLE accounts_data (
    accounts_fk INT NOT NULL REFERENCES accounts(id),
    case_id_fk INT NOT NULL REFERENCES medical_case(id),
    case_card_number TEXT NOT NULL,
    case_date_open DATE NOT NULL,
    case_date_close DATE NOT NULL,
    case_medical_organization INT NOT NULL,
    case_department INT NOT NULL,
    patient_id INT NOT NULL,
    patient_age INT,
    patient_full_name TEXT,
    patient_birth_date DATE,
    document_id INT,
    document_type_code TEXT,
    document_series TEXT,
    document_number TEXT,
    is_filtered BOOLEAN DEFAULT FALSE,
    filter_reason TEXT,
    PRIMARY KEY (accounts_fk, case_id_fk)
);
