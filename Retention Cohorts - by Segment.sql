-- source: https://app.mode.com/benn/reports/bf7bbe2135e7/runs/f0fdd5471b74

WITH 
  users AS (
SELECT user_id,
       activated_at,
       state,
       language
  FROM tutorial.playbook_users
),

  events AS (
SELECT user_id,
       event_name,
       occurred_at,
       device,
       location
  FROM tutorial.playbook_events
)

SELECT x.cohort AS "Language",
       MAX(x.period_age) OVER (PARTITION BY x.cohort) AS cutoff_age,
       x.period_age,
       x.tally,
       x.tally/MAX(x.tally) OVER (PARTITION BY x.cohort)::FLOAT AS retention_rate,
       MAX(x.tally) OVER (PARTITION BY x.cohort) AS "New Users"
  FROM (
SELECT u.language AS cohort,
       FLOOR(EXTRACT('day' FROM e.occurred_at - u.activated_at)/7) AS period_age,
       COUNT(DISTINCT u.user_id) AS tally
  FROM users u
  LEFT JOIN events e
    ON e.user_id = u.user_id
 WHERE u.activated_at IS NOT NULL
   AND u.activated_at >= '2014-06-01'
 GROUP BY 1,2
       ) x
 ORDER BY 3,1