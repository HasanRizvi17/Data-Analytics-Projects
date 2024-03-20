WITH 

user_weekly_entries AS
      (
      SELECT user_id, DATE_TRUNC(created_at, WEEK) AS entry_week,
              COUNT(*) AS num_of_entries
      FROM data_mart.entries
      GROUP BY user_id, entry_week
      ),
      
user_median_weekly_entries AS
      (
      SELECT user_weekly_entries.*,
              PERCENTILE_DISC(num_of_entries, 0.5) OVER(PARTITION BY user_id) AS median_weekly_entries 
      FROM user_weekly_entries
      ),
      
user_median_weekly_entries_2 AS
      (
      SELECT user_id, 
              AVG(median_weekly_entries) AS median_weekly_entries
      FROM user_median_weekly_entries
      GROUP BY user_id 
      ),
      
user_stats_rl AS
      (
      SELECT user_id, 
              COUNT(DISTINCT DATE_TRUNC(created_at, WEEK)) AS transacting_weeks,
              DATE_DIFF(CURRENT_DATE(), MAX(created_at), DAY) AS recency
      FROM data_mart.entries
      GROUP BY user_id
      ),
      
user_stats_rfl AS
      (
      SELECT user_stats_rl.user_id, 
              user_stats_rl.recency, user_median_weekly_entries_2.median_weekly_entries, user_stats_rl.transacting_weeks
      FROM user_stats_rl
      LEFT JOIN user_median_weekly_entries_2 ON user_median_weekly_entries_2.user_id = user_stats_rl.user_id
      ),

rfl_1 AS
      (
      SELECT users.user_id, 
              user_stats_rfl.recency, user_stats_rfl.median_weekly_entries, user_stats_rfl.transacting_weeks,
              CASE WHEN user_stats_rfl.recency > 40 THEN 1
                   WHEN user_stats_rfl.recency BETWEEN 15 AND 40 THEN 2
                   WHEN user_stats_rfl.recency BETWEEN 8 AND 14 THEN 3
                   WHEN user_stats_rfl.recency <= 7 THEN 4
                   ELSE NULL
              END AS r_score,
              CASE WHEN user_stats_rfl.median_weekly_entries = 1 THEN 1
                   WHEN user_stats_rfl.median_weekly_entries BETWEEN 2 AND 5 THEN 2
                   WHEN user_stats_rfl.median_weekly_entries BETWEEN 6 AND 10 THEN 3
                   WHEN user_stats_rfl.median_weekly_entries >= 11 THEN 4
                   ELSE NULL
              END AS f_score,
              CASE WHEN user_stats_rfl.transacting_weeks = 2 THEN 1
                   WHEN user_stats_rfl.transacting_weeks BETWEEN 3 AND 10 THEN 2
                   WHEN user_stats_rfl.transacting_weeks BETWEEN 11 AND 14 THEN 3
                   WHEN user_stats_rfl.transacting_weeks >= 15 THEN 4
                   ELSE NULL
              END AS l_score
                   
      FROM data_mart.users
      LEFT JOIN user_stats_rfl ON user_stats_rfl.user_id = users.user_id
      ),
      
rfl_2 AS
      (
      SELECT rfl_1.*,
              CAST((CAST(r_score AS STRING) || CAST(f_score AS STRING) || CAST(l_score AS STRING)) AS INT) AS rfl_score
      FROM rfl_1
      ),

rfl_3 AS
      (
      SELECT rfl_2.*,
              CASE WHEN rfl_score IN (444) THEN 'Champions'
                   WHEN rfl_score IN (314, 324, 334, 344, 414, 424, 434) THEN 'Loyal Users'
                   WHEN rfl_score IN (332, 333, 342, 412, 413, 432, 422, 423, 442, 343, 433, 443) THEN 'Potential Loyalist'
                   WHEN rfl_score IN (211, 221, 231, 241, 311, 321, 331, 341, 411, 421, 431, 441) THEN 'Recent Users'
                   WHEN rfl_score IN (222, 223, 232, 233, 312, 313, 322, 323, 243) THEN 'Users Needing Attention'
                   WHEN rfl_score IN (242, 212, 213) THEN 'At Risk'
                   WHEN rfl_score IN (214, 224, 234, 244) THEN 'Cant Lose Them'
                   WHEN rfl_score IN (111, 121, 131, 141,
                                      114, 124, 134, 144, 
                                      122, 123, 132, 133, 142, 112, 
                                      113, 143) THEN 'Lost'
                   ELSE 'Not Activated' END
              AS rfl_segment
      FROM rfl_2
      )
      
SELECT rfl_segment,
        COUNT(*) AS user_count
FROM rfl_3
GROUP BY rfl_segment
ORDER BY user_count DESC
LIMIT 100
