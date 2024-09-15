# 🛠️ Tools Used
| **Tool**                            | **Purpose**          |
|-------------------------------------|----------------------|
| SQL                            | Data Modeling and Analysis                | 
| Tableau                     | Data Visualization   | 
<br>



# 💡 Objective
Understand quantitatively how well our current phishing simulation offering and its campaigns are performing in terms of the value it is bringing to the customers throughout their lifecycle and share actionable insights that the Phishing Simulation Product Team could utilize to make them more impactful for our customers.

<br>



# 📊 Analysis & Insights

## Metric Definitions

**Success Metric**

This will be the North Star Metric to evaluate the product performance. 
- _Click Rate_: % of total employees that click on the simulated phishing emails
<br>

**Supporting Metrics**
These would be our layer 2 metric that helps explain the over-arching North Start Metric (top layer metric)
- _Average Click Rate per Customer_: click rate for an average customer in the company’s customer base
<br>

**How these metrics indicate the value the product is bringing to the customers:**

The lower the values of these metrics, the better the employees are at being aware of, identifying and avoiding phishing emails.
<br>
<br>

## Quantitative Analysis and Visualization
**Click Rate – Monthly Trend**
![image](https://github.com/user-attachments/assets/7381cf16-ca28-4724-80f6-5f9c6b0ac561)

- This upward trend of Click Rate seems to indicate that customers are becoming increasingly susceptible to phishing emails over time
- This might be a sign that customers need more training to develop stronger awareness to phishing emails
- However, there could be a few other potential reasons for this increasing trend as well, which might not necessarily be negative (and for which we currently don’t have the data):
  - New employees might have joined the customer companies and could be contributing to this concerning trend
  - The difficulty of simulations might have been changed by the the company's admins in the customer companies to provide the employees more advanced trainings
<br>

**Average Click Rate per Customer – Monthly Trend**
![image](https://github.com/user-attachments/assets/4d957e08-05bd-4e4d-a90f-66bd4a2183fd)
 
- Parallel to Click Rate, this metric seems to be going up as well and following a similar trend
- This indicates that there were no particular groups or segments of customers that could have been pulling the North Star Metric upwards
<br>



## Zooming Into Template-level Performance

### Repeat Click Rates 
**repeat click rate** (for a template): % of customers who click a 2nd or higher time after their first time
- 60% of the total templates have 100% repeat click rate
- 68% of the total templates have 90% or higher repeat click rate
- 80% of the total templates have 80% or higher repeat click rate

This indicates that most of the templates don’t seem to be effective in delivering the customers key learning moments after they click on a particular template the first time as a huge chunk tends to return to click on them again in the later months. 
<br>
<br>

### Top and Bottom 10 Templates (by Click Rates)
<br>

Note: For this section, we have based our analysis on the templates that fit the following criteria:
- used by at least 10 unique customers
- in English language
<br>

**Top 10 Templates (by highest Click Rates)**
![image](https://github.com/user-attachments/assets/e875210a-dfd5-40a6-8b26-74c7ab3e3646)

- Obvious Phishing Email: Some of the templates here are too obvious for the customers to fall for such as those related to “lost property” and “concert invitation”, resulting in lower tendencies to click on them
- Security Checks: Emails of this nature tend to automatically get an average individual to have their guard up. Upon encountering these, customers are likely to proceed ahead with much greater caution, which can be observed in the “Security Warning” email being the 1st-ranked template, with a conversion rate of only 1.8% (lowest by a big margin)
<br>

**Bottom 10 Templates (by lowest Click Rates)**
![image](https://github.com/user-attachments/assets/5ee74f61-e9b6-46bc-a1d4-124f1962c769)

- Sense of Urgency/Panic: Employees seem to be lured by the emails that create a sense of urgency such “Payroll Error” which naturally prompts an individual to take quick action
  - This is the highest Click Rate, almost twice the magnitude of the 2nd-lowest template
- Relevance: 6/10 of these bottom 10 templates (60%) are relevant to the employees’ current organization, which seems take advantage of the employees trust factor to lure them in
<br>
<br>


## Zooming Into Industries

**Distribution of Click Rate by Industry**

![image](https://github.com/user-attachments/assets/d4a0ff20-1365-452f-a5a6-ab53725fa49c)
 
- As per the bar chart above, there seems to be a distinguishable difference in Product Performance (Click Rate) between the industries
- Public Sector and Service Industry seems to be the most susceptible as per our metric
- Finance and Banking industry seems to be the least vulnerable
  - One potential reason could be that the workforce in this industry is more familiar with common phishing strategies due to the financial nature involved (i.e financial scams)
<br>

**Monthly Trend for Click Rate by Industry**

It’s also important to zoom out a bit to look at the trends from a wider scope across the various industries as well
![image](https://github.com/user-attachments/assets/61eadba7-76ed-4fa6-b257-aa7e81416ccf)

- Retail industry’s downward trend of Click Rate is the most impressive finding here
- Public sector seems to exhibit the strongest upward trend. Apart from using more difficult simulation templates, other potential reasons could be:
  - Increase in phishing attempts in the public sector
  - New phishing strategies being used that employees in this industry are not already aware of

Overall, it seems most of the industry’s are becoming increasingly susceptible to phishing attempts (keeping the factor of template difficulty constant), which calls for some tweaks and experimentation in the phishing detection training strategies.

<br>
<br>



# 💼 Business Recommendations
<br>

**1) Develop Journeys for Delivering Learning Moments**
- As we saw earlier, 60% of the total templates have 100% repeat click rate
- This indicates a lack of effective learning lessons for the customers, resulting in the customers falling for the same trap again
- Recommendation: After each click on the simulated phishing email, a feedback loop should be immediately provided to the customer which does the following:
  - Explain why the email they clicked on was a phishing attempt
  - Redirect customers to resources which they could use to learn more about common phishing tactics in their relevant industry
<br>

**2) Template Rotation**
- We earlier observed some of the templates with the lowest click rates 
- Recommendation: If we notice a consistently low click rate across certain templates, it would be better to develop some sort of automated mechanism (rather than leaving it entirely to the customers) that then rotates the customer to new and more challenging templates relevant to their industry
  - This increases their familiarity with new types of phishing attempt scenarios
<br>

**3) Emphasis on Common Phishing Tactics**
- We earlier observed some of the templates with the highest click rates
- Recommendation: identify the common tactics and themes that are part of the templates with the highest click rates, and highlight them in the training materials for the customers and the educational resources they are redirected to when they click on a particular phishing email
<br>

**4) Collect Data on Employee Level (masked)**
- Currently we have campaign data aggregated on a customer level for all employees in the customer company
- Recommendation: start collecting masked employee level data from partner customer companies, which would allow the company to further personalize the phishing simulations
  - Segmented training for new and existing employees to avoid the downward bias in click rates caused by newly joining employees with little to no cybersecurity training




