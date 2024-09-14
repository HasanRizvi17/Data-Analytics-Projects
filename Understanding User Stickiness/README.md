# Objective
Analyze the transactional data and give the business stakeholders an understanding of how sticky these users are to the business management ledger product/app. The top users would be made part of the cohort we'll be experimenting our new loyalty program with.

# Analysis & Insights

### **Stickiness on Overall User-base Level**

We're using the following formula here: `Stickiness = Daily Active Users (DAU) / (Weekly Active Users (WAU)`
          
The closer this ratio is to 1, the more likely our users are to become regular users (converting from WAU to DAU with increasing frequency)

Attaching a chart below that shows WAU, Weekly Avg DAU and stickiness by the weeks:

![image](https://github.com/user-attachments/assets/ab9ef1cd-538f-4339-82f1-0ddd5b360a3a)

The _**average stickiness of the users for the last 10 weeks is ~0.462**_. We have had stickiness of 0.57 with 37 active users in the week of 30th May 2021, which means that the potential for an even higher stickiness is still there.  _**The Weekly Active Users (WAU) and Weekly Avg DAU however, seem to be on a decline over the past couple of weeks**_ and this could potentially be due to fewer users returning to the app (having recency > max gap between any two transactions).
<br>
<br>
<br>

### **Stickiness on User Level**

On a user-level, we're measuring stickiness by the following metrics:
- weeks actively transacting (number of weeks with >= 1 transaction done) 
- number average of weekly transactions (total transactions done / weeks actively transacting)


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
