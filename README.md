# CFPB Consumer Complaint Analytics

## 📌 Project Overview

This project analyzes **93,718 consumer complaints** across five financial product categories using **Python, Pandas, NumPy, PostgreSQL, SQL, and Matplotlib**.

The objective is to identify major complaint drivers, understand product-specific customer pain points, evaluate timely-response performance, analyze complaint trends, and translate the findings into actionable business recommendations.

---

## 🎯 Business Problem

Financial institutions receive thousands of consumer complaints across different financial products. Simply counting complaints is not enough to understand where improvement is required.

This project answers questions such as:

- Which financial products generate the most complaints?
- What are the most common complaint issues?
- What is the dominant complaint issue for each product?
- Which products have weaker timely-response performance?
- How have complaint volumes changed over time?
- Which areas should businesses prioritize for improvement?

---

## 📊 Dataset

**Source:** Consumer Financial Protection Bureau (CFPB) Consumer Complaint Database

The analysis focuses on five financial products:

- Money transfer, virtual currency, or money service
- Mortgage
- Vehicle loan or lease
- Student loan
- Prepaid card

**Total Records:** 93,718 complaints

### Key Columns

- `date_received`
- `product`
- `sub_product`
- `issue`
- `sub_issue`
- `company`
- `state`
- `submitted_via`
- `date_sent_to_company`
- `company_response_to_consumer`
- `timely_response`
- `complaint_id`
- `response_days`

---

## 🛠️ Tools & Technologies

- **Python**
- **Pandas**
- **NumPy**
- **Matplotlib**
- **PostgreSQL**
- **SQL**
- **Jupyter Notebook**
- **GitHub**

---

## 🔄 Project Workflow

```text
Dataset
   ↓
Data Understanding
   ↓
Data Cleaning
   ↓
Exploratory Data Analysis
   ↓
Numerical Analysis
   ↓
SQL Business Analysis
   ↓
Data Visualization
   ↓
Business Insights
   ↓
Recommendations
