CREATE TABLE IF NOT EXISTS performance_test_s3 (
    id INT, 
    squared int, 
    halved double, 
    timesTwo INT, 
    timesThree INT, 
    timesFour INT, 
    timesFive INT, 
    timesSix INT, 
    timesSeven INT, 
    timesEight INT, 
    timesNine INT, 
    timesTen INT) 
PARTITIONED BY (onesPlace INT)
STORED AS ORC 
LOCATION 's3://hive-s3-performance-data-bucket/performance_test_s3';

CREATE TABLE IF NOT EXISTS performance_test_hdfs (
    id INT, 
    squared int, 
    halved double, 
    timesTwo INT, 
    timesThree INT, 
    timesFour INT, 
    timesFive INT, 
    timesSix INT, 
    timesSeven INT, 
    timesEight INT, 
    timesNine INT, 
    timesTen INT) 
PARTITIONED BY (onesPlace INT) 
STORED AS ORC 
LOCATION 'hdfs:///performance_test_s3';
