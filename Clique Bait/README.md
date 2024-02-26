# 🍜 Case Study #6: Clique Bait 
<p align="left">
    <img src="https://github.com/Kanikamittal99/8-week-sql-challenge/assets/32505627/6f8953c0-2fd0-4aec-8990-e4a98920cf38" width="500" height="500"/> 
</p>

  
## 📚 Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Questions Answered](#questions-answered)

### Problem Statement
- Clique Bait is an online seafood store 
- In this case study - we need to analyze this dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

### Entity Relationship Diagram
<p align="left">
    <img src=https://github.com/Kanikamittal99/8-week-sql-challenge/assets/32505627/f2bb1a04-bc79-4f27-8173-d3d25d759ef1 width="950" height="500"/> 
</p>


### Questions Answered
**Digital Analysis**
1. How many users are there?
2. How many cookies does each user have on average?
3. What is the unique number of visits by all users per month?
4. What is the number of events for each event type?
5. What is the percentage of visits which have a purchase event?
6. What is the percentage of visits which view the checkout page but do not have a purchase event?
7. What are the top 3 pages by number of views?
8. What is the number of views and cart adds for each product category?
9. What are the top 3 products by purchases?
***
**Product Funnel Analysis**
1. Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to the cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?

2. Additionally, create another table that further aggregates the data for the above points but this time for each product category instead of individual products.

3. Use your 2 new output tables - answer the following questions:
- Which product had the most views, cart adds, and purchases?
- Which product was most likely to be abandoned?
- Which product had the highest view to purchase percentage?
- What is the average conversion rate from view to cart add?
- What is the average conversion rate from cart add to purchase?
  ***
**Campaign Analysis**
1. Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)



**Click [here](https://github.com/Kanikamittal99/8-week-sql-challenge/blob/main/Clique%20Bait/CaseStudy.sql) to check my approach in handling above business queries**
