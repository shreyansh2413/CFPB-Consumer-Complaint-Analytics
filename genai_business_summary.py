
import os
import pandas as pd
from google import genai

INPUT_FILE = "cfpb_complaints_cleaned.csv"
OUTPUT_FILE = "cfpb_ai_business_summary.txt"
MODEL = "gemini-3.5-flash-lite"

# Load data
df = pd.read_csv(INPUT_FILE)

# Prepare dates and calculate metrics using Pandas
df["date_received"] = pd.to_datetime(
    df["date_received"], errors="coerce", utc=True
)

df = df.dropna(subset=["date_received"])

monthly = (
    df.groupby(df["date_received"].dt.strftime("%Y-%m"))
    .size()
    .sort_index()
)

top_products = df["product"].value_counts().head(5)
top_issues = df["issue"].value_counts().head(5)

timely = (
    df["timely_response"]
    .astype(str)
    .str.strip()
    .str.lower()
)

valid_timely = timely.isin(["yes", "no"])
timely_rate = (
    timely[valid_timely].eq("yes").mean() * 100
    if valid_timely.any() else None
)

response_days = pd.to_numeric(
    df["response_days"], errors="coerce"
)

avg_days = response_days.mean()

# Build a factual metrics summary
metrics = f"""
CFPB Consumer Complaints Analysis

Total complaints: {len(df):,}

Monthly complaints:
{monthly.to_string()}

Top 5 products:
{top_products.to_string()}

Top 5 issues:
{top_issues.to_string()}

Timely response rate: {
    f"{timely_rate:.2f}%" if timely_rate is not None else "Unavailable"
}

Average response days: {
    f"{avg_days:.2f}" if pd.notna(avg_days) else "Unavailable"
}

Note: The final month may be incomplete.
"""

# Connect to Gemini
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError(
        "GEMINI_API_KEY is missing. Set it in your terminal first."
    )

client = genai.Client(api_key=api_key)

prompt = f"""
You are a business data analyst.

Analyze the following verified metrics from a consumer
complaints dataset.

{metrics}

Write a concise business insights report with:
1. Executive summary
2. Three important findings
3. Possible business implications
4. Three recommendations for companies or complaint-handling teams
5. Data limitations

Rules:
- Use only the supplied metrics.
- Never invent statistics or causes.
- Clearly distinguish observed patterns from possible explanations.
- Do not claim that a pattern proves causation.
- Mention that the final month may be incomplete.
- Do not imply that the dataset contains original complaint narratives.
"""

response = client.models.generate_content(
    model=MODEL,
    contents=prompt
)

if not response.text:
    raise RuntimeError("Gemini returned no text. Check the API response.")

with open(OUTPUT_FILE, "w", encoding="utf-8") as file:
    file.write("CFPB AI-GENERATED BUSINESS INSIGHTS\n\n")
    file.write(response.text.strip())
    file.write("\n")

print("\nAI business summary generated successfully!")
print(f"Saved to: {OUTPUT_FILE}")
print("\n" + response.text.strip())
