# Objective
Analyze the transactional data and give the business stakeholders an understanding of how sticky these users are to the business management ledger product/app. The top users would be made part of the cohort we'll be experimenting our new loyalty program with.
<br>
<br>
<br>

# Analysis & Insights

### **Stickiness on Overall User-base Level**

We're using the following formula here: `Stickiness = Daily Active Users (DAU) / (Weekly Active Users (WAU)`
          
Stickiness is measured on a scale between 0 and 1. The closer this ratio is to 1, the stickier the users are and the more likely they are to become regular users (converting from WAU to DAU with increasing frequency)

Attaching a chart below that shows WAU, Weekly Avg DAU and stickiness by the weeks:

![image](https://github.com/user-attachments/assets/ab9ef1cd-538f-4339-82f1-0ddd5b360a3a)

The _**average stickiness of the users for the last 10 weeks is ~0.462**_. We have had stickiness of 0.57 with 37 active users in the week of 30th May 2021, which means that the potential for an even higher stickiness is still there.  _**The Weekly Active Users (WAU) and Weekly Avg DAU however, seem to be on a decline over the past couple of weeks**_ and this could potentially be due to fewer users returning to the app (having recency > max gap between any two transactions).
<br>
<br>

### **Stickiness on User Level**

On a user-level, we're measuring stickiness by the following metrics:
- weeks actively transacting (number of weeks with >= 1 transaction done) 
- average weekly transactions (`total transactions done / weeks actively transacting`)
<br>

**Top 10 users by Weeks Actively Transacting**

![image](https://github.com/user-attachments/assets/edbad079-dc7f-4bb8-a63b-59069832a8a6)
<br>
<br>

**Top 10 users by Average Weekly Transactions**

![image](https://github.com/user-attachments/assets/4457d19e-fbe9-4867-a438-e66bbcd4a25f)
<br>

This depicts that the top users, when viewed individually on the basis of these two metrics, are vastly different.
When viewing the top 10 users separately by the two metrics above, we find that:
1. _**Only 1 out of the top 10 users by average transactions per active week, also belongs to the top 10 users by weeks actively transacting**_. 90% of these top 10 users are those who haven’t been active in a lot of weeks, but when they have been using the Business Management Ledger app, they have been using it quite rigorously within their active weeks.
2. _**Only 1 out of the top 10 users by weeks actively transacting, also belongs to the top 10 users by average transactions per active week**_. The 90% of the top 10 users (remaining 9 users) are those who haven’t been rigorously and frequently using it within their active weeks, but have been consistently using the Business Management Ledger app over a larger number of weeks.
<br>

**Top 10 Users by both Average Weekly Transactions and Weeks Actively Transacting**

In order to strike a sweet spot between the two metrics and see which users have had a decent usage frequency of the app and have also used the app consistently, we will use the best combination of the two. \
The means of the two metrics turn out to be the following:
- average transactions per active week: 13.83
- weeks actively transacting: 11.46

Depicting below the % of total users who lie above and below the means for both metrics:

![image](https://github.com/user-attachments/assets/3b172357-b38d-4799-ac98-6039f34d56c5)

![image](https://github.com/user-attachments/assets/2a5fae41-0ada-418d-9652-dcdd6f243821)

Since we see that a majority of the user base is below the means for both, we’ll filter out the users who are above mean in both and find that desirable combination for stickiness.

There are 12 such users in total. We arrange them by descending order of Average Transactions per Active Week and filter out the top 10.

![image](https://github.com/user-attachments/assets/f2b1bc20-a068-4996-9c2b-4947b11d46e7)

Even in this group of users, we notice the _**transactions_per_active_week is heavily skewed in favor of the top 2 users having values of 144.64 and 112.67 respectively**_, which are much higher than the transactions_per_active_week value of the third ranked user, which is 44.17.

Perhaps, if we look into more data such as in-app product analytics data, we can get a much better understanding of how their journey looks like within the app and what makes them stick more to the app than the other users.
<br>
<br>
<br>

# Business Recommendations
1. For us to further deep dive into this, we have to understand why some of these top users are on the brink of churning.
2. Some of the methods we could use to understand this are:
  - Use of in-app product analytics (the data of which we do not have at the moment for deeper analysis)
    - Separate the cohort for users at risk of churn
    - Make event flows in our product analytics tool
    - Identify the common events occurring right before the user’s last transaction (or app session)
  - Conduct a churn survey
  - Community meetup with some of out top as well as previously active but now churned users to understand their pain points
3. Some potential reasons and of churn and corresponding solutions could be:
  - User doesn’t fully know how to use the app
    - Introduce tutorials for different features and functionalities within the app (since currently there are none)
    - Other:
      - If, from our product analytics tool, we find that the reason for user churn was not due to PNs, we could utilize PNs to remind them of the company’s services (otherwise it would not make sense to keep spamming them with PNs)
      - To keep the current users engaged, we could automate reminder PNs as soon as they cross the 7-day mark for time since their last transaction
