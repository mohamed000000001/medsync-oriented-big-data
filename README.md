🩺 MedSync – Big Data–Driven Healthcare Monitoring Platform
MedSync is a scalable, real-time healthcare monitoring platform that leverages modern Big Data technologies to ingest, process, and visualize patient data from medical records, IoT devices, and appointment systems. Designed for high-throughput environments, it enables continuous analytics and real-time decision-making in clinical settings.

🚀 Features
📡 Real-Time Ingestion: Collects sensor and event data via RESTful APIs and streams them into Apache Kafka.

💾 Flexible Storage: Uses MongoDB to store semi-structured patient records and analytics results.

⚙️ Stream Processing: Real-time data analytics powered by Apache Spark Structured Streaming.

📊 Live Dashboard: React-based UI displays processed analytics (e.g., sensor averages per patient).

🔔 Extensible Alerts: Architecture supports anomaly detection and real-time alerting with WebSockets or Kafka topics.

| Layer             | Technology               |
| ----------------- | ------------------------ |
| Frontend          | React.js                 |
| API Server        | Node.js + Express.js     |
| Data Streaming    | Apache Kafka             |
| Stream Processing | Apache Spark (Streaming) |
| Storage           | MongoDB                  |
| Analytics         | Python (Spark job)       |

🔄 Data Pipeline Overview
IoT data is sent to /api/iot.

Backend stores data in MongoDB and publishes it to Kafka.

Apache Spark processes Kafka data and computes real-time metrics.

Results are written to MongoDB and exposed via /api/analytics.

Frontend dashboard fetches and displays analytics in real time.

✅ Benefits
Scalable handling of high-volume medical and sensor data.

Real-time patient monitoring and alerting capabilities.

Modular and extensible design for future AI/ML integration.


MedSync combines Kafka, Spark, and MongoDB to enable real-time healthcare analytics from IoT data. Its architecture supports scalable, low-latency processing with live dashboards. This flow allows instant insights, anomaly detection, and AI-ready integration.










