-- UP Script

-- Create LOGS Table first to avoid circular dependency
CREATE TABLE LOGS (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    details TEXT,
    performed_by INT
);

-- Create USERS Table
CREATE TABLE USERS (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'Researcher', 'Viewer') DEFAULT 'Viewer',
    creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Now add the foreign key to LOGS
ALTER TABLE LOGS
ADD CONSTRAINT fk_logs_users
FOREIGN KEY (performed_by) REFERENCES USERS(user_id) ON DELETE SET NULL;

-- Create USER_LOGS Table (removed circular dependency)
CREATE TABLE USER_LOGS (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    username VARCHAR(50) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    performed_by INT,
    FOREIGN KEY (performed_by) REFERENCES USERS(user_id) ON DELETE SET NULL
);

-- Create DATASET_DETAILS Table
CREATE TABLE DATASET_DETAILS (
    dataset_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_name VARCHAR(255) NOT NULL,
    dataset_date DATE NOT NULL,
    researcher VARCHAR(100),
    notes TEXT,
    created_by INT,
    FOREIGN KEY (created_by) REFERENCES USERS(user_id) ON DELETE SET NULL
);

-- Create DATASETS Table with indexes
CREATE TABLE DATASETS (
    dataset_id INT NOT NULL,
    sample_ref INT NOT NULL,
    frequency_of_sampling INT,
    pressure FLOAT,
    tempr FLOAT,
    M1 FLOAT,
    M2 FLOAT,
    M3 FLOAT,
    A1 FLOAT,
    A2 FLOAT,
    A3 FLOAT,
    Aw1 FLOAT,
    Aw2 FLOAT,
    Aw3 FLOAT,
    Mw1 FLOAT,
    Mw2 FLOAT,
    Mw3 FLOAT,
    Pitch FLOAT,
    Head FLOAT,
    Roll FLOAT,
    PRIMARY KEY (dataset_id, sample_ref),
    FOREIGN KEY (dataset_id) REFERENCES DATASET_DETAILS(dataset_id) ON DELETE CASCADE,
    INDEX idx_pressure (pressure),
    INDEX idx_sample_ref (sample_ref)
);

-- Create BEHAVIOR_TYPES Table
CREATE TABLE BEHAVIOR_TYPES (
    behavior_type_id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(255) UNIQUE NOT NULL
);

-- Create ANNOTATIONS Table with constraints and indexes
CREATE TABLE ANNOTATIONS (
    annotation_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_id INT NOT NULL,
    start_sample INT NOT NULL,
    end_sample INT NOT NULL,
    classification_label VARCHAR(255) NOT NULL,
    behavior_type VARCHAR(255),
    confidence_score FLOAT,
    FOREIGN KEY (dataset_id) REFERENCES DATASET_DETAILS(dataset_id) ON DELETE CASCADE,
    FOREIGN KEY (behavior_type) REFERENCES BEHAVIOR_TYPES(label),
    CONSTRAINT check_samples CHECK (start_sample <= end_sample),
    INDEX idx_classification (classification_label),
    INDEX idx_behavior_type (behavior_type)
);

-- Create ANNOTATION_HISTORY Table
CREATE TABLE ANNOTATION_HISTORY (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    annotation_id INT NOT NULL,
    previous_behavior_label VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(50),
    reason_for_change TEXT,
    FOREIGN KEY (annotation_id) REFERENCES ANNOTATIONS(annotation_id) ON DELETE CASCADE
);

