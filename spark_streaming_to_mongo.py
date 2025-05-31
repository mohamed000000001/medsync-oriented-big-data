from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col
from pyspark.sql.types import StructType, StringType, DoubleType, TimestampType

# Define schema for incoming data
schema = StructType() \
    .add("patientId", StringType()) \
    .add("type", StringType()) \
    .add("value", StringType()) \
    .add("timestamp", TimestampType())

spark = SparkSession.builder \
    .appName("KafkaToMongo") \
    .config("spark.mongodb.output.uri", "mongodb://localhost:27017/medsync.analytics") \
    .getOrCreate()

df = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sensor-data") \
    .load()

json_df = df.selectExpr("CAST(value AS STRING) as json") \
    .select(from_json(col("json"), schema).alias("data")) \
    .select("data.*")

# Example: Calculate average value per patient per type (assuming value is numeric)
agg_df = json_df.withColumn("value", col("value").cast(DoubleType())) \
    .groupBy("patientId", "type") \
    .avg("value") \
    .withColumnRenamed("avg(value)", "avg_value")

# Write to MongoDB
query = agg_df.writeStream \
    .format("mongodb") \
    .option("checkpointLocation", "/tmp/spark-mongo-checkpoint") \
    .outputMode("complete") \
    .option("database", "medsync") \
    .option("collection", "analytics") \
    .start()

query.awaitTermination() 