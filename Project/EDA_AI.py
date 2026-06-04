import streamlit as st
import pandas as pd
from pandasai import SmartDataframe
from pandasai.llm.openai import OpenAI
import matplotlib.pyplot as plt
import seaborn as sns
import os
import io
import speech_recognition as sr
from dotenv import load_dotenv
# Load environment variables from the .env file
load_dotenv()

# Access the OpenAI API key from the environment
api_key = os.getenv("OPENAI_API_KEY")

# Use the API key in your code
if api_key:
    print("OpenAI API Key loaded successfully")
else:
    print("Failed to load the OpenAI API Key")

# Initialize LLM
llm = OpenAI(api_token=os.getenv("OPENAI_API_KEY"))

# Streamlit App UI
st.markdown("""
    <h1 style='text-align: center; color: #4CAF50; font-size: 48px;'>📊 AI-Powered Data Analysis Tool 🚀</h1>
    <h3 style='text-align: center; color: #ff9800;'>Unleash Insights from Your Data with AI!</h3>
""", unsafe_allow_html=True)

st.sidebar.header("🔍 Upload Your Dataset")

# Upload file
uploaded_file = st.sidebar.file_uploader("Upload a CSV or Excel file", type=["csv", "xlsx"])

def get_chart_download_link(fig):
    """Generate a link to download a matplotlib chart."""
    buf = io.BytesIO()
    fig.savefig(buf, format="png")
    buf.seek(0)
    return buf

def recognize_speech():
    """Function to recognize speech using the microphone."""
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        st.info("🎤 Say your question to AI (hold your microphone close).")
        recognizer.adjust_for_ambient_noise(source)  # Adjust for ambient noise
        audio = recognizer.listen(source, timeout=5)
        try:
            # Recognize the speech using Google Web Speech API
            question = recognizer.recognize_google(audio)
            st.success(f"🎤 You said: {question}")
            return question
        except sr.UnknownValueError:
            st.error("⚠ Sorry, I couldn't understand what you said.")
        except sr.RequestError:
            st.error("⚠ Could not request results from the speech recognition service.")
        return None

if uploaded_file is not None:
    try:
        # Load the dataset
        if uploaded_file.name.endswith('.csv'):
            df = pd.read_csv(uploaded_file)
        elif uploaded_file.name.endswith('.xlsx'):
            df = pd.read_excel(uploaded_file, engine='openpyxl')

        # Check if the dataset is empty
        if df.empty:
            st.error("🚨 The uploaded file is empty. Please upload a valid dataset.")
        else:
            st.write("### 📂 Dataset Preview")
            st.dataframe(df.head(100))

            # Convert to SmartDataframe
            sdf = SmartDataframe(df, config={"llm": llm})

            # AI-Generated Dataset Summary
            st.write("### 📊 AI-Generated Data Summary")
            try:
                summary = sdf.chat("Summarize this dataset in a few sentences.")
                st.write(summary)
            except Exception as e:
                st.error(f"🤖 AI Error: {e}")

            # Summary Statistics
            st.write("### 📈 Summary Statistics")
            st.write(df.describe())

            # Check for Missing Values
            st.write("### ❗ Missing Values")
            missing_values = df.isnull().sum()
            st.write(missing_values)

            # If there are missing values, offer an option to fill them
            if missing_values.any():
                st.write("### 💡 Fill Missing Values")

                # Column-wise missing value handling based on data type
                columns_with_na = df.columns[df.isnull().any()].tolist()
                for column in columns_with_na:
                    st.write(f"#### {column} (Data Type: {df[column].dtype})")

                    # AI suggestion for column type
                    ai_column_suggestion = None
                    try:
                        ai_column_suggestion = sdf.chat(f"How should I handle missing values in the '{column}' column?")
                    except Exception:
                        ai_column_suggestion = "AI Suggestion Unavailable."

                    st.write(f"AI Suggestion for '{column}': {ai_column_suggestion}")

                    # Provide options to fill missing values based on data type
                    if df[column].dtype in ['float64', 'int64']:
                        fill_na_option = st.radio(
                            f"How to fill missing values in '{column}'?",
                            options=["Mean", "Median", "Mode", "Leave As Is", "Use AI Suggestion"],
                            key=column
                        )

                        if fill_na_option == "Mean":
                            df[column].fillna(df[column].mean(), inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with Mean.")
                        elif fill_na_option == "Median":
                            df[column].fillna(df[column].median(), inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with Median.")
                        elif fill_na_option == "Mode":
                            df[column].fillna(df[column].mode()[0], inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with Mode.")
                        elif fill_na_option == "Leave As Is":
                            st.info(f"🛑 No changes made to missing values in '{column}'.")
                        elif fill_na_option == "Use AI Suggestion" and ai_column_suggestion != "AI Suggestion Unavailable.":
                            # Apply AI suggestion if available
                            df[column].fillna(ai_column_suggestion, inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with AI Suggested Method.")
                    elif df[column].dtype == 'object':
                        fill_na_option = st.radio(
                            f"How to fill missing values in '{column}'? (Categorical Data)",
                            options=["Mode", "Leave As Is", "Use AI Suggestion"],
                            key=column
                        )

                        if fill_na_option == "Mode":
                            df[column].fillna(df[column].mode()[0], inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with Mode.")
                        elif fill_na_option == "Leave As Is":
                            st.info(f"🛑 No changes made to missing values in '{column}'.")
                        elif fill_na_option == "Use AI Suggestion" and ai_column_suggestion != "AI Suggestion Unavailable.":
                            # Apply AI suggestion if available
                            df[column].fillna(ai_column_suggestion, inplace=True)
                            st.success(f"✅ Filled missing values in '{column}' with AI Suggested Method.")

                # *Updated Summary and Cleaned Dataset* - only displayed after missing value handling
                if st.button("Show Cleaned Dataset and Updated Summary"):
                    st.write("### 📊 Updated Summary After Filling Missing Values")
                    st.write(df.describe())
                    st.write("### ✅ Missing Values After Cleaning")
                    st.write(df.isnull().sum())

                    # Option to Download Cleaned Data
                    st.sidebar.download_button(
                        label="📥 Download Cleaned Dataset",
                        data=df.to_csv(index=False),
                        file_name="cleaned_dataset.csv",
                        mime="text/csv"
                    )

                    # AI KPI Suggestions based on cleaned data
                    st.write("### 💡 AI-Powered KPI Suggestions")
                    try:
                        kpi_suggestions = sdf.chat(f"Based on the cleaned dataset, what are realistic KPIs we should track?")
                        st.write(f"🔑 Suggested KPIs: {kpi_suggestions}")
                    except Exception as e:
                        st.error(f"⚠ Error generating KPI suggestions: {e}")

            # AI-Powered Data Query - Text Input
            st.write("### 💬 Ask a Question")
            query = st.text_input("Enter your question about the data:")
            if query:
                try:
                    response = sdf.chat(query)
                    st.write("#### 🤖 AI Response:")
                    st.write(response)
                except Exception as e:
                    st.error(f"⚠ Error: {e}")

            # AI-Powered Data Query - Voice Input
            if st.button("🎤 Ask AI with Your Voice"):
                question = recognize_speech()
                if question:
                    try:
                        response = sdf.chat(question)
                        st.write("#### 🤖 AI Response:")
                        st.write(response)
                    except Exception as e:
                        st.error(f"⚠ Error processing voice question: {e}")

            # AI-Suggested Visualization
            st.write("### 📊 AI-Suggested Visualization")
            try:
                chart_suggestion = sdf.chat("What is the best visualization for this dataset?")
                st.write(f"📊 AI Suggests: {chart_suggestion}")
            except Exception as e:
                st.write("⚠ AI Suggestion Unavailable")

            # Visualization
            st.write("### 📊 Generate Visualization")
            chart_type = st.selectbox("Select Chart Type",
                                      ["Bar Chart", "Line Chart", "Scatter Plot", "Pie Chart", "Histogram", "Box Plot",
                                       "Heatmap"])
            x_col = st.selectbox("Select X-axis Column", df.columns)
            y_col = st.selectbox("Select Y-axis Column", df.columns)

            if st.button("Generate Chart"):
                try:
                    fig = plt.figure(figsize=(10, 6))
                    if chart_type == "Bar Chart":
                        sns.barplot(data=df, x=x_col, y=y_col)
                    elif chart_type == "Line Chart":
                        sns.lineplot(data=df, x=x_col, y=y_col)
                    elif chart_type == "Scatter Plot":
                        sns.scatterplot(data=df, x=x_col, y=y_col)
                    elif chart_type == "Pie Chart":
                        df[y_col].value_counts().plot.pie(autopct='%1.1f%%', startangle=90, cmap='viridis')
                    elif chart_type == "Histogram":
                        sns.histplot(data=df, x=x_col, bins=20, kde=True)
                    elif chart_type == "Box Plot":
                        sns.boxplot(data=df, x=x_col, y=y_col)
                    elif chart_type == "Heatmap":
                        sns.heatmap(df.corr(), annot=True, cmap='coolwarm')
                    plt.title(f"{chart_type} of {y_col} vs {x_col}")
                    plt.xticks(rotation=45)
                    st.pyplot(fig)

                    # Downloadable Chart
                    buf = get_chart_download_link(fig)
                    st.sidebar.download_button(
                        label="📥 Download Chart",
                        data=buf,
                        file_name=f"{chart_type}{x_col}_vs{y_col}.png",
                        mime="image/png"
                    )

                except Exception as e:
                    st.error(f"⚠ Error generating chart: {e}")

    except Exception as e:
        st.error(f"⚠ Error reading file: {e}")

else:
    st.info("📥 Upload a dataset to start."
