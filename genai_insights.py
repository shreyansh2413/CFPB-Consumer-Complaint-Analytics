
import pandas as pd

df = pd.read_csv("cfpb_complaints_cleaned.csv")

df["date_received"] = pd.to_datetime(
    df["date_received"], errors="coerce", utc=True
)

# Monthly complaint counts
df["month"] = df["date_received"].dt.to_period("M").astype(str)
monthly = (
    df.groupby("month")
    .size()
    .reset_index(name="complaints")
)

# Top products
top_products = (
    df.groupby("product")
    .size()
    .sort_values(ascending=False)
    .head(5)
)

# Top issues
top_issues = (
    df.groupby("issue")
    .size()
    .sort_values(ascending=False)
    .head(5)
)

# Timely response rate
timely = df["timely_response"].astype(str).str.strip().str.lower()
valid = timely.isin(["yes", "no"])
timely_rate = (
    timely[valid].eq("yes").mean() * 100
    if valid.any() else None
)

# Average response days
response_days = pd.to_numeric(df["response_days"], errors="coerce")
avg_days = response_days.mean()

print("\nMONTHLY COMPLAINTS")
print(monthly.to_string(index=False))

print("\nTOP 5 PRODUCTS")
print(top_products.to_string())

print("\nTOP 5 ISSUES")
print(top_issues.to_string())

print("\nTIMELY RESPONSE RATE (%)")
print(round(timely_rate, 2) if timely_rate is not None else "Unavailable")

print("\nAVERAGE RESPONSE DAYS")
print(round(avg_days, 2) if pd.notna(avg_days) else "Unavailable")
