Key Lookup and Covering Index

- Explored Key Lookup behavior in SQL Server
- Understood how non-clustered indexes may require additional lookups for missing columns
- Learned that covering indexes (using INCLUDE) can eliminate extra reads
- Observed that indexing improvements are not always visible on small datasets
- Identified that SQL Server optimizer may prefer scans for small tables
- Key insight: Index optimization benefits become significant at scale (large datasets)

### Summary

- Index Seek = fast targeted access  
- Scan = sometimes optimal for small data  
- Covering Index = eliminates Key Lookup  