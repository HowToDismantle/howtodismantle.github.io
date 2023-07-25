---
layout: post
title: Understanding locks when using SQL Server to store fast changing machine or sensor data
date: 2023-03-01 12:00:00 +0200
tags: sqlserver bestpractice
image: /assets/2023-09-13/title.png
read_more_links:
  - name: All about locking in SQL Server
    url: https://www.sqlshack.com/locking-sql-server/
---
<!---
This article was mainly generated by ChatGPT. Thats why it sounds different from other articles
-->

In the realm of database management systems, concurrency control plays a vital role in ensuring data integrity and consistent query results. This article aims to delve into the functioning of locking in SQL Server databases, particularly in scenarios where simultaneous reading and writing occur. Additionally, it explores the application of the "WITH (NOLOCK)" hint in Peakboard applications, where the storage of sensor or machine data is prevalent.

## Understanding Locking in SQL Server:

Locking in SQL Server facilitates the prevention of conflicting operations from occurring simultaneously, thereby maintaining data integrity. When a transaction accesses a table or row, it acquires a lock on the respective resource, preventing other transactions from modifying it until the lock is released.

SQL Server supports various types of locks, including shared locks (S), exclusive locks (X), update locks (U), and intent locks, among others. Shared locks enable multiple transactions to read data concurrently, while exclusive locks are acquired for write operations, preventing other transactions from reading or writing to the locked resource. Update locks are acquired when a transaction intends to modify a resource.

In scenarios where concurrent reading and writing operations take place on the same table, contention issues often arise. Without adequate concurrency control, a transaction attempting to read data might be blocked by an exclusive lock obtained by a concurrent write operation. Consequently, the execution may be delayed, leading to performance degradation and reduced throughput.

## Using "WITH (NOLOCK)" to control locks

The "WITH (NOLOCK)" query hint in SQL Server offers a solution to address contention issues, especially bad peformance. In such cases, where sensor or machine data is stored, multiple transactions may need to read the data simultaneously. By utilizing "WITH (NOLOCK)" in the queries, transactions can read data without acquiring shared locks. This hint disregards any locks held by concurrent write operations, providing the ability to retrieve data in its current state, even during modifications.

Consider a Peakboard application that stores machine sensor data in an SQL Server database. Multiple transactions might need to read the latest sensor values while simultaneous writing of new sensor data is occurring. To achieve this, the following query can be used for reading:

{% highlight sql %}
SELECT SensorID, SensorValue
FROM SensorData WITH (NOLOCK)
ORDER BY Timestamp DESC;
{% endhighlight %}

In this example, the "WITH (NOLOCK)" hint allows the concurrent reading of sensor values without acquiring shared locks. This ensures the ability to access the latest data in real-time, even if write operations are ongoing.

Considerations:
While "WITH (NOLOCK)" enhances query performance by reducing locking overhead in Peakboard applications, it is essential to be aware of the trade-off between consistency and performance.

It is important to note that using "WITH (NOLOCK)" may result in "dirty reads," where a transaction retrieves data in the process of being modified or rolled back by another concurrent transaction. Consequently, inconsistent or incorrect results can occur if the data is updated while the query is executing. However we must understand that usually this not relevant for 99% of common applications within the Peakboard scope.

## Conclusion

Concurrency control and locking mechanisms are fundamental to maintaining data consistency and integrity in SQL Server databases. The "WITH (NOLOCK)" hint proves valuable in Peakboard applications that store sensor or machine data, allowing concurrent reading without acquiring shared locks. However, careful consideration of the trade-offs and potential for inconsistent results is crucial when utilizing this hint. By understanding the specific requirements of the application and employing appropriate locking mechanisms, a balance between performance and data consistency can be achieved.

