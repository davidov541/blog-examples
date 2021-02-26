CREATE TABLE IF NOT EXISTS performance_test_s3 (id INT, squared int, halved double) STORED AS ORC LOCATION 's3://hive-s3-performance-data-bucket/performance_test_s3';
CREATE TABLE IF NOT EXISTS performance_test_hdfs (id INT, squared int, halved double) STORED AS ORC LOCATION 'hdfs:///performance_test_s3';