-- Create IMPORT_LOGS Table
CREATE TABLE IMPORT_LOGS (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    file_path VARCHAR(255) NOT NULL,
    error_message TEXT,
    dataset_id INT,
    performed_by INT,
    import_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES DATASET_DETAILS(dataset_id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES USERS(user_id) ON DELETE SET NULL
);

-- Create DERIVED_METRICS Table
CREATE TABLE DERIVED_METRICS (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_id INT NOT NULL,
    dive_id INT,
    metric_name VARCHAR(255) NOT NULL,
    metric_value FLOAT NOT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES DATASET_DETAILS(dataset_id) ON DELETE CASCADE
);

-- Create DIVE_STATS Table with constraints
CREATE TABLE DIVE_STATS (
    dive_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_id INT NOT NULL,
    start_time INT NOT NULL,
    end_time INT NOT NULL,
    max_depth FLOAT NOT NULL,
    time_max_depth INT,
    duration INT NOT NULL,
    dest_st INT,
    dest_et INT,
    dest_dur INT,
    to_dur INT,
    from_dur INT,
    to_rate FLOAT,
    from_rate FLOAT,
    additional_metrics JSON,
    FOREIGN KEY (dataset_id) REFERENCES DATASET_DETAILS(dataset_id) ON DELETE CASCADE,
    CONSTRAINT check_times CHECK (start_time <= end_time)
);

-- Add foreign key to DERIVED_METRICS after DIVE_STATS creation
ALTER TABLE DERIVED_METRICS
ADD CONSTRAINT fk_derived_metrics_dive
FOREIGN KEY (dive_id) REFERENCES DIVE_STATS(dive_id);

-- Create MACHINE_LEARNING_MODELS Table
CREATE TABLE MACHINE_LEARNING_MODELS (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(255) NOT NULL,
    trained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ML_CLASSIFICATIONS Table with indexes
CREATE TABLE ML_CLASSIFICATIONS (
    classification_id INT AUTO_INCREMENT PRIMARY KEY,
    dive_id INT NOT NULL,
    event_t0 BIGINT NOT NULL,
    event_tn BIGINT NOT NULL,
    label VARCHAR(255) NOT NULL,
    model_id INT NOT NULL,
    confidence_score FLOAT NOT NULL,
    FOREIGN KEY (dive_id) REFERENCES DIVE_STATS(dive_id) ON DELETE CASCADE,
    FOREIGN KEY (model_id) REFERENCES MACHINE_LEARNING_MODELS(model_id) ON DELETE CASCADE,
    INDEX idx_label_confidence (label, confidence_score)
);

-- Create Views
CREATE VIEW DatasetSummary AS
SELECT 
    d.dataset_id,
    d.dataset_name,
    d.dataset_date,
    a.annotation_id,
    a.start_sample,
    a.end_sample,
    a.classification_label,
    a.behavior_type,
    m.metric_id,
    m.metric_name,
    m.metric_value
FROM DATASET_DETAILS d
LEFT JOIN ANNOTATIONS a ON d.dataset_id = a.dataset_id
LEFT JOIN DERIVED_METRICS m ON d.dataset_id = m.dataset_id;

CREATE VIEW DiveClassificationSummary AS
SELECT 
    ds.dive_id,
    ds.dataset_id,
    ds.start_time,
    ds.end_time,
    ds.max_depth,
    c.classification_id,
    c.label,
    c.confidence_score
FROM DIVE_STATS ds
LEFT JOIN ML_CLASSIFICATIONS c ON ds.dive_id = c.dive_id;

-- Create Procedures
DELIMITER //

CREATE PROCEDURE UploadDataset(
    IN csv_file_path VARCHAR(255),
    IN user_id INT
)
BEGIN
    DECLARE import_count INT;
    
    -- Check rate limiting
    SELECT COUNT(*) INTO import_count 
    FROM IMPORT_LOGS 
    WHERE performed_by = user_id 
    AND import_time > DATE_SUB(NOW(), INTERVAL 1 HOUR);
    
    IF import_count > 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rate limit exceeded. Please try again later.';
    END IF;

    -- Validate input
    IF csv_file_path IS NULL OR LENGTH(csv_file_path) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CSV file path is missing or invalid.';
    END IF;

    -- Proceed with import
    LOAD DATA INFILE csv_file_path
    INTO TABLE DATASETS
    FIELDS TERMINATED BY ',' 
    ENCLOSED BY '"' 
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;
END //

CREATE PROCEDURE UploadAnnotations(
    IN csv_file_path VARCHAR(255),
    IN user_id INT
)
BEGIN
    DECLARE import_count INT;
    
    -- Check rate limiting
    SELECT COUNT(*) INTO import_count 
    FROM IMPORT_LOGS 
    WHERE performed_by = user_id 
    AND import_time > DATE_SUB(NOW(), INTERVAL 1 HOUR);
    
    IF import_count > 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rate limit exceeded. Please try again later.';
    END IF;

    IF csv_file_path IS NULL OR LENGTH(csv_file_path) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CSV file path is missing or invalid.';
    END IF;

    LOAD DATA INFILE csv_file_path
    INTO TABLE ANNOTATIONS
    FIELDS TERMINATED BY ',' 
    ENCLOSED BY '"' 
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;
END //

-- Create Triggers
CREATE TRIGGER LogAnnotationChange
AFTER UPDATE ON ANNOTATIONS
FOR EACH ROW
BEGIN
    INSERT INTO ANNOTATION_HISTORY (annotation_id, previous_behavior_label, updated_at, updated_by, reason_for_change)
    VALUES (
        OLD.annotation_id,
        OLD.classification_label,
        NOW(),
        USER(),
        'Classification or behavior type updated.'
    );
END //

CREATE TRIGGER LogDatasetInsert   
AFTER INSERT ON DATASET_DETAILS
FOR EACH ROW
BEGIN
    INSERT INTO LOGS (log_timestamp, table_name, operation, details, performed_by)
    VALUES (
        NOW(),
        'DATASET_DETAILS',
        'INSERT',
        CONCAT('New dataset added: ', NEW.dataset_name),
        NEW.created_by
    );
END //

DELIMITER ;

-- Grant statements for different roles
GRANT SELECT ON WDAS.* TO 'viewer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON WDAS.* TO 'researcher'@'localhost';
GRANT ALL PRIVILEGES ON WDAS.* TO 'admin'@'localhost';

-- DOWN Script
DROP TRIGGER IF EXISTS LogDatasetInsert;
DROP TRIGGER IF EXISTS LogAnnotationChange;
DROP PROCEDURE IF EXISTS UploadAnnotations;
DROP PROCEDURE IF EXISTS UploadDataset;
DROP VIEW IF EXISTS DiveClassificationSummary;
DROP VIEW IF EXISTS DatasetSummary;
DROP TABLE IF EXISTS ML_CLASSIFICATIONS;
DROP TABLE IF EXISTS MACHINE_LEARNING_MODELS;
DROP TABLE IF EXISTS DERIVED_METRICS;
DROP TABLE IF EXISTS DIVE_STATS;
DROP TABLE IF EXISTS IMPORT_LOGS;
DROP TABLE IF EXISTS ANNOTATION_HISTORY;
DROP TABLE IF EXISTS ANNOTATIONS;
DROP TABLE IF EXISTS BEHAVIOR_TYPES;
DROP TABLE IF EXISTS DATASETS;
DROP TABLE IF EXISTS DATASET_DETAILS;
DROP TABLE IF EXISTS USER_LOGS;
DROP TABLE IF EXISTS LOGS;
DROP TABLE IF EXISTS USERS;
DROP USER IF EXISTS 'viewer'@'localhost';
DROP USER IF EXISTS 'researcher'@'localhost';
DROP USER IF EXISTS 'admin'@'localhost';
