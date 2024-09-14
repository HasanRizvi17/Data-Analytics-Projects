# Objective
The aim of this project was to identify the top product combinations with the highest propensity to be purchased together by customers to enable the key stakeholders in the Commercials and Marketing teams to take strategic decisions around pricing and bundling.

# What is Market Basket Analysis?
Market Basket Analysis (MBA) uses a machine learning algorithm that can tell us what items customers frequently buy together by generating a set of rules called association rules.
A sample result table of such analysis is shown below:

![image](https://github.com/HasanRizvi17/Hasan-Data-Analytics-Projects/assets/66498297/8f73d03c-3294-44b1-9053-d3a6665e6b30)

- ***Count*** is the Number of transactions that contain a particular combination of products.
- ***Confidence*** indicates the likelihood of a customer purchasing Product X given that he/she purchases Product Y in the same order. For example, Confidence of 0.70 for an association rule, “Coffee Powder => Sugar” tells us that, in all the orders in which customers purchased Coffee Powder, 70% of them also purchased Sugar in the same order. This can also be interpreted as: “if a customer purchases Coffee Powder in an order, he/she is 70% likely to purchase Sugar as well”.
- ***Lift*** of 3.5 for an association rule “Coffee Powder => Sugar” tells us that customer who is purchases Coffee Powder is 3.5 times more likely to purchase Sugar as well than any other random customer. If the lift is equal to one, this means that the purchases of the two products in the rule are completely independent. If the lift is less than 1 this means that the presence of Coffee Powder in the order will have a negative effect on the purchase of Sugar.

<br>

# Our Analysis and Results
- Analysis is included in the R file in the same folder
- The results for the products most frequenly purchased together are shown below:
  
  ![image](https://github.com/HasanRizvi17/Hasan-Data-Analytics-Projects/assets/66498297/000f1ba0-a61d-4766-b488-4765b84d907e)

<br>

# Post-analysis Actionable Strategies
### Cross-selling:
- *Implement bundled offerings* featuring popular products paired with complementary items ***to optimize sales performance across all product categories***
- *Leverage personalized sales* interactions to recommend supplementary products identified through association rules derived from market basket analysis ***to enhance customer engagement, foster long-term customer loyalty, and boost sales***
- *Utilize targeted up-selling strategies* to promote premium product offerings to established clientele segments ***to help optimize average order value and boost overall revenue generation***
### In-app Product Improvements:
- *Craft tailored messaging* by leveraging market basket analysis insights that resonates with individual customer needs and preferences ***to enhance marketing communications effectiveness and help drivie customer engagement and conversion rates***
- *Implement dynamic checkout experiences* that recommend value-added bundles personalized to each customer's shopping cart contents ***to encourage impulse purchases and maximizing transaction value***
- *Introduce "Frequently Bought Together" features* within the application interface ***to guide purchasing decisions and improve user experience through intuitive product suggestions***.
- *Optimize SKU placement* within the app based on established rules with a high confidence threshold ***to optimize strategic product positioning that helps maximize sales potential***









