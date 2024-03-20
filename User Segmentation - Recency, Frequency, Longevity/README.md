## Problem Statement

Currently, we are only segmenting our user base based on the frequency of weekly entries users do. This ignores all other factors when classifying users as either *Super*, *Power*, *Transacting*, or *New* type. 

To support this, in one of our earlier analyses, we found out that out of all the users who had been transacting on the app for ≥ 52 distinct weeks, the biggest chunk, 41% came from the *transacting* users group, when we split the distribution by *user_type*. Attaching image for reference below:

<img src="/User Segmentation - Recency, Frequency, Longevity/Images/User Type Distribution.png" alt="Alt text" title="Optional title">

Furthermore, we are also currently not taking into account the recency of users, and how many days ago they last transacted on the app. A lot of the users we classify as “*Super*” or “*Power*”, have churned and this information is overlooked many times whenever splitting any product data across user types/groups.

## Objectives

Re-define user segments/types using a more sophisticated and multi-dimensional approach that takes into account indicators of user’s performance and engagement apart from only the frequency of entries the user makes in the ledger.

## Walk Through

We took inspiration from the RFM segmentation approach that segments users across 3 dimensions: 

- ***Recency*** — how many days ago the user was last active or transacted on
- ***Frequency*** — how many times has the user transacted
- ***Monetary Value*** — the total amount of revenue the user has generated through orders

As we can see from the definitions above, this approach is mostly used in the e-commerce industry. 

However, we decided to leverage the power of this approach to fit it and make it more compatible with CreditBook Ledger’s model. We redefined these 3 segments:

- ***Recency*** — how many days ago the user last transacted on
- ***Frequency*** — how many times the user transacts on average in a week (median weekly entries)
- ***Longevity*** — number of transacting weeks of the user (distinct weeks in which the user did ≥ 1 entry in the ledger)

We remodeled the RFM to **RFL Segmentation** to align it with the context of our user base.

### **RFL Scoring Scale**

For each of the 3 factors, recency, frequency, and longevity, we have scored the user **on a scale of 1 to 4**

![Untitled (5).png](https://prod-files-secure.s3.us-west-2.amazonaws.com/66b28ac1-811a-44c2-ab9a-0fe2f63adc42/748cf0c6-6f6a-4d82-9f55-3483d2c57540/Untitled_(5).png)

The overall **RFL score** is simply the three scores (R, F, L) concatenated together. For instance, if a customer gets an R score of 2, F score of 4, and L score of 3, his RFM score will be 243.

Now we have users across 64 different possible scores.

Using intuition, we classified those users into 9 different segments, the information on which can be seen below

| Segment | RFL Score | Description |
| --- | --- | --- |
| Champions | 444, | Dream users. Transacted recently, Transact frequently, and have been transacting for a long period of time. Can possibly create a word of mouth about the product amongst their circles. Must be treated with immense care. |
| Loyal users | 314, 324, 334, 344, 414, 424, 434 | These users are getting clear value out of the product, using it for some time now showing consistency. |
| Potential Loyalist | 332, 333, 342, 412, 413, 432, 422, 423, 442, 343, 433, 443 | They have a decent amount of weekly transactions and/or number of transacting weeks and have the potential to become loyal to the product. |
| Recent users | 211, 221, 231, 241, 311, 321, 331, 341, 411, 421, 431, 441 | Have recently started using the product |
| Users Needing Attention | 222, 223, 232, 233, 312, 313, 322, 323, 243 | These users don’t necessarily have the best combination of average entries per week or overall transacting weeks but if provided a decent amount of attention, they can prove to be valuable users. |
| At Risk | 242, 212, 213 | These are  the users we are close to losing since they have not made any transaction since some time now and it is likely that we may lose them if we don't try to make any push to ensure their retention. |
| Cant Lose Them | 214, 224, 234, 244 | These users have not transacted in the product in a long time but have made transactions in the product with decent frequency over a long number of weeks |
| Lost | 111, 121, 131, 141, 114, 124, 134, 144, 122, 123, 132, 133, 142, 112, 113, 143 | These users used the product for a very short amount of time and now have stopped using the product altogether and have probably decided to opt for alternatives instead. |
| Not Activated | 0 | Users with <= 1 transacting weeks in the product |

This time, we have been a bit more stringent on how we define “*activated users*”. A user will not be considered to have been activated if they haven’t been transacting (with ≥ 1 entry) in **at least 2 distinct weeks**. This way, we are able to incorporate the fact that a lot of the users are just testing out the app during the first week in which they install and signup on the app.

<aside>
📝 **Note:** An understanding of the distribution of the recency, frquency and longevity variables and basic intuition was used to assign users of particular RFL score to segments.

</aside>

## Insights

When validating the results of this RFL Segmentation, we viewed the user distribution across 2 groups, the results of which are attached below:

- **Addicted Users** — total transacting weeks ≥ 52
    
    ![Untitled (6).png](https://prod-files-secure.s3.us-west-2.amazonaws.com/66b28ac1-811a-44c2-ab9a-0fe2f63adc42/7490abc2-2667-446c-8bd7-7239084a8c91/Untitled_(6).png)
    
- **Good Churned Users** — total transacting weeks ≥ 10 and ≤ 20 AND days since last activity ≥>1 month
    
    ![Untitled (7).png](https://prod-files-secure.s3.us-west-2.amazonaws.com/66b28ac1-811a-44c2-ab9a-0fe2f63adc42/0c6d8575-eca0-4b11-a8cc-df4c6b2d1a61/Untitled_(7).png)
