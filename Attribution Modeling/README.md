# 📊 Attribution Modeling
**_Feature Impact Analysis for Free Trial → Paid Conversion in a Language Learning App_**
<br>
<br>


## 🎯 Objective  
To find out which in-app features used during the free trial period of a Language Learning App (Duolingo-style) most influence a user's decision to upgrade to premium
<br>
<br>


## 📌 Project Overview
This project demonstrates end-to-end attribution modeling for product analytics, applied to a language learning app. We look at in-app feature usage and how it contributes to a user upgrading from a free trial to a paid subscription. The steps in the workflow involve:
1. generating data by simulating user event logs for product features used during the free trial and paid susbcriptions data  
2. preprocessing data by creating all possible pairs of paid subscriptions and the events following them in a defined attribution window (free trial period)  
3. creating different attribution models by modeling the data -- Last Click, First Click, Multi-touch (Linear), Multi-touch (Time-Decay) 
4. visualizing feature impact accrording to the credit attributed by each of the models  
<br>
<br>


## 🔍 Key App Features Analyzed  
- AI Chatbot -- usage indicated by the trigger of `complete_use_ai_chatbot` event 
- Review Mistakes -- usage indicated by the trigger of `complete_review_mistakes` event
- Target Practice -- usage indicated by the trigger of `complete_target_practice` event
- Unlimited Hearts -- usage indicated by the trigger of `complete_5th_mistake` event
<br>
<br>


## 🔍 Assumptions  
- only first-time upgrades to paid subscriptions taken into account
- only using product features that represent explicit user actions such as completing certain type of lessons
  - e.g in-app adds are not taken into account here
- the `complete_5th_mistake` event is triggered on every 5th mistake made by the user
- the `complete_5th_mistake` event trigger indicates the usage of the _Unlimited Hearts_ features since in the non-paid version, after every 5th mistake made, the user would have needed to wait for their hearts to be refilled
<br>
<br>


## ⚙️ Attribution Models Implemented  
| Model           | Description                                                           |
|----------------|------------------------------------------------------------------------|
| **Last Click**  | 100% credit to the last feature used before conversion                     |
| **First Click**  | 100% credit to the first feature used within the attribution window before conversion                    |
| **Multi-touch (Linear)**      | Equal credit to all features used within the attribution window before conversion          |
| **Multi-touch (Time-Decay)**  | More credit is attributed to features more recently used before conversion               | 

**Some Concepts**  
- Attribution Window: The time range before a conversion (in this case, upgrade to paid) during which events are considered relevant for assigning credit for attribution
- Time-decay attribution: attribution model that gives more credit to more recent feature usage and less credit to older usage. The idea is that the closer the usage is to the conversion, the more influence it likely had.
- In time-decay attribution models, half-life is the amount of time it takes for the attribution weight (or influence in real terms) of a product feature usage to reduce to 50% of its original value
-   example: for a `half_life` value = 3, an feature that was used 3 days before conversion will get 50% weight

**Calculation of Weights in Time-decay Attribution (example)**<br>
formula: `weight = 0.5^(days_since_event / half_life)`
| Days Since Event | Formula            | Weight |
|------------------|--------------------|--------|
| 0                | 0.5^(0/7) = 0.5^0   | 1.00   |
| 3                | 0.5^(3/7)           | ~0.76  |
| 7                | 0.5^(7/7) = 0.5^1   | 0.50   |
| 14               | 0.5^(14/7) = 0.5^2  | 0.25   |
| 21               | 0.5^(21/7) = 0.5^3  | 0.125  |
<br>
<br>


## 🛠 Tools Used
- **Pandas and Numpy**: for data manuipulation and attribution modeling  
- **Matplotlib and Seaborn**: for visualizing feature attribution across different attribution models
<br>
<br>


## 📌 Insights from Analysis
| Feature              | First Touch    | Last Touch    | Multi-Touch Linear   | Multi-Touch Decay    |
| -------------------- | -------------- | ------------- | ---------------------| -------------------- |
| **AI Chatbot**       | Highest        | High          | Highest              | Highest              |
| **Target Practice**  | High           | Highest       | Highest              | Highest              |
| **Review Mistakes**  | Medium         | Lowest        | Lowest               | Lowest               |
| **Unlimited Hearts** | Lowest         | Medium        | Lowest               | Lowest               |

Summary:
- AI Chatbot gets high credit in First Touch and Multi-Touch models -> often the first feature users interact with
- Target Practice gets most credit in Last Touch and Multi-Touch -> frequently used right before conversion
- Review Mistakes and Unlimited Hearts get lower credit in general -> less directly linked to conversion
  => **Overall**, AI Chatbot and Target Practice get high credit -> more directly linked to conversion
