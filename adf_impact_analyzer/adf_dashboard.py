"""
═══════════════════════════════════════════════════════════════════════════════
Azure Data Factory Analyzer Dashboard v10.1 - FIXED & PRODUCTION READY
═══════════════════════════════════════════════════════════════════════════════

✨ FEATURES:
  🌐 Advanced Network Visualizations (2D & 3D)
  📊 20+ Interactive Charts
  🎨 Modern Material Design UI
  🔍 Smart Search & Filtering
  📈 Real-time Analytics
  💡 AI-Powered Insights
  🎯 Impact Analysis
  📱 Responsive Design
  📥 Multiple Export Formats

FIXES APPLIED:
  ✅ Fixed all incomplete functions
  ✅ Fixed data structure compatibility with v9.1 analyzer
  ✅ Fixed session state management
  ✅ Fixed CSS rendering issues
  ✅ Added comprehensive error handling
  ✅ Optimized for large datasets
  ✅ Fixed network visualization bugs
  ✅ Added caching for performance
  ✅ Fixed Excel sheet name mismatches

Author: Enterprise ADF Team
Date: 2024
Version: 10.1 - Fixed & Production Ready
═══════════════════════════════════════════════════════════════════════════════
"""

import streamlit as st
import pandas as pd
import numpy as np
import json
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
try:
    import networkx as nx
    HAS_NETWORKX = True
except Exception:
    # networkx is optional for some visualizations; allow dashboard to import
    nx = None
    HAS_NETWORKX = False
from pathlib import Path
from datetime import datetime, timedelta
import re
from collections import defaultdict, Counter
from typing import Dict, List, Any, Tuple, Optional, Set
import warnings
import io
import traceback

# Suppress warnings
warnings.filterwarnings("ignore")

# Check optional dependencies
try:
    import openpyxl

    HAS_OPENPYXL = True
except ImportError:
    HAS_OPENPYXL = False

# ═══════════════════════════════════════════════════════════════════════════
# PAGE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

st.set_page_config(
    page_title="ADF Analyzer v10.1 - Dashboard",
    page_icon="🏭",
    layout="wide",
    initial_sidebar_state="expanded",
    menu_items={
        "Get Help": None,
        "Report a bug": None,
        "About": """
        # ADF Analyzer v10.1
        
        **Enterprise Azure Data Factory Analysis Dashboard**
        
        Features:
        - Network Visualizations (2D & 3D)
        - Impact Analysis
        - Orphaned Resource Detection
        - Data Lineage Tracking
        - Interactive Charts
        - Smart Filtering
        """,
    },
)

# ═══════════════════════════════════════════════════════════════════════════
# CUSTOM CSS - MODERN DESIGN (FIXED & OPTIMIZED)
# ═══════════════════════════════════════════════════════════════════════════


def load_custom_css():
    """Load optimized custom CSS"""
    st.markdown(
        """
    <style>
        /* ═══════════════════════════════════════════════════════════════ */
        /* GLOBAL STYLES */
        /* ═══════════════════════════════════════════════════════════════ */
        
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        
        * {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }
        
        .main {
            padding: 0rem 1rem;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* HEADER */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .main-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            border-radius: 15px;
            margin-bottom: 2rem;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            text-align: center;
        }
        
        .main-header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 700;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        .main-header p {
            margin: 10px 0 0 0;
            font-size: 1.1em;
            opacity: 0.95;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* METRIC CARDS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .metric-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 1.5rem;
            border-radius: 12px;
            color: white;
            text-align: center;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
            transition: transform 0.3s;
            margin-bottom: 1rem;
        }
        
        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 30px rgba(0, 0, 0, 0.25);
        }
        
        .metric-value {
            font-size: 2.5em;
            font-weight: 700;
            margin: 10px 0;
        }
        
        .metric-label {
            font-size: 0.9em;
            opacity: 0.95;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* GRADIENT VARIANTS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .gradient-purple { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .gradient-pink { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .gradient-blue { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); }
        .gradient-green { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); }
        .gradient-orange { background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); }
        .gradient-teal { background: linear-gradient(135deg, #30cfd0 0%, #330867 100%); }
        .gradient-fire { background: linear-gradient(135deg, #ff9a56 0%, #ff6a88 100%); }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* BADGES */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .badge {
            display: inline-block;
            padding: 6px 14px;
            margin: 3px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        
        .badge-critical { background: #FF4444; color: white; }
        .badge-high { background: #FF8800; color: white; }
        .badge-medium { background: #FFBB33; color: black; }
        .badge-low { background: #00C851; color: white; }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* INFO CARDS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .info-card {
            background: white;
            padding: 1.5rem;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            margin-bottom: 1rem;
            border-left: 4px solid #667eea;
            transition: all 0.3s;
        }
        
        .info-card:hover {
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
            transform: translateY(-3px);
        }
        
        .info-card h3, .info-card h4 {
            margin: 0 0 10px 0;
            color: #667eea;
            font-weight: 700;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* TABS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .stTabs [data-baseweb="tab-list"] {
            gap: 8px;
            background: white;
            padding: 10px;
            border-radius: 10px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }
        
        .stTabs [data-baseweb="tab"] {
            padding: 12px 24px;
            background: #f8f9fa;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .stTabs [data-baseweb="tab"]:hover {
            background: #e9ecef;
        }
        
        .stTabs [data-baseweb="tab"][aria-selected="true"] {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* BUTTONS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .stButton > button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 0.5rem 1.5rem;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .stButton > button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(102, 126, 234, 0.4);
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* DATAFRAME */
        /* ═══════════════════════════════════════════════════════════════ */
        
        .dataframe {
            border-radius: 8px !important;
            overflow: hidden;
        }
        
        /* ═══════════════════════════════════════════════════════════════ */
        /* ANIMATIONS */
        /* ═══════════════════════════════════════════════════════════════ */
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .fade-in {
            animation: fadeIn 0.6s ease-out;
        }
    </style>
    """,
        unsafe_allow_html=True,
    )


def _ensure_css_loaded():
    """Ensure the custom CSS is injected only once per session."""
    if not st.session_state.get("_custom_css_loaded", False):
        load_custom_css()
        st.session_state["_custom_css_loaded"] = True


def render_info_card(title: str, body: str, color: str = None, small: bool = False):
    """Render a consistent info-card using the app CSS.

    Args:
        title: Heading text (can include emoji)
        body: HTML or plain text for card body (can include small tags)
        color: Optional hex color string to set the left border and title color
        small: If True use a smaller font for body
    """
    _ensure_css_loaded()
    border_style = f"border-left: 4px solid {color};" if color else ""
    title_color = f"color: {color};" if color else ""
    small_class = "font-size:0.95em;" if small else ""

    html = f"""
<div class="info-card" style="{border_style}">
    <h4 style="{title_color}">{title}</h4>
    <div style="{small_class}">{body}</div>
</div>
"""
    st.markdown(html, unsafe_allow_html=True)


def render_feature_card(title: str, bullets: List[str], hint: str = None):
    """Render a visually prominent gradient feature card (matches the sample look).

    Uses a safe subset of CSS (gradient background, rounded corners) that Streamlit
    supports via inline styles.
    """
    _ensure_css_loaded()
    bullets_html = "".join([f"<p>• {b}</p>" for b in bullets])
    hint_html = f"<p style='color:#999; margin-top:12px;'>{hint}</p>" if hint else ""

    html = f"""
<div style="background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); padding: 20px; border-radius: 12px; margin: 12px 0;">
    <h3 style="color: #667eea; margin-bottom: 12px;">{title}</h3>
    <div style="text-align: left; display: inline-block; max-width: 720px;">
        {bullets_html}
    </div>
    {hint_html}
</div>
"""
    st.markdown(html, unsafe_allow_html=True)


def prepare_pie_data(df: pd.DataFrame, label_col: str, value_col: str, top_n: Optional[int] = None):
    """Helper to prepare pie chart labels and values safely.

    - Coerces value_col to numeric
    - Groups by label_col and sums values
    - Sorts descending and optionally takes top_n
    - Drops zero-value entries
    Returns (labels, values) as lists.
    """
    if df is None or df.empty:
        return [], []

    if label_col not in df.columns or value_col not in df.columns:
        return [], []

    tmp = df[[label_col, value_col]].copy()
    tmp[value_col] = pd.to_numeric(tmp[value_col], errors="coerce").fillna(0)
    grouped = tmp.groupby(label_col, as_index=False)[value_col].sum()
    grouped = grouped[grouped[value_col] > 0].sort_values(value_col, ascending=False)

    if top_n:
        grouped = grouped.head(top_n)

    labels = grouped[label_col].astype(str).tolist()
    values = grouped[value_col].astype(int).tolist()
    return labels, values


def to_csv_bytes(df: pd.DataFrame) -> bytes:
    """Return CSV bytes with UTF-8 BOM so Excel opens it correctly."""
    try:
        csv_str = df.to_csv(index=False, encoding="utf-8-sig")
        return csv_str.encode("utf-8-sig")
    except Exception:
        # Fallback without BOM
        return df.to_csv(index=False).encode("utf-8")


def to_json_bytes(obj: Any) -> bytes:
    """Return JSON bytes (utf-8)."""
    return json.dumps(obj, indent=2, default=str).encode("utf-8")


def to_excel_bytes(dfs: Dict[str, pd.DataFrame]) -> bytes:
    """Write a dict of DataFrames to an in-memory Excel workbook and return bytes.

    dfs: mapping of sheet_name -> DataFrame
    """
    buffer = io.BytesIO()
    try:
        with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
            for sheet_name, df in dfs.items():
                try:
                    df.to_excel(writer, sheet_name=sheet_name[:31], index=False)
                except Exception:
                    # If df is not a DataFrame, skip
                    continue
        return buffer.getvalue()
    except Exception:
        return b""


# ═══════════════════════════════════════════════════════════════════════════
# SESSION STATE INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════


def initialize_session_state():
    """Initialize all session state variables with defaults"""

    # Data state
    defaults = {
        "data_loaded": False,
        "excel_data": {},
        "dependency_graph": None,
        "analysis_metadata": {},
            "show_debug_panel": False,
        # UI state
        "selected_theme": "dark",
        "filter_options": ["All"],
        "search_query": "",
        "selected_pipeline": None,
        # Cache
        "cached_graphs": {},
        "cached_metrics": {},
        # File upload tracking
        "uploaded_file_name": None,
        "last_load_time": None,
    }

    for key, value in defaults.items():
        if key not in st.session_state:
            st.session_state[key] = value


# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════


def safe_get_dataframe(sheet_name: str, *alternative_names: str) -> pd.DataFrame:
    """
    Safely get DataFrame from excel_data with fallback names

    Args:
        sheet_name: Primary sheet name to look for
        *alternative_names: Alternative sheet names to try

    Returns:
        DataFrame if found, empty DataFrame otherwise
    """
    # Try primary name (exact)
    excel_data = st.session_state.excel_data or {}

    if sheet_name in excel_data:
        df = excel_data[sheet_name]
        if isinstance(df, pd.DataFrame):
            return df

    # Try alternatives (exact)
    for alt_name in alternative_names:
        if alt_name in excel_data:
            df = excel_data[alt_name]
            if isinstance(df, pd.DataFrame):
                return df

    # Fallback: try normalized matching (ignore case, underscores, spaces)
    def _normalize(key: str) -> str:
        return re.sub(r"[_\s]+", "", str(key)).lower()

    target_norm = _normalize(sheet_name)

    # Check exact keys normalized
    for key, df in excel_data.items():
        try:
            if _normalize(key) == target_norm and isinstance(df, pd.DataFrame):
                return df
        except Exception:
            continue

    # Try normalized alternatives
    for alt_name in alternative_names:
        alt_norm = _normalize(alt_name)
        for key, df in excel_data.items():
            try:
                if _normalize(key) == alt_norm and isinstance(df, pd.DataFrame):
                    return df
            except Exception:
                continue

    # Special-case fallbacks / synthesized sheets
    # 1) GlobalParameterUsage: if not present but GlobalParameters exists, synthesize a usage table
    try:
        if target_norm in ("globalparameterusage", "globalparameter_usage"):
            # find GlobalParameters sheet (normalized)
            for key, df in excel_data.items():
                if _normalize(key) == "globalparameters" and isinstance(df, pd.DataFrame):
                    gp = df
                    # Synthesize usage counts = 0 (best-effort) so charts render
                    synth_rows = []
                    # try to find a column that looks like name
                    name_col = None
                    for c in gp.columns:
                        if "name" in c.lower() or "parameter" in c.lower():
                            name_col = c
                            break
                    if name_col is None and len(gp.columns) > 0:
                        name_col = gp.columns[0]

                    for _, r in gp.iterrows():
                        pname = r.get(name_col, "") if name_col else ""
                        synth_rows.append({
                            "ParameterName": pname,
                            "TotalUsages": 0,
                            "UniqueResources": 0,
                            "UsageByType": "",
                            "SampleUsages": "",
                        })

                    return pd.DataFrame(synth_rows)
    except Exception:
        pass

    # 2) FactoryInfo: synthesize basic factory info from Summary or uploaded file name
    try:
        if target_norm in ("factoryinfo", "factory_info"):
            # try to build from Summary sheet metrics if available
            summary_df = excel_data.get("Summary") or excel_data.get("summary")
            factory_name = None
            location = "Unknown"
            identity = "Unknown"
            public_network = "Unknown"
            encryption = "Unknown"

            if isinstance(summary_df, pd.DataFrame) and not summary_df.empty:
                try:
                    metrics = dict(summary_df.set_index("Metric")["Value"])
                    factory_name = metrics.get("FactoryName") or metrics.get("Factory Name")
                    location = metrics.get("Location", location)
                    identity = metrics.get("IdentityType", identity)
                    public_network = metrics.get("PublicNetworkAccess", public_network)
                    encryption = metrics.get("EncryptionEnabled", encryption)
                except Exception:
                    pass

            # Fallback to uploaded file name if still unknown
            if not factory_name:
                factory_name = st.session_state.get("uploaded_file_name") or "UnknownFactory"

            return pd.DataFrame([
                {
                    "FactoryName": factory_name,
                    "Location": location,
                    "IdentityType": identity,
                    "PublicNetworkAccess": public_network,
                    "EncryptionEnabled": encryption,
                }
            ])
    except Exception:
        pass

    # 3) DataDictionary: synthesize a light-weight data dictionary by inspecting available sheets
    try:
        if target_norm in ("datadictionary", "data_dictionary"):
            rows = []
            for sname, df in excel_data.items():
                if not isinstance(df, pd.DataFrame):
                    continue
                for col in df.columns:
                    try:
                        dtype = str(df[col].dtype)
                    except Exception:
                        dtype = "object"
                    example = ""
                    try:
                        sample = df[col].dropna()
                        if not sample.empty:
                            example = str(sample.iloc[0])
                    except Exception:
                        example = ""

                    rows.append(
                        {
                            "Sheet": sname,
                            "Column": col,
                            "Description": "",
                            "DataType": dtype,
                            "Example": example,
                        }
                    )

            return pd.DataFrame(rows)
    except Exception:
        pass

    # 4) Credentials: synthesize an empty credentials table if missing
    try:
        if target_norm in ("credentials", "credential", "credentialinfo"):
            return pd.DataFrame(
                columns=["LinkedService", "CredentialType", "SecretName", "Notes"]
            )
    except Exception:
        pass

    # 5) Managed Private Endpoints / Managed VNets: provide empty placeholders
    try:
        if target_norm in ("managedprivateendpoints", "managed_private_endpoints"):
            return pd.DataFrame(columns=["Name", "ResourceId", "LinkedService", "State"])
    except Exception:
        pass

    try:
        if target_norm in ("managedvnets", "managed_vnets", "managedvnet"):
            return pd.DataFrame(columns=["Name", "ResourceId", "Type", "Notes"])
    except Exception:
        pass

    # 6) Errors: empty errors table
    try:
        if target_norm in ("errors", "errorlog"):
            return pd.DataFrame(columns=["ErrorType", "Message", "Object"])
    except Exception:
        pass

    # 7) CircularDependencies: empty placeholder
    try:
        if target_norm in ("circulardependencies", "circular_dependencies"):
            return pd.DataFrame(columns=["Pipeline", "CyclePath"])
    except Exception:
        pass
    except Exception:
        pass

    # Not found
    return pd.DataFrame()


def get_summary_metric(metric_name: str, default: Any = 0) -> Any:
    """
    Get metric from Summary sheet

    Args:
        metric_name: Name of the metric
        default: Default value if not found

    Returns:
        Metric value or default
    """
    summary = safe_get_dataframe("Summary")

    if summary.empty or "Metric" not in summary.columns:
        return default

    try:
        metrics = summary.set_index("Metric")["Value"].to_dict()
        return metrics.get(metric_name, default)
    except:
        return default


def get_count_with_fallback(metric_name: str, fallback_sheets: List[str]) -> int:
    """
    Retrieve a numeric count from the Summary sheet, coercing strings to numbers,
    and fallback to counting rows in one of the provided sheets when the metric
    is missing or zero.

    Args:
        metric_name: Metric name in Summary sheet (e.g., 'Pipelines')
        fallback_sheets: List of possible sheet names to check for row counts

    Returns:
        int count (0 if nothing found)
    """
    val = get_summary_metric(metric_name, 0)

    try:
        if isinstance(val, (int, float)) and not (isinstance(val, bool)):
            if int(val) > 0:
                return int(val)
        # If val is a numeric-looking string, get_summary_metric already coerces it.
    except Exception:
        pass

    # Fallback: inspect sheets for counts
    for s in fallback_sheets:
        df = safe_get_dataframe(s)
        if isinstance(df, pd.DataFrame) and not df.empty:
            return len(df)

    # Another fallback: if dependency graph exists and metric_name mentions 'Dependencies'
    if "Dependency" in metric_name or "Dependencies" in metric_name:
        g = st.session_state.get("dependency_graph")
        if g is not None:
            try:
                return g.number_of_edges()
            except Exception:
                pass

    return 0


def format_number(num: int) -> str:
    """Format number with thousand separators"""
    try:
        return f"{int(num):,}"
    except:
        return str(num)


def truncate_text(text: str, max_length: int = 50) -> str:
    """Truncate text with ellipsis"""
    text = str(text)
    if len(text) <= max_length:
        return text
    return text[: max_length - 3] + "..."


def _merge_split_sheets_inplace(excel_dict: Dict[str, pd.DataFrame]) -> None:
    """Detect sheets split with suffix _P1/_P2/... and merge them into a single sheet.

    This mutates the supplied dict and creates a merged DataFrame under the base
    name if that base name does not already exist. The analyzer uses the pattern
    <SheetName>_P1, <SheetName>_P2 for auto-split exports.
    """
    groups = {}
    for name in list(excel_dict.keys()):
        m = re.match(r"^(.+)_P(\d+)$", name, re.IGNORECASE)
        if m:
            base = m.group(1)
            idx = int(m.group(2))
            groups.setdefault(base, []).append((idx, name))

    for base, parts in groups.items():
        parts.sort()
        frames = []
        for _, part_name in parts:
            df = excel_dict.get(part_name)
            if isinstance(df, pd.DataFrame):
                frames.append(df)

        if frames:
            try:
                merged = pd.concat(frames, ignore_index=True)
                # Only add merged if base not already present (to avoid overwriting)
                if base not in excel_dict:
                    excel_dict[base] = merged
                else:
                    # provide a merged alias if base exists
                    excel_dict[f"{base}_MERGED"] = merged
            except Exception:
                # If concat fails, skip merging but preserve original parts
                continue


def _normalize_sheet_map_inplace(excel_dict: Dict[str, pd.DataFrame]) -> None:
    """Create convenient aliases in the excel_data map for common variants.

    This does not duplicate dataframes unnecessarily; it only adds new keys
    that reference the same DataFrame objects for tolerant lookups.
    """
    def norm(k: str) -> str:
        return re.sub(r"[_\s]+", "", str(k)).lower()

    # Build a mapping of normalized -> existing key (prefer exact matches)
    norm_map: Dict[str, str] = {}
    for key in list(excel_dict.keys()):
        try:
            n = norm(key)
            if n not in norm_map:
                norm_map[n] = key
        except Exception:
            continue

    # Add aliases for some commonly referenced names (safety net)
    aliases = [
        ("linkedserviceusage", ["LinkedServiceUsage", "LinkedService_Usage", "linkedservice_usage"]),
        ("integrationruntimeusage", ["IntegrationRuntimeUsage", "IntegrationRuntime_Usage", "integrationruntime_usage"]),
        ("globalparameterusage", ["GlobalParameterUsage", "Global_Parameter_Usage", "globalparameter_usage"]),
        ("datasetusage", ["DatasetUsage", "Dataset_Usage", "dataset_usage"]),
    ]

    for canonical, variants in aliases:
        # if canonical already resolves, skip
        if canonical in norm_map:
            continue
        for v in variants:
            if v in excel_dict:
                norm_map[canonical] = v
                break

    # Inject alias keys that point to existing DataFrames
    for nkey, existing in norm_map.items():
        if nkey in excel_dict:
            continue
        df = excel_dict.get(existing)
        if isinstance(df, pd.DataFrame):
            excel_dict[nkey] = df


def safe_plotly(
    fig: Optional[go.Figure],
    df: Optional[pd.DataFrame] = None,
    required_columns: Optional[List[str]] = None,
    info_message: Optional[str] = None,
    use_container_width: bool = True,
):
    """
    Safely render a plotly figure in Streamlit.

    - If `df` is provided, ensure it's a DataFrame and (optionally) contains the
      `required_columns`. If checks fail, show a friendly message instead of
      attempting to render the chart.
    - This allows centralizing chart guards so individual renderers remain concise.
    """
    try:
        # If no figure was provided, show a friendly message instead of raising
        if fig is None:
            st.info(info_message or "📊 No chart available to render")
            return

        if df is not None:
            if not isinstance(df, pd.DataFrame) or df.empty:
                st.info(info_message or "📊 No data available for this chart")
                return

            if required_columns:
                missing = [c for c in required_columns if c not in df.columns]
                if missing:
                    st.info(
                        info_message
                        or f"📊 Chart data missing required columns: {', '.join(missing)}"
                    )
                    return

        # If checks passed (or none required), render the figure
        st.plotly_chart(fig, use_container_width=use_container_width)
    except Exception as e:
        st.error(f"❌ Could not render chart: {e}")
        return


# ═══════════════════════════════════════════════════════════════════════════
# MAIN APPLICATION CLASS
# ═══════════════════════════════════════════════════════════════════════════


class ADF_Dashboard:
    """
    Enterprise ADF Analysis Dashboard v10.1

    Fixed & Production Ready
    """

    # Color schemes
    COLORS = {
        "primary": "#667eea",
        "secondary": "#764ba2",
        "success": "#43e97b",
        "danger": "#f5576c",
        "warning": "#fee140",
        "info": "#4facfe",
        "trigger": "#FFD700",
        "dataflow": "#87CEEB",
        "pipeline": "#90EE90",
        "dataset": "#DDA0DD",
        "orphaned": "#FFA07A",
    }

    def __init__(self):
        """Initialize dashboard"""
        initialize_session_state()
        load_custom_css()

    def run(self):
        """Main entry point"""

        # Render header
        self.render_header()

        # Render sidebar
        with st.sidebar:
            self.render_sidebar()

        # Main content
        if st.session_state.data_loaded:
            self.render_main_dashboard()
        else:
            self.render_welcome_screen()

    def render_header(self):
        """Render main header"""
        st.markdown(
            """
        <div class="main-header fade-in">
            <h1>🏭 Azure Data Factory Analyzer v10.1</h1>
            <p>Enterprise Analysis Dashboard - Fixed & Production Ready</p>
        </div>
        """,
            unsafe_allow_html=True,
        )

    def render_sidebar(self):
        """Render sidebar controls"""

        # Branding
        st.markdown(
            """
        <div style="text-align: center; padding: 20px 0;">
            <h2 style="margin: 0;">📊 Control Panel</h2>
            <p style="margin: 5px 0; opacity: 0.7; font-size: 0.9em;">v10.1 Fixed Edition</p>
        </div>
        """,
            unsafe_allow_html=True,
        )

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # FILE UPLOAD
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("### 📁 Data Input")

        uploaded_file = st.file_uploader(
            "Upload Analysis Excel",
            type=["xlsx", "xls"],
            help="Upload adf_analysis_latest.xlsx from ADF Analyzer v9.1",
            label_visibility="collapsed",
        )

        col1, col2 = st.columns(2)

        with col1:
            if uploaded_file:
                if st.button("🔍 Load", type="primary", use_container_width=True):
                    self.load_excel_file(uploaded_file)

        with col2:
            if st.button("📊 Sample", use_container_width=True):
                self.load_sample_data()

        # ═══════════════════════════════════════════════════════════════════
        # STATUS
        # ═══════════════════════════════════════════════════════════════════

        if st.session_state.data_loaded:
            st.success("✅ Data Loaded")

            # Show last load time
            if st.session_state.last_load_time:
                st.caption(
                    f"Loaded: {st.session_state.last_load_time.strftime('%H:%M:%S')}"
                )

            st.markdown("---")

            # Quick stats
            self.render_sidebar_stats()

            st.markdown("---")

            # Filters
            self.render_sidebar_filters()

        else:
            st.info("👆 Upload file or load sample data")

            # ═══════════════════════════════════════════════════════════════════
            # FOOTER
            # ═══════════════════════════════════════════════════════════════════
            # Developer debug toggle
            st.markdown("---")
            st.checkbox("Developer: Show debug panel", value=st.session_state.get("show_debug_panel", False), key="show_debug_panel")

            st.markdown("---")
        st.markdown(
            """
        <div style="text-align: center; opacity: 0.7; font-size: 0.8em;">
            <p>Made with ❤️ by ADF Team</p>
            <p>© 2024 v10.1 Fixed</p>
        </div>
        """,
            unsafe_allow_html=True,
        )

    def render_sidebar_stats(self):
        """Render quick stats in sidebar"""

        st.markdown("### 📈 Quick Stats")
        # Use robust fallbacks in case Summary is missing or contains strings
        pipelines = get_count_with_fallback(
            "Pipelines", ["ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis", "Pipelines"]
        )
        dataflows = get_count_with_fallback(
            "DataFlows", ["DataFlows", "DataFlowLineage", "DataFlow_Summary"]
        )
        orphaned = get_count_with_fallback(
            "Orphaned Pipelines", ["OrphanedPipelines", "Orphaned_Pipelines"]
        )

        st.metric("Pipelines", format_number(pipelines))
        st.metric("DataFlows", format_number(dataflows))
        st.metric(
            "Orphaned",
            format_number(orphaned),
            delta=f"-{orphaned}" if orphaned > 0 else "0",
            delta_color="inverse",
        )

    def render_sidebar_filters(self):
        """Render filter controls"""

        st.markdown("### 🎯 Filters")

        # Impact filter (if available)
        impact_df = safe_get_dataframe("ImpactAnalysis", "Pipeline_Analysis")

        if not impact_df.empty and "Impact" in impact_df.columns:
            impact_filter = st.multiselect(
                "Impact Level",
                ["CRITICAL", "HIGH", "MEDIUM", "LOW"],
                default=["CRITICAL", "HIGH"],
                key="impact_filter",
            )

        # Search
        search = st.text_input(
            "🔍 Search", placeholder="Search resources...", label_visibility="collapsed"
        )
        st.session_state.search_query = search

    # ═══════════════════════════════════════════════════════════════════════
    # DATA LOADING & PROCESSING
    # ═══════════════════════════════════════════════════════════════════════

    def load_excel_file(self, uploaded_file):
        """
        Load and process uploaded Excel file

        FIXED:
        - Move summary outside sidebar
        - Proper error handling
        - Progress tracking
        """

        try:
            with st.spinner("🔄 Loading analysis file..."):

                # Progress tracking
                progress_bar = st.progress(0)
                status_text = st.empty()

                # Step 1: Read Excel file
                status_text.text("📖 Reading Excel file...")
                progress_bar.progress(10)

                excel_file = pd.ExcelFile(uploaded_file)
                sheet_names = excel_file.sheet_names

                status_text.text(f"📊 Found {len(sheet_names)} sheets...")
                progress_bar.progress(20)

                # Step 2: Load all sheets
                data = {}
                total_sheets = len(sheet_names)

                for i, sheet_name in enumerate(sheet_names):
                    status_text.text(f"📄 Loading: {sheet_name}...")
                    progress = 20 + int((i / total_sheets) * 50)
                    progress_bar.progress(progress)

                    try:
                        df = pd.read_excel(excel_file, sheet_name=sheet_name)
                        data[sheet_name] = df
                    except Exception as e:
                        st.warning(f"⚠️ Could not load sheet '{sheet_name}': {e}")
                        continue

                status_text.text("💾 Storing data...")
                progress_bar.progress(70)

                # Post-process loaded sheets to merge auto-split parts and
                # create tolerant aliases for common sheet name variants.
                try:
                    _merge_split_sheets_inplace(data)
                    _normalize_sheet_map_inplace(data)
                except Exception:
                    # Non-fatal: if augmentation fails, fall back to raw data
                    pass

                st.session_state.excel_data = data
                st.session_state.uploaded_file_name = uploaded_file.name

                # Step 3: Extract metadata
                status_text.text("📋 Extracting metadata...")
                progress_bar.progress(80)

                self.extract_metadata()

                # Step 4: Build dependency graph
                status_text.text("🕸️ Building dependency graph...")
                progress_bar.progress(90)

                self.build_dependency_graph()

                # Step 5: Complete
                status_text.text("✅ Loading complete!")
                progress_bar.progress(100)

                st.session_state.data_loaded = True
                st.session_state.last_load_time = datetime.now()

                # Clear progress indicators
                import time

                time.sleep(0.5)
                progress_bar.empty()
                status_text.empty()

                # ✅ FIX: Show success message ONLY (no columns in sidebar)
                st.success(f"✅ Successfully loaded: {uploaded_file.name}")

                # ✅ FIX: Summary will show in main area on next rerun
                st.session_state.show_load_summary = True

        except Exception as e:
            st.error(f"❌ Error loading file: {str(e)}")

            # Show detailed error
            with st.expander("🔍 Error Details"):
                st.code(traceback.format_exc())

    def extract_metadata(self):
        """
        Extract and store metadata from loaded data

        FIXED:
        - Safe dictionary access
        - Type validation
        - Default values
        """

        metadata = {
            "loaded_at": datetime.now(),
            "sheets": list(st.session_state.excel_data.keys()),
            "sheet_counts": {},
            "file_name": st.session_state.uploaded_file_name or "Unknown",
        }

        # Count records in each sheet
        for sheet_name, df in st.session_state.excel_data.items():
            if isinstance(df, pd.DataFrame):
                metadata["sheet_counts"][sheet_name] = len(df)

        # Extract summary information
        summary = safe_get_dataframe("Summary")
        if (
            not summary.empty
            and "Metric" in summary.columns
            and "Value" in summary.columns
        ):
            try:
                metadata["summary"] = summary.set_index("Metric")["Value"].to_dict()
            except:
                metadata["summary"] = {}
        else:
            metadata["summary"] = {}

        st.session_state.analysis_metadata = metadata

    def show_load_summary(self):
        """Show summary after successful load"""

        metadata = st.session_state.analysis_metadata

        st.markdown("### 📊 Load Summary")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("Sheets Loaded", len(metadata.get("sheets", [])))

        with col2:
            total_records = sum(metadata.get("sheet_counts", {}).values())
            st.metric("Total Records", format_number(total_records))

        with col3:
            pipelines = get_count_with_fallback(
                "Pipelines", ["ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis", "Pipelines"]
            )
            st.metric("Pipelines", format_number(pipelines))

        with col4:
            dataflows = get_count_with_fallback(
                "DataFlows", ["DataFlows", "DataFlowLineage", "DataFlow_Summary"]
            )
            st.metric("DataFlows", format_number(dataflows))

    def build_dependency_graph(self):
        """
        Build NetworkX dependency graph from loaded data

        FIXED:
        - Compatible with v9.1 analyzer output
        - Proper sheet name matching
        - Error handling
        - Node attribute validation
        """

        try:
            G = nx.DiGraph()

            # ═══════════════════════════════════════════════════════════════
            # Add Pipeline Nodes
            # ═══════════════════════════════════════════════════════════════

            # Try multiple sheet names (v9.1 uses ImpactAnalysis)
            pipeline_df = safe_get_dataframe(
                "ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis", "Pipelines"
            )

            if not pipeline_df.empty:
                for _, row in pipeline_df.iterrows():
                    # Extract pipeline name (try multiple column names)
                    pipeline_name = (
                        row.get("Pipeline")
                        or row.get("pipeline")
                        or row.get("PipelineName")
                        or ""
                    )

                    if not pipeline_name:
                        continue

                    # Extract attributes with safe defaults
                    has_trigger = False
                    has_dataflow = False
                    is_orphaned = False
                    impact = "LOW"

                    # Check for triggers (multiple column formats)
                    if "UpstreamTriggerCount" in row:
                        has_trigger = int(row.get("UpstreamTriggerCount", 0)) > 0
                    elif "UpstreamTriggers" in row:
                        has_trigger = bool(row.get("UpstreamTriggers", ""))
                    elif "Has_Trigger" in row:
                        has_trigger = row.get("Has_Trigger") in ["Yes", True, 1]

                    # Check for dataflows
                    if "DataFlowCount" in row:
                        has_dataflow = int(row.get("DataFlowCount", 0)) > 0
                    elif "UsedDataFlows" in row:
                        has_dataflow = bool(row.get("UsedDataFlows", ""))
                    elif "Has_DataFlow" in row:
                        has_dataflow = row.get("Has_DataFlow") in ["Yes", True, 1]

                    # Check orphaned status
                    if "IsOrphaned" in row:
                        is_orphaned = row.get("IsOrphaned") in ["Yes", True, 1]
                    elif "Is_Orphaned" in row:
                        is_orphaned = row.get("Is_Orphaned") in ["Yes", True, 1]

                    # Get impact level
                    impact = row.get("Impact", row.get("ImpactLevel", "LOW"))

                    # Add node with attributes
                    G.add_node(
                        pipeline_name,
                        type="pipeline",
                        has_trigger=has_trigger,
                        has_dataflow=has_dataflow,
                        is_orphaned=is_orphaned,
                        impact=str(impact),
                    )

            # ═══════════════════════════════════════════════════════════════
            # Add Trigger → Pipeline Edges
            # ═══════════════════════════════════════════════════════════════

            trigger_df = safe_get_dataframe(
                "TriggerDetails", "Trigger_Pipeline", "Triggers"
            )

            if not trigger_df.empty:
                for _, row in trigger_df.iterrows():
                    trigger = row.get("Trigger") or row.get("trigger") or ""
                    pipeline = row.get("Pipeline") or row.get("pipeline") or ""

                    if trigger and pipeline:
                        # Add trigger node if not exists
                        if not G.has_node(trigger):
                            G.add_node(trigger, type="trigger")

                        # Add edge
                        G.add_edge(trigger, pipeline, relation="triggers", weight=3)

            # ═══════════════════════════════════════════════════════════════
            # Add Pipeline → Pipeline Edges
            # ═══════════════════════════════════════════════════════════════

            pipeline_pipeline_df = safe_get_dataframe(
                "Pipeline_Pipeline", "PipelinePipeline"
            )

            if not pipeline_pipeline_df.empty:
                for _, row in pipeline_pipeline_df.iterrows():
                    from_pipeline = (
                        row.get("from_pipeline") or row.get("FromPipeline") or ""
                    )
                    to_pipeline = row.get("to_pipeline") or row.get("ToPipeline") or ""

                    if from_pipeline and to_pipeline:
                        G.add_edge(
                            from_pipeline, to_pipeline, relation="executes", weight=2
                        )

            # ═══════════════════════════════════════════════════════════════
            # Add Pipeline → DataFlow Edges
            # ═══════════════════════════════════════════════════════════════

            pipeline_dataflow_df = safe_get_dataframe(
                "Pipeline_DataFlow", "PipelineDataFlow"
            )

            if not pipeline_dataflow_df.empty:
                for _, row in pipeline_dataflow_df.iterrows():
                    pipeline = row.get("pipeline") or row.get("Pipeline") or ""
                    dataflow = row.get("dataflow") or row.get("DataFlow") or ""

                    if pipeline and dataflow:
                        # Add dataflow node if not exists
                        if not G.has_node(dataflow):
                            G.add_node(dataflow, type="dataflow")

                        # Add edge
                        G.add_edge(
                            pipeline, dataflow, relation="uses_dataflow", weight=1
                        )

            # ═══════════════════════════════════════════════════════════════
            # Add Dataset Nodes from DataLineage
            # ═══════════════════════════════════════════════════════════════

            lineage_df = safe_get_dataframe("DataLineage", "Data_Lineage")

            if not lineage_df.empty:
                for _, row in lineage_df.iterrows():
                    source = row.get("Source", "")
                    sink = row.get("Sink", "")

                    if source and not G.has_node(source):
                        G.add_node(source, type="dataset")

                    if sink and not G.has_node(sink):
                        G.add_node(sink, type="dataset")

                    if source and sink:
                        G.add_edge(source, sink, relation="data_flow", weight=1)

            # Store graph
            st.session_state.dependency_graph = G

            # Calculate metrics
            st.session_state.graph_metrics = {
                "nodes": G.number_of_nodes(),
                "edges": G.number_of_edges(),
                "density": nx.density(G) if G.number_of_nodes() > 0 else 0,
                "is_directed": G.is_directed(),
            }

        except Exception as e:
            st.error(f"⚠️ Error building dependency graph: {e}")
            # Create empty graph as fallback
            st.session_state.dependency_graph = nx.DiGraph()
            st.session_state.graph_metrics = {
                "nodes": 0,
                "edges": 0,
                "density": 0,
                "is_directed": True,
            }

    def load_sample_data(self):
        """
        Load comprehensive sample data for demonstration

        FIXED:
        - Compatible with v9.1 analyzer output format
        - Realistic data structure
        - All required sheets
        """

        with st.spinner("🎮 Loading sample data..."):

            # Create realistic sample data matching v9.1 output
            sample_data = {
                "Summary": pd.DataFrame(
                    [
                        {
                            "Metric": "Analysis Date",
                            "Value": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                        },
                        {"Metric": "Source File", "Value": "sample_factory.json"},
                        {
                            "Metric": "Analyzer Version",
                            "Value": "9.1 - Fixed & Enhanced",
                        },
                        {"Metric": "", "Value": ""},
                        {"Metric": "=== RESOURCES ===", "Value": ""},
                        {"Metric": "Pipelines", "Value": 25},
                        {"Metric": "DataFlows", "Value": 12},
                        {"Metric": "Datasets", "Value": 45},
                        {"Metric": "LinkedServices", "Value": 18},
                        {"Metric": "Triggers", "Value": 15},
                        {"Metric": "Integration Runtimes", "Value": 5},
                        {"Metric": "", "Value": ""},
                        {"Metric": "=== DEPENDENCIES ===", "Value": ""},
                        {"Metric": "Total Dependencies", "Value": 127},
                        {"Metric": "Trigger → Pipeline", "Value": 35},
                        {"Metric": "Pipeline → DataFlow", "Value": 28},
                        {"Metric": "Pipeline → Pipeline", "Value": 18},
                        {"Metric": "", "Value": ""},
                        {"Metric": "=== ORPHANED RESOURCES ===", "Value": ""},
                        {"Metric": "Orphaned Pipelines", "Value": 3},
                        {"Metric": "Orphaned Datasets", "Value": 5},
                        {"Metric": "Orphaned LinkedServices", "Value": 2},
                        {"Metric": "", "Value": ""},
                        {"Metric": "=== QUALITY ===", "Value": ""},
                        {"Metric": "Parse Errors", "Value": 0},
                    ]
                ),
                "ImpactAnalysis": pd.DataFrame(
                    [
                        {
                            "Pipeline": "PL_MainDataIngestion",
                            "Impact": "CRITICAL",
                            "BlastRadius": 15,
                            "DirectUpstreamTriggers": "TR_Hourly, TR_Daily",
                            "DirectUpstreamTriggerCount": 2,
                            "DirectUpstreamPipelines": "",
                            "DirectUpstreamPipelineCount": 0,
                            "DirectDownstreamPipelines": "PL_Transform, PL_Validate",
                            "DirectDownstreamPipelineCount": 2,
                            "UsedDataFlows": "DF_CleanData",
                            "DataFlowCount": 1,
                            "UsedDatasets": "DS_RawData, DS_StagingData",
                            "DatasetCount": 2,
                            "IsOrphaned": "No",
                        },
                        {
                            "Pipeline": "PL_DataTransformation",
                            "Impact": "HIGH",
                            "BlastRadius": 12,
                            "DirectUpstreamTriggers": "TR_Hourly",
                            "DirectUpstreamTriggerCount": 1,
                            "DirectUpstreamPipelines": "PL_MainDataIngestion",
                            "DirectUpstreamPipelineCount": 1,
                            "DirectDownstreamPipelines": "PL_DataQuality",
                            "DirectDownstreamPipelineCount": 1,
                            "UsedDataFlows": "DF_Transform, DF_Aggregate",
                            "DataFlowCount": 2,
                            "UsedDatasets": "DS_StagingData, DS_ProcessedData",
                            "DatasetCount": 2,
                            "IsOrphaned": "No",
                        },
                        {
                            "Pipeline": "PL_DataQuality",
                            "Impact": "MEDIUM",
                            "BlastRadius": 8,
                            "DirectUpstreamTriggers": "",
                            "DirectUpstreamTriggerCount": 0,
                            "DirectUpstreamPipelines": "PL_DataTransformation",
                            "DirectUpstreamPipelineCount": 1,
                            "DirectDownstreamPipelines": "",
                            "DirectDownstreamPipelineCount": 0,
                            "UsedDataFlows": "DF_Validate",
                            "DataFlowCount": 1,
                            "UsedDatasets": "DS_ProcessedData, DS_QualityReports",
                            "DatasetCount": 2,
                            "IsOrphaned": "No",
                        },
                        {
                            "Pipeline": "PL_OrphanedPipeline",
                            "Impact": "LOW",
                            "BlastRadius": 0,
                            "DirectUpstreamTriggers": "",
                            "DirectUpstreamTriggerCount": 0,
                            "DirectUpstreamPipelines": "",
                            "DirectUpstreamPipelineCount": 0,
                            "DirectDownstreamPipelines": "",
                            "DirectDownstreamPipelineCount": 0,
                            "UsedDataFlows": "",
                            "DataFlowCount": 0,
                            "UsedDatasets": "",
                            "DatasetCount": 0,
                            "IsOrphaned": "Yes",
                        },
                        {
                            "Pipeline": "PL_CustomerAnalytics",
                            "Impact": "HIGH",
                            "BlastRadius": 10,
                            "DirectUpstreamTriggers": "TR_Daily",
                            "DirectUpstreamTriggerCount": 1,
                            "DirectUpstreamPipelines": "",
                            "DirectUpstreamPipelineCount": 0,
                            "DirectDownstreamPipelines": "PL_CustomerReports",
                            "DirectDownstreamPipelineCount": 1,
                            "UsedDataFlows": "DF_CustomerMetrics",
                            "DataFlowCount": 1,
                            "UsedDatasets": "DS_CustomerData, DS_Analytics",
                            "DatasetCount": 2,
                            "IsOrphaned": "No",
                        },
                    ]
                ),
                "TriggerDetails": pd.DataFrame(
                    [
                        {
                            "Trigger": "TR_Hourly",
                            "Pipeline": "PL_MainDataIngestion",
                            "TriggerType": "ScheduleTrigger",
                            "Schedule": "Every 1 hour",
                            "State": "Started",
                        },
                        {
                            "Trigger": "TR_Hourly",
                            "Pipeline": "PL_DataTransformation",
                            "TriggerType": "ScheduleTrigger",
                            "Schedule": "Every 1 hour",
                            "State": "Started",
                        },
                        {
                            "Trigger": "TR_Daily",
                            "Pipeline": "PL_MainDataIngestion",
                            "TriggerType": "ScheduleTrigger",
                            "Schedule": "Daily at 00:00",
                            "State": "Started",
                        },
                        {
                            "Trigger": "TR_Daily",
                            "Pipeline": "PL_CustomerAnalytics",
                            "TriggerType": "ScheduleTrigger",
                            "Schedule": "Daily at 00:00",
                            "State": "Started",
                        },
                        {
                            "Trigger": "TR_Weekly",
                            "Pipeline": "PL_WeeklyReport",
                            "TriggerType": "ScheduleTrigger",
                            "Schedule": "Weekly on Monday",
                            "State": "Started",
                        },
                    ]
                ),
                "Pipeline_DataFlow": pd.DataFrame(
                    [
                        {
                            "pipeline": "PL_MainDataIngestion",
                            "dataflow": "DF_CleanData",
                            "activity": "ExecuteDF_Clean",
                        },
                        {
                            "pipeline": "PL_DataTransformation",
                            "dataflow": "DF_Transform",
                            "activity": "ExecuteDF_Transform",
                        },
                        {
                            "pipeline": "PL_DataTransformation",
                            "dataflow": "DF_Aggregate",
                            "activity": "ExecuteDF_Aggregate",
                        },
                        {
                            "pipeline": "PL_DataQuality",
                            "dataflow": "DF_Validate",
                            "activity": "ExecuteDF_Validate",
                        },
                        {
                            "pipeline": "PL_CustomerAnalytics",
                            "dataflow": "DF_CustomerMetrics",
                            "activity": "ExecuteDF_Metrics",
                        },
                    ]
                ),
                "Pipeline_Pipeline": pd.DataFrame(
                    [
                        {
                            "from_pipeline": "PL_MainDataIngestion",
                            "to_pipeline": "PL_DataTransformation",
                            "activity": "ExecutePL_Transform",
                        },
                        {
                            "from_pipeline": "PL_DataTransformation",
                            "to_pipeline": "PL_DataQuality",
                            "activity": "ExecutePL_Quality",
                        },
                        {
                            "from_pipeline": "PL_CustomerAnalytics",
                            "to_pipeline": "PL_CustomerReports",
                            "activity": "ExecutePL_Reports",
                        },
                    ]
                ),
                "ActivityCount": pd.DataFrame(
                    [
                        {"ActivityType": "Copy", "Count": 45, "Percentage": "35.7%"},
                        {
                            "ActivityType": "ExecuteDataFlow",
                            "Count": 28,
                            "Percentage": "22.2%",
                        },
                        {"ActivityType": "Lookup", "Count": 18, "Percentage": "14.3%"},
                        {
                            "ActivityType": "SetVariable",
                            "Count": 15,
                            "Percentage": "11.9%",
                        },
                        {
                            "ActivityType": "ExecutePipeline",
                            "Count": 10,
                            "Percentage": "7.9%",
                        },
                        {
                            "ActivityType": "SqlServerStoredProcedure",
                            "Count": 6,
                            "Percentage": "4.8%",
                        },
                        {
                            "ActivityType": "GetMetadata",
                            "Count": 4,
                            "Percentage": "3.2%",
                        },
                        {
                            "ActivityType": "=== TOTAL ===",
                            "Count": 126,
                            "Percentage": "100.0%",
                        },
                    ]
                ),
                "OrphanedPipelines": pd.DataFrame(
                    [
                        {
                            "Pipeline": "PL_OrphanedPipeline",
                            "Reason": "Not referenced by any trigger or ExecutePipeline activity",
                            "Type": "Orphaned",
                            "Recommendation": "Review for deletion",
                        },
                        {
                            "Pipeline": "PL_LegacyPipeline",
                            "Reason": "Not referenced by any trigger or ExecutePipeline activity",
                            "Type": "Orphaned",
                            "Recommendation": "Consider removing",
                        },
                        {
                            "Pipeline": "PL_TestPipeline",
                            "Reason": "Not referenced by any trigger or ExecutePipeline activity",
                            "Type": "Orphaned",
                            "Recommendation": "Archive or delete",
                        },
                    ]
                ),
                "OrphanedDatasets": pd.DataFrame(
                    [
                        {
                            "Dataset": "DS_UnusedData",
                            "Reason": "Not used by any pipeline or dataflow",
                            "Type": "Orphaned",
                            "Recommendation": "Consider removing",
                        },
                        {
                            "Dataset": "DS_LegacyData",
                            "Reason": "Not used by any pipeline or dataflow",
                            "Type": "Orphaned",
                            "Recommendation": "Archive or delete",
                        },
                    ]
                ),
                "DataLineage": pd.DataFrame(
                    [
                        {
                            "Pipeline": "PL_MainDataIngestion",
                            "Activity": "CopyRawData",
                            "Type": "Copy",
                            "Source": "DS_RawData",
                            "SourceTable": "raw.data",
                            "Sink": "DS_StagingData",
                            "SinkTable": "staging.data",
                            "Transformation": "SqlSource→AzureSqlSink",
                        },
                        {
                            "Pipeline": "PL_DataTransformation",
                            "Activity": "ExecuteDF_Transform",
                            "Type": "DataFlow",
                            "Source": "DS_StagingData",
                            "SourceTable": "staging.data",
                            "Sink": "DS_ProcessedData",
                            "SinkTable": "processed.data",
                            "Transformation": "DataFlow: DF_Transform (Select, DerivedColumn, Aggregate)",
                        },
                    ]
                ),
            }

            # Store sample data
            st.session_state.excel_data = sample_data
            st.session_state.uploaded_file_name = "sample_data.xlsx"
            st.session_state.data_loaded = True
            st.session_state.last_load_time = datetime.now()

            # Extract metadata
            self.extract_metadata()

            # Build graph
            self.build_dependency_graph()

            st.success("✅ Sample data loaded successfully!")
            st.balloons()

            # Show summary
            self.show_load_summary()

    # ═══════════════════════════════════════════════════════════════════════
    # WELCOME SCREEN
    # ═══════════════════════════════════════════════════════════════════════

    def render_welcome_screen(self):
        """Render welcome screen with feature highlights"""

        # Hero section
        col1, col2, col3 = st.columns([1, 2, 1])

        with col2:
            # Hero (concise): emoji, title, subtitle
            st.markdown(
                """
            <div class="info-card fade-in" style="text-align: center; padding: 2rem; margin-top: 1rem;">
                <div style="font-size: 4em; margin-bottom: 12px;">🏭</div>
                <h2 style="color: #667eea; margin-bottom: 6px;">Welcome to ADF Analyzer v10.1!</h2>
                <p style="font-size: 1.05em; color: #666; margin-bottom: 12px;">
                    Upload your ADF Analysis Excel file to unlock powerful insights
                </p>
            </div>
            """,
                unsafe_allow_html=True,
            )

            # Feature card (uses safe helper)
            bullets = [
                "🌐 Network Visualizations - Interactive 2D & 3D dependency graphs",
                "📊 Advanced Charts - 15+ chart types for comprehensive analysis",
                "🎯 Impact Analysis - Understand change impact before making it",
                "⚠️ Orphan Detection - Find unused resources automatically",
                "🔍 Smart Search - Quickly find any resource",
                "📈 Statistics - Activity distribution and usage metrics",
                "📥 Export - Download filtered data and reports",
            ]

            render_feature_card("✨ Key Features", bullets, hint="👈 Use the sidebar to upload your analysis file or load sample data")

        # Feature cards
        st.markdown("<br>", unsafe_allow_html=True)

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.markdown(
                """
            <div class="info-card fade-in" style="text-align: center;">
                <div style="font-size: 3em; color: #667eea;">🌐</div>
                <h4 style="color: #667eea;">Network Graphs</h4>
                <p style="font-size: 0.9em; color: #666;">
                    Visualize dependencies in interactive 2D & 3D graphs
                </p>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col2:
            st.markdown(
                """
            <div class="info-card fade-in" style="text-align: center;">
                <div style="font-size: 3em; color: #f5576c;">🎯</div>
                <h4 style="color: #f5576c;">Impact Analysis</h4>
                <p style="font-size: 0.9em; color: #666;">
                    See what breaks when you make changes
                </p>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col3:
            st.markdown(
                """
            <div class="info-card fade-in" style="text-align: center;">
                <div style="font-size: 3em; color: #43e97b;">⚠️</div>
                <h4 style="color: #43e97b;">Orphan Detection</h4>
                <p style="font-size: 0.9em; color: #666;">
                    Identify unused resources for cleanup
                </p>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col4:
            st.markdown(
                """
            <div class="info-card fade-in" style="text-align: center;">
                <div style="font-size: 3em; color: #4facfe;">📊</div>
                <h4 style="color: #4facfe;">Smart Reports</h4>
                <p style="font-size: 0.9em; color: #666;">
                    Interactive charts and detailed analytics
                </p>
            </div>
            """,
                unsafe_allow_html=True,
            )

        # Quick start guide
        st.markdown("<br>", unsafe_allow_html=True)

        with st.expander("📚 Quick Start Guide"):
            st.markdown(
                """
            ### Getting Started
            
            1. **Run the Analyzer**
               ```bash
               python adf_analyzer_v9_1_fixed.py your_template.json
               ```
            
            2. **Upload the Excel Output**
               - Click "Upload Analysis Excel" in the sidebar
               - Select `adf_analysis_latest.xlsx`
               - Click "🔍 Load"
            
            3. **Explore the Dashboard**
               - Navigate tabs for different views
               - Use filters to focus on specific resources
               - Click items for detailed information
            
            4. **Export Results**
               - Use the Export tab to download filtered data
               - Generate custom reports
            
            ### Or Try Sample Data
            
            Click the "📊 Sample" button in the sidebar to load demo data and explore features.
            """
            )

        # Try sample button
        st.markdown("<br>", unsafe_allow_html=True)
        col1, col2, col3 = st.columns([1, 1, 1])
        with col2:
            if st.button(
                "🎮 Try Sample Data", type="primary", use_container_width=True
            ):
                self.load_sample_data()
                # ═══════════════════════════════════════════════════════════════════════

    # MAIN DASHBOARD RENDERING
    # ═══════════════════════════════════════════════════════════════════════

    def render_main_dashboard(self):
        """
        Render main dashboard with all tabs

        FIXED:
        - Proper tab structure
        - Error handling for each tab
        - Consistent layout
        """
        # ✅ FIX: Show load summary if just loaded
        if st.session_state.get("show_load_summary", False):
            self.show_load_summary()
            st.session_state.show_load_summary = False
            st.markdown("---")

        # Enhanced metrics row
        self.render_enhanced_metrics()

        st.markdown("<br>", unsafe_allow_html=True)

        # Main navigation tabs
        tabs = st.tabs(
            [
                "🏠 Overview",
                "🌐 Network Graph",
                "🎯 Impact Analysis",
                "⚠️ Orphaned Resources",
                "📊 Statistics",
                "🌊 DataFlow Analysis",
                "📈 Data Lineage",
                "🔍 Data Explorer",
                "📥 Export",
            ]
        )

        with tabs[0]:
            try:
                self.render_overview_tab()
            except Exception as e:
                st.error(f"Error rendering Overview: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[1]:
            try:
                self.render_network_tab()
            except Exception as e:
                st.error(f"Error rendering Network: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[2]:
            try:
                self.render_impact_analysis_tab()
            except Exception as e:
                st.error(f"Error rendering Impact Analysis: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[3]:
            try:
                self.render_orphaned_resources_tab()
            except Exception as e:
                st.error(f"Error rendering Orphaned Resources: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[4]:
            try:
                self.render_statistics_tab()
            except Exception as e:
                st.error(f"Error rendering Statistics: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[5]:
            try:
                self.render_dataflow_tab()
            except Exception as e:
                st.error(f"Error rendering DataFlow Analysis: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[6]:
            try:
                self.render_lineage_tab()
            except Exception as e:
                st.error(f"Error rendering Data Lineage: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[7]:
            try:
                self.render_explorer_tab()
            except Exception as e:
                st.error(f"Error rendering Explorer: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

        with tabs[8]:
            try:
                self.render_export_tab()
            except Exception as e:
                st.error(f"Error rendering Export: {e}")
                with st.expander("Debug Info"):
                    st.code(traceback.format_exc())

    def render_enhanced_metrics(self):
        """
        Render enhanced metrics row

        FIXED:
        - Safe metric extraction
        - Default values
        - Proper formatting
        """

        # Get metrics with safe defaults (use fallbacks when Summary is missing)
        pipelines = get_count_with_fallback(
            "Pipelines", ["ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis", "Pipelines"]
        )
        dataflows = get_count_with_fallback(
            "DataFlows", ["DataFlows", "DataFlowLineage", "DataFlow_Summary"]
        )
        datasets = get_count_with_fallback("Datasets", ["Datasets"]) 
        triggers = get_count_with_fallback("Triggers", ["TriggerDetails", "Triggers"]) 
        dependencies = get_count_with_fallback(
            "Total Dependencies", ["ActivityExecutionOrder", "DataLineage", "Pipeline_Pipeline", "Pipeline_DataFlow"]
        )
        orphaned = get_count_with_fallback("Orphaned Pipelines", ["OrphanedPipelines", "Orphaned_Pipelines"]) 

        # Calculate health score
        health_score = 100
        if pipelines > 0:
            orphan_penalty = (orphaned / pipelines) * 50
            health_score = int(100 - orphan_penalty)

        # Create 7 metric cards
        col1, col2, col3, col4, col5, col6, col7 = st.columns(7)

        metric_configs = [
            (col1, "Pipelines", pipelines, "gradient-purple", "📦"),
            (col2, "DataFlows", dataflows, "gradient-pink", "🌊"),
            (col3, "Datasets", datasets, "gradient-blue", "📊"),
            (col4, "Triggers", triggers, "gradient-green", "⏰"),
            (col5, "Dependencies", dependencies, "gradient-orange", "🔗"),
            (col6, "Health", f"{health_score}%", "gradient-teal", "🏥"),
            (
                col7,
                "Orphaned",
                orphaned,
                "gradient-fire" if orphaned > 0 else "gradient-green",
                "⚠️" if orphaned > 0 else "✅",
            ),
        ]

        for col, label, value, gradient, icon in metric_configs:
            with col:
                st.markdown(
                    f"""
                <div class="metric-card {gradient}">
                    <div style="font-size: 1.5em;">{icon}</div>
                    <div class="metric-label">{label}</div>
                    <div class="metric-value">{value if isinstance(value, str) else format_number(value)}</div>
                </div>
                """,
                    unsafe_allow_html=True,
                )

    # ═══════════════════════════════════════════════════════════════════════
    # OVERVIEW TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_overview_tab(self):
        """
        Render overview dashboard

        FIXED:
        - Safe data access
        - Fallback for missing data
        - Proper chart rendering
        """

        st.markdown("### 🏠 Factory Overview Dashboard")

        # Row 1: Pipeline distribution and health
        col1, col2 = st.columns([2, 1])

        with col1:
            self.render_pipeline_distribution_chart()

        with col2:
            self.render_health_gauge()

        st.markdown("---")

        # Row 2: Activity breakdown and resource summary
        col1, col2 = st.columns(2)

        with col1:
            self.render_activity_distribution()

        with col2:
            self.render_resource_summary()

        st.markdown("---")

        # Row 3: Analysis info
        self.render_analysis_info()

    def render_pipeline_distribution_chart(self):
        """Render pipeline category distribution"""

        impact_df = safe_get_dataframe(
            "ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis"
        )

        if impact_df.empty:
            st.info("📊 No pipeline data available")
            return

        # Calculate categories safely
        categories = {}

        # With Triggers
        if "DirectUpstreamTriggerCount" in impact_df.columns:
            categories["With Triggers"] = (
                impact_df["DirectUpstreamTriggerCount"].fillna(0).astype(int) > 0
            ).sum()
        elif "UpstreamTriggerCount" in impact_df.columns:
            categories["With Triggers"] = (
                impact_df["UpstreamTriggerCount"].fillna(0).astype(int) > 0
            ).sum()
        else:
            categories["With Triggers"] = 0

        # With DataFlows
        if "DataFlowCount" in impact_df.columns:
            categories["With DataFlows"] = (
                impact_df["DataFlowCount"].fillna(0).astype(int) > 0
            ).sum()
        else:
            categories["With DataFlows"] = 0

        # Calling Pipelines
        if "DirectDownstreamPipelineCount" in impact_df.columns:
            categories["Calling Pipelines"] = (
                impact_df["DirectDownstreamPipelineCount"].fillna(0).astype(int) > 0
            ).sum()
        elif "DownstreamPipelineCount" in impact_df.columns:
            categories["Calling Pipelines"] = (
                impact_df["DownstreamPipelineCount"].fillna(0).astype(int) > 0
            ).sum()
        else:
            categories["Calling Pipelines"] = 0

        # Orphaned
        if "IsOrphaned" in impact_df.columns:
            categories["Orphaned"] = (impact_df["IsOrphaned"] == "Yes").sum()
        else:
            categories["Orphaned"] = 0

        # Create horizontal bar chart
        fig = go.Figure()

        colors = ["#667eea", "#f093fb", "#4facfe", "#fa709a"]

        fig.add_trace(
            go.Bar(
                y=list(categories.keys()),
                x=list(categories.values()),
                orientation="h",
                marker=dict(color=colors, line=dict(color="white", width=2)),
                text=list(categories.values()),
                textposition="auto",
                textfont=dict(size=14, color="white"),
                hovertemplate="<b>%{y}</b><br>Count: %{x}<extra></extra>",
            )
        )

        fig.update_layout(
            title={
                "text": "📊 Pipeline Categories",
                "font": {"size": 20, "color": "#667eea"},
            },
            xaxis_title="Count",
            height=350,
            margin=dict(l=20, r=20, t=60, b=20),
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            xaxis=dict(gridcolor="rgba(128,128,128,0.2)"),
            showlegend=False,
        )

        safe_plotly(fig, df=impact_df, required_columns=["Impact"], info_message="📊 No pipeline impact data to display")

    def render_health_gauge(self):
        """Render factory health score gauge"""

        pipelines = get_count_with_fallback(
            "Pipelines", ["ImpactAnalysis", "PipelineAnalysis", "Pipeline_Analysis", "Pipelines"]
        )
        orphaned = get_count_with_fallback(
            "Orphaned Pipelines", ["OrphanedPipelines", "Orphaned_Pipelines"]
        )

        # Calculate health score (0-100)
        if pipelines > 0:
            health_score = int((1 - orphaned / pipelines) * 100)
        else:
            health_score = 100

        # Determine status
        if health_score >= 90:
            color = "#43e97b"
            status = "Excellent"
            icon = "🟢"
        elif health_score >= 75:
            color = "#4facfe"
            status = "Good"
            icon = "🔵"
        elif health_score >= 60:
            color = "#fee140"
            status = "Fair"
            icon = "🟡"
        else:
            color = "#f5576c"
            status = "Needs Attention"
            icon = "🔴"

        # Create gauge
        fig = go.Figure(
            go.Indicator(
                mode="gauge+number+delta",
                value=health_score,
                domain={"x": [0, 1], "y": [0, 1]},
                title={"text": f"{icon} Health Score", "font": {"size": 18}},
                delta={"reference": 80, "increasing": {"color": "#43e97b"}},
                gauge={
                    "axis": {"range": [None, 100], "tickwidth": 1},
                    "bar": {"color": color},
                    "bgcolor": "white",
                    "borderwidth": 2,
                    "bordercolor": "gray",
                    "steps": [
                        {"range": [0, 60], "color": "#ffebee"},
                        {"range": [60, 75], "color": "#fff9c4"},
                        {"range": [75, 90], "color": "#e1f5fe"},
                        {"range": [90, 100], "color": "#e8f5e9"},
                    ],
                    "threshold": {
                        "line": {"color": "red", "width": 4},
                        "thickness": 0.75,
                        "value": 90,
                    },
                },
            )
        )

        fig.update_layout(
            height=350,
            margin=dict(l=20, r=20, t=60, b=20),
            paper_bgcolor="rgba(0,0,0,0)",
        )

        safe_plotly(fig)

    def render_activity_distribution(self):
        """Render activity type distribution pie chart"""

        activity_df = safe_get_dataframe("ActivityCount")

        if activity_df.empty:
            st.info("📊 No activity data available")
            return

        # Filter out total rows and coerce Count to numeric
        if "ActivityType" in activity_df.columns:
            activity_df = activity_df[~activity_df["ActivityType"].astype(str).str.contains("TOTAL", na=False)]
        if "Count" in activity_df.columns:
            activity_df["Count"] = pd.to_numeric(activity_df["Count"], errors="coerce").fillna(0).astype(int)

        # Aggregate by ActivityType to ensure pie percentages are accurate
        if "ActivityType" in activity_df.columns and "Count" in activity_df.columns:
            grouped = (
                activity_df.groupby("ActivityType", as_index=False)["Count"].sum().sort_values("Count", ascending=False)
            )
        else:
            grouped = pd.DataFrame(columns=["ActivityType", "Count"])

        # Take top 10 activity types
        grouped = grouped.head(10)

        if grouped.empty:
            st.info("📊 No activity data to display")
            return

        # Compute totals and percentages explicitly to avoid any Plotly rounding surprises
        total = int(grouped["Count"].sum())
        if total == 0:
            st.info("📊 Activity counts sum to zero, nothing to display")
            return

        # Prepare labels, values and percent customdata
        labels = grouped["ActivityType"].astype(str).tolist()
        values = grouped["Count"].astype(int).tolist()
        percents = [v / total for v in values]

        # Create pie chart (use explicit texttemplate with customdata for percent)
        fig = go.Figure(
            data=[
                go.Pie(
                    labels=labels,
                    values=values,
                    customdata=percents,
                    hole=0.4,
                    marker=dict(
                        colors=px.colors.qualitative.Set3,
                        line=dict(color="white", width=2),
                    ),
                    textinfo="none",
                    texttemplate="%{label}<br>%{customdata:.1%} (%{value})",
                    insidetextorientation="radial",
                    textfont=dict(size=11),
                    hovertemplate="<b>%{label}</b><br>Count: %{value}<br>%{customdata:.1%}<extra></extra>",
                )
            ]
        )

        fig.update_layout(
            title={
                "text": "⚡ Activity Distribution",
                "font": {"size": 20, "color": "#667eea"},
            },
            height=400,
            margin=dict(l=20, r=20, t=60, b=20),
            paper_bgcolor="rgba(0,0,0,0)",
            showlegend=True,
            legend=dict(
                orientation="v", yanchor="middle", y=0.5, xanchor="left", x=1.05
            ),
        )

        safe_plotly(fig, df=activity_df, required_columns=["ActivityType", "Count"], info_message="📊 No activity data to display")

    def render_resource_summary(self):
        """Render resource summary treemap"""

        # Get resource counts
        resources = []
        counts = []

        # Build resource type counts robustly by inspecting loaded sheets first
        def sheet_count(*names):
            """Return number of rows from the first matching sheet name."""
            for n in names:
                df = safe_get_dataframe(n)
                if not df.empty:
                    return len(df)
            return 0

        resource_types = [
            ("Pipelines", sheet_count("PipelineAnalysis", "Pipelines")),
            ("DataFlows", sheet_count("DataFlows", "DataFlowLineage", "DataFlow_Summary")),
            ("Datasets", sheet_count("Datasets")),
            ("LinkedServices", sheet_count("LinkedServices")),
            ("Triggers", sheet_count("Triggers", "TriggerDetails")),
            ("Integration Runtimes", sheet_count("IntegrationRuntimes", "Integration_Runtime")),

            # New resource types introduced in analyzer v10.x
            ("Credentials", sheet_count("Credentials", "credentials")),
            ("Managed VNets", sheet_count("ManagedVNets", "ManagedVnets", "managed_vnets")),
            ("Managed Private Endpoints", sheet_count("ManagedPrivateEndpoints", "managed_private_endpoints")),
            ("Global Parameters", sheet_count("GlobalParameterUsage", "GlobalParameters", "global_parameters")),
        ]

        for label, count in resource_types:
            if count > 0:
                resources.append(label)
                counts.append(count)

        if not resources:
            st.info("📊 No resource data available")
            return

        # Create treemap
        fig = go.Figure(
            go.Treemap(
                labels=resources,
                parents=[""] * len(resources),
                values=counts,
                textinfo="label+value+percent root",
                marker=dict(colorscale="Viridis", line=dict(width=2, color="white")),
                hovertemplate="<b>%{label}</b><br>Count: %{value}<br>%{percentRoot}<extra></extra>",
            )
        )

        fig.update_layout(
            title={
                "text": "📦 Resources Overview",
                "font": {"size": 20, "color": "#667eea"},
            },
            height=400,
            margin=dict(l=20, r=20, t=60, b=20),
            paper_bgcolor="rgba(0,0,0,0)",
        )

        safe_plotly(fig)

    def render_analysis_info(self):
        """Render analysis information cards"""

        st.markdown("### 📅 Analysis Information")

        col1, col2, col3, col4 = st.columns(4)

        analysis_date = get_summary_metric("Analysis Date", "N/A")
        source_file = get_summary_metric("Source File", "N/A")
        version = get_summary_metric("Analyzer Version", "N/A")
        errors = get_summary_metric("Parse Errors", 0)

        with col1:
            render_info_card("📅 Analysis Date", f"<p>{analysis_date}</p>")

        with col2:
            filename = Path(str(source_file)).name if source_file != "N/A" else "N/A"
            render_info_card("📁 Source File", f"<p title='{source_file}'>{truncate_text(filename, 30)}</p>")

        with col3:
            render_info_card("🔧 Version", f"<p>{truncate_text(str(version), 30)}</p>")

        with col4:
            color = "#43e97b" if errors == 0 else "#f5576c"
            status = "No Errors" if errors == 0 else f"{errors} Errors"
            render_info_card("✅ Status", f"<p style='color: {color}; font-weight: 600;'>{status}</p>", color=color)

    def render_debug_panel(self):
        """Developer debug panel to inspect loaded sheets and key DataFrames"""
        if not st.session_state.get("show_debug_panel", False):
            return

        st.markdown("---")
        st.markdown("### 🐞 Debug Panel (Developer)")

        # Show loaded sheet keys
        excel_data = st.session_state.get("excel_data", {}) or {}
        st.write("Loaded sheet keys:", list(excel_data.keys()))

        # Show sheet_map and hyperlink_map if available
        if "sheet_map" in st.session_state:
            st.write("sheet_map:", st.session_state.get("sheet_map"))
        if "hyperlink_map" in st.session_state:
            st.write("hyperlink_map (sample 20):", dict(list(st.session_state.get("hyperlink_map", {}).items())[:20]))

        # Show small preview of Summary and ActivityCount
        try:
            summary_df = safe_get_dataframe("Summary")
            st.write("Summary (top 20):")
            if summary_df is None or summary_df.empty:
                st.write("(empty)")
            else:
                st.dataframe(summary_df.head(20))
        except Exception as e:
            st.write("Could not preview Summary:", e)

        try:
            act = safe_get_dataframe("ActivityCount")
            st.write("ActivityCount (top 20):")
            if act is None or act.empty:
                st.write("(empty)")
            else:
                # coerce Count if present
                if "Count" in act.columns:
                    act["Count"] = pd.to_numeric(act["Count"], errors="coerce").fillna(0).astype(int)
                st.dataframe(act.head(20))
        except Exception as e:
            st.write("Could not preview ActivityCount:", e)


    # ═══════════════════════════════════════════════════════════════════════
    # NETWORK VISUALIZATION TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_network_tab(self):
        """
        Render network visualization

        FIXED:
        - Safe graph access
        - Proper node filtering
        - Layout options
        - Error handling
        """

        st.markdown("### 🌐 Dependency Network Visualization")
        st.markdown("*Interactive visualization of your data factory dependencies*")

        if st.session_state.dependency_graph is None:
            st.warning("⚠️ No dependency graph available. Please load data first.")
            return

        G = st.session_state.dependency_graph

        if G.number_of_nodes() == 0:
            st.warning("⚠️ Dependency graph is empty. No relationships found.")
            return

        # Controls
        col1, col2, col3 = st.columns(3)

        with col1:
            show_node_types = st.multiselect(
                "🎨 Show Node Types",
                ["Triggers", "Pipelines", "DataFlows", "Datasets"],
                default=["Triggers", "Pipelines", "DataFlows"],
                key="net_node_types",
            )

        with col2:
            layout_type = st.selectbox(
                "📐 Layout Algorithm",
                ["Spring (Force)", "Circular", "Hierarchical", "Shell"],
                index=0,
                key="net_layout",
            )

        with col3:
            show_labels = st.checkbox("Show Labels", value=True, key="net_labels")

        # Filter graph by node types
        filtered_nodes = []
        for node, data in G.nodes(data=True):
            node_type = data.get("type", "unknown")

            if (
                (node_type == "trigger" and "Triggers" in show_node_types)
                or (node_type == "pipeline" and "Pipelines" in show_node_types)
                or (node_type == "dataflow" and "DataFlows" in show_node_types)
                or (node_type == "dataset" and "Datasets" in show_node_types)
            ):
                filtered_nodes.append(node)

        if not filtered_nodes:
            st.warning("⚠️ No nodes match the selected filters")
            return

        # --- Node selection options (allow user to focus the graph) ---
        with st.expander("🔎 Node Selection / Focus (optional)", expanded=False):
            sel_col1, sel_col2 = st.columns([2, 1])

            with sel_col1:
                node_mode = st.radio(
                    "Select nodes by:",
                    ["All (filtered types)", "Select nodes", "Top N by degree", "Search (substring/regex)"],
                    index=0,
                    key="net_node_mode",
                )

            with sel_col2:
                include_neighbors = st.checkbox("Include neighbors (1-hop)", value=False, key="net_include_neighbors")

            selected_nodes = set(filtered_nodes)

            if node_mode == "Select nodes":
                # Show a searchable multiselect of filtered nodes (limit to 1000)
                pick = st.multiselect(
                    "Choose nodes to display",
                    sorted(filtered_nodes),
                    default=[],
                    key="net_node_multiselect",
                )
                if pick:
                    selected_nodes = set(pick)
                else:
                    # If user didn't pick any, keep empty so we can warn later
                    selected_nodes = set()

            elif node_mode == "Top N by degree":
                max_n = min(50, max(5, int(len(filtered_nodes) / 5)))
                n = st.slider("Top N nodes by degree", min_value=3, max_value=max_n, value=min(15, max_n), key="net_topn")
                # compute degrees on filtered nodes
                degs = [(n_, G.degree(n_)) for n_ in filtered_nodes]
                degs_sorted = sorted(degs, key=lambda x: x[1], reverse=True)[:n]
                selected_nodes = set([d[0] for d in degs_sorted])

            elif node_mode == "Search (substring/regex)":
                q = st.text_input("Search nodes (substring or regex)", value="", key="net_search")
                try:
                    if q.strip():
                        pattern = re.compile(q, re.IGNORECASE)
                        matched = [n for n in filtered_nodes if pattern.search(n)]
                    else:
                        matched = []
                except re.error:
                    # treat as simple substring
                    matched = [n for n in filtered_nodes if q.lower() in n.lower()]

                selected_nodes = set(matched)

            # If include_neighbors, expand selection to 1-hop neighbors
            if include_neighbors and selected_nodes:
                neighbors = set()
                for n in list(selected_nodes):
                    try:
                        neighbors.update(set(G.predecessors(n)))
                        neighbors.update(set(G.successors(n)))
                    except Exception:
                        # Graph may not be directed or methods unavailable — try neighbors()
                        try:
                            neighbors.update(set(G.neighbors(n)))
                        except Exception:
                            pass
                selected_nodes.update(neighbors)

            # If user chose All (filtered types), keep selected_nodes as filtered_nodes
            if node_mode == "All (filtered types)":
                final_nodes = set(filtered_nodes)
            else:
                final_nodes = selected_nodes

            if not final_nodes:
                st.warning("⚠️ No nodes selected — adjust selection or switch to 'All (filtered types)'.")
                return

        # Create subgraph from final node set
        H = G.subgraph(sorted(final_nodes))

        if H.number_of_nodes() == 0:
            st.warning("⚠️ Filtered graph is empty")
            return

        # Calculate layout
        try:
            if layout_type.startswith("Spring"):
                pos = nx.spring_layout(
                    H, k=1 / np.sqrt(H.number_of_nodes()), iterations=50, seed=42
                )
            elif layout_type.startswith("Circular"):
                pos = nx.circular_layout(H)
            elif layout_type.startswith("Hierarchical"):
                # Try hierarchical, fallback to spring
                try:
                    pos = nx.kamada_kawai_layout(H)
                except:
                    pos = nx.spring_layout(H, seed=42)
            else:  # Shell
                pos = nx.shell_layout(H)
        except Exception as e:
            st.error(f"Layout calculation error: {e}")
            pos = nx.spring_layout(H, seed=42)

        # Render 2D network
        self.render_2d_network(H, pos, show_labels)

        # Network statistics
        st.markdown("---")
        st.markdown("### 📊 Network Statistics")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("Nodes", H.number_of_nodes())

        with col2:
            st.metric("Edges", H.number_of_edges())

        with col3:
            density = nx.density(H) if H.number_of_nodes() > 0 else 0
            st.metric("Density", f"{density:.3f}")

        with col4:
            # Count node types
            node_types = Counter(
                data.get("type", "unknown") for _, data in H.nodes(data=True)
            )
            st.metric("Node Types", len(node_types))

    def render_2d_network(self, G, pos: dict, show_labels: bool):
        """
        Render 2D network using Plotly

        Args:
            G: NetworkX graph
            pos: Node positions
            show_labels: Whether to show node labels
        """

        # Extract edge coordinates
        edge_x = []
        edge_y = []

        for edge in G.edges():
            x0, y0 = pos[edge[0]]
            x1, y1 = pos[edge[1]]
            edge_x.extend([x0, x1, None])
            edge_y.extend([y0, y1, None])

        # Create edge trace
        edge_trace = go.Scatter(
            x=edge_x,
            y=edge_y,
            mode="lines",
            line=dict(width=1, color="rgba(125, 125, 125, 0.5)"),
            hoverinfo="none",
            showlegend=False,
        )

        # Extract node coordinates and attributes
        node_x = []
        node_y = []
        node_colors = []
        node_text = []
        node_sizes = []

        for node in G.nodes():
            x, y = pos[node]
            node_x.append(x)
            node_y.append(y)

            # Get node data
            node_data = G.nodes[node]
            node_type = node_data.get("type", "unknown")

            # Determine color and size
            if node_type == "trigger":
                color = "#FFD700"
                icon = "🔔"
                size = 25
            elif node_type == "pipeline":
                if node_data.get("is_orphaned"):
                    color = "#FFA07A"
                    icon = "⚠️"
                elif node_data.get("has_trigger"):
                    color = "#90EE90"
                    icon = "✅"
                else:
                    color = "#87CEEB"
                    icon = "📦"
                size = 20
            elif node_type == "dataflow":
                color = "#DDA0DD"
                icon = "🌊"
                size = 20
            elif node_type == "dataset":
                color = "#F0E68C"
                icon = "📊"
                size = 15
            else:
                color = "#D3D3D3"
                icon = "❓"
                size = 15

            node_colors.append(color)
            node_text.append(f"{icon} {node}")

            # Size based on connections
            degree = G.degree(node)
            node_sizes.append(size + degree * 2)

        # Create node trace
        node_trace = go.Scatter(
            x=node_x,
            y=node_y,
            mode="markers+text" if show_labels else "markers",
            marker=dict(
                size=node_sizes, color=node_colors, line=dict(color="white", width=2)
            ),
            text=node_text if show_labels else None,
            textposition="top center",
            textfont=dict(size=10),
            hovertext=node_text,
            hoverinfo="text",
            showlegend=False,
        )

        # Create figure
        fig = go.Figure(data=[edge_trace, node_trace])

        fig.update_layout(
            title={
                "text": f"🌐 Dependency Network ({G.number_of_nodes()} nodes, {G.number_of_edges()} edges)",
                "font": {"size": 20, "color": "#667eea"},
            },
            showlegend=False,
            hovermode="closest",
            margin=dict(b=0, l=0, r=0, t=60),
            xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
            yaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
            plot_bgcolor="rgba(240, 240, 250, 0.3)",
            height=600,
        )

        st.plotly_chart(fig, use_container_width=True)

        # Legend
        st.markdown("---")
        st.markdown("### 📖 Legend")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.markdown(
                '<span class="badge" style="background: #FFD700; color: black;">🔔 Triggers</span>',
                unsafe_allow_html=True,
            )
        with col2:
            st.markdown(
                '<span class="badge" style="background: #90EE90; color: black;">✅ Pipelines (Triggered)</span>',
                unsafe_allow_html=True,
            )
        with col3:
            st.markdown(
                '<span class="badge" style="background: #DDA0DD; color: white;">🌊 DataFlows</span>',
                unsafe_allow_html=True,
            )
        with col4:
            st.markdown(
                '<span class="badge" style="background: #FFA07A; color: white;">⚠️ Orphaned</span>',
                unsafe_allow_html=True,
            )
            # ═══════════════════════════════════════════════════════════════════════

    # IMPACT ANALYSIS TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_impact_analysis_tab(self):
        """
        Render impact analysis with visual hierarchy
        
        FIXED:
        - All HTML properly rendered
        - Pie chart fixed
        - Sankey diagram working
        """
        
        st.markdown("### 🎯 Impact Analysis Dashboard")
        st.markdown("*Understand the blast radius of changes before making them*")
        
        impact_df = safe_get_dataframe('ImpactAnalysis', 'PipelineAnalysis', 'Pipeline_Analysis')
        
        if impact_df.empty:
            st.warning("⚠️ No impact analysis data available")
            return
        
        # Ensure required columns exist
        if 'Pipeline' not in impact_df.columns:
            st.error("❌ Missing 'Pipeline' column in impact data")
            return
        
        # Add Impact column if missing (default to LOW)
        if 'Impact' not in impact_df.columns:
            impact_df['Impact'] = 'LOW'
        
        # ═══════════════════════════════════════════════════════════════════
        # Impact Distribution Overview
        # ═══════════════════════════════════════════════════════════════════
        
        col1, col2 = st.columns([1, 2])
        
        with col1:
            # Impact level counts
            impact_counts = impact_df['Impact'].value_counts()
            
            # ✅ FIX: Create proper data for pie chart
            labels = []
            values = []
            colors_list = []
            
            for impact_level in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
                count = impact_counts.get(impact_level, 0)
                if count > 0:  # Only add non-zero counts
                    labels.append(impact_level)
                    values.append(count)
                    
                    # Assign colors
                    if impact_level == 'CRITICAL':
                        colors_list.append('#FF4444')
                    elif impact_level == 'HIGH':
                        colors_list.append('#FF8800')
                    elif impact_level == 'MEDIUM':
                        colors_list.append('#FFBB33')
                    else:  # LOW
                        colors_list.append('#00C851')
            
            # ✅ FIX: Only create chart if we have data
            if labels and values:
                fig = go.Figure(data=[go.Pie(
                    labels=labels,
                    values=values,
                    hole=0.5,
                    marker=dict(colors=colors_list),
                    textinfo='none',
                    texttemplate='<b>%{label}</b><br>%{value}<br>(%{percent:.1%})',
                    hovertemplate='<b>%{label}</b><br>Count: %{value}<br>%{percent:.1%}<extra></extra>'
                )])
                
                fig.update_layout(
                    title="Impact Distribution",
                    height=300,
                    margin=dict(l=20, r=20, t=40, b=20),
                    showlegend=True,
                    legend=dict(
                        orientation="v",
                        yanchor="middle",
                        y=0.5,
                        xanchor="left",
                        x=1.05
                    )
                )
                
                safe_plotly(fig)
            else:
                st.info("📊 No impact data to visualize")
        
        with col2:
            # Impact level metrics
            st.markdown("#### 📊 Impact Summary")
            
            metric_col1, metric_col2, metric_col3, metric_col4 = st.columns(4)
            
            critical_count = impact_counts.get('CRITICAL', 0)
            high_count = impact_counts.get('HIGH', 0)
            medium_count = impact_counts.get('MEDIUM', 0)
            low_count = impact_counts.get('LOW', 0)
            
            with metric_col1:
                st.markdown(f"""
                <div class="metric-card badge-critical" style="padding: 1rem;">
                    <div class="metric-label">CRITICAL</div>
                    <div class="metric-value" style="font-size: 2em;">{critical_count}</div>
                </div>
                """, unsafe_allow_html=True)
            
            with metric_col2:
                st.markdown(f"""
                <div class="metric-card badge-high" style="padding: 1rem;">
                    <div class="metric-label">HIGH</div>
                    <div class="metric-value" style="font-size: 2em;">{high_count}</div>
                </div>
                """, unsafe_allow_html=True)
            
            with metric_col3:
                st.markdown(f"""
                <div class="metric-card badge-medium" style="padding: 1rem;">
                    <div class="metric-label">MEDIUM</div>
                    <div class="metric-value" style="font-size: 2em;">{medium_count}</div>
                </div>
                """, unsafe_allow_html=True)
            
            with metric_col4:
                st.markdown(f"""
                <div class="metric-card badge-low" style="padding: 1rem;">
                    <div class="metric-label">LOW</div>
                    <div class="metric-value" style="font-size: 2em;">{low_count}</div>
                </div>
                """, unsafe_allow_html=True)
        
        st.markdown("---")
        
        # ═══════════════════════════════════════════════════════════════════
        # Filter Controls
        # ═══════════════════════════════════════════════════════════════════
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            impact_filter = st.multiselect(
                "🎯 Filter by Impact",
                ["CRITICAL", "HIGH", "MEDIUM", "LOW"],
                default=["CRITICAL", "HIGH"],
                key="impact_filter_main"
            )
        
        with col2:
            orphan_filter = st.selectbox(
                "⚠️ Show Orphaned",
                ["All", "Only Orphaned", "Exclude Orphaned"],
                index=0,
                key="impact_orphan_filter"
            )
        
        with col3:
            sort_by = st.selectbox(
                "📊 Sort By",
                ["Impact (Critical First)", "Blast Radius (High to Low)", "Name (A-Z)"],
                index=0,
                key="impact_sort"
            )
        
        # Apply filters
        filtered_df = impact_df.copy()
        
        if impact_filter:
            filtered_df = filtered_df[filtered_df['Impact'].isin(impact_filter)]
        
        if 'IsOrphaned' in filtered_df.columns:
            if orphan_filter == "Only Orphaned":
                filtered_df = filtered_df[filtered_df['IsOrphaned'] == 'Yes']
            elif orphan_filter == "Exclude Orphaned":
                filtered_df = filtered_df[filtered_df['IsOrphaned'] != 'Yes']
        
        # Sort
        if sort_by == "Impact (Critical First)":
            impact_order = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3}
            filtered_df['_sort'] = filtered_df['Impact'].map(impact_order).fillna(999)
            filtered_df = filtered_df.sort_values('_sort').drop('_sort', axis=1)
        elif sort_by == "Blast Radius (High to Low)":
            if 'BlastRadius' in filtered_df.columns:
                filtered_df = filtered_df.sort_values('BlastRadius', ascending=False)
        else:  # Name A-Z
            filtered_df = filtered_df.sort_values('Pipeline')
        
        if filtered_df.empty:
            st.info("📭 No pipelines match the selected filters")
            return
        
        st.markdown(f"### 📋 Pipeline Impact Details ({len(filtered_df)} pipelines)")
        
        # ═══════════════════════════════════════════════════════════════════
        # Pipeline Selection for Detailed View
        # ═══════════════════════════════════════════════════════════════════
        
        selected_pipeline = st.selectbox(
            "🔍 Select pipeline for detailed analysis",
            filtered_df['Pipeline'].tolist(),
            key="impact_selected_pipeline"
        )
        
        if selected_pipeline:
            pipeline_data = filtered_df[filtered_df['Pipeline'] == selected_pipeline].iloc[0]
            
            # Detailed view
            col1, col2 = st.columns([1, 2])
            
            with col1:
                # Pipeline info card
                impact = pipeline_data.get('Impact', 'LOW')
                blast_radius = pipeline_data.get('BlastRadius', 0)
                is_orphaned = pipeline_data.get('IsOrphaned', 'No')
                
                impact_color = {
                    'CRITICAL': '#FF4444',
                    'HIGH': '#FF8800',
                    'MEDIUM': '#FFBB33',
                    'LOW': '#00C851'
                }.get(impact, '#999999')
                
                # ✅ FIX: Properly render HTML using helper
                status_html = (
                    "<span style='color: #FF4444;'>⚠️ Orphaned</span>"
                    if is_orphaned == 'Yes'
                    else "<span style='color: #00C851;'>✅ Active</span>"
                )

                body = (
                    f"<h3 style='color: {impact_color}; margin-bottom: 8px;'>{selected_pipeline}</h3>"
                    f"<div style='margin: 8px 0;'><strong>Impact Level:</strong><br>"
                    f"<span class='badge' style='background: {impact_color}; color: white; font-size: 1.05em;'>{impact}</span></div>"
                    f"<div style='margin: 8px 0;'><strong>Blast Radius:</strong> {blast_radius} resources</div>"
                    f"<div style='margin: 8px 0;'><strong>Status:</strong> {status_html}</div>"
                )

                render_info_card(selected_pipeline, body, color=impact_color)
                
                # Metrics
                st.markdown("#### 📊 Dependency Counts")
                
                trigger_count = pipeline_data.get('DirectUpstreamTriggerCount', 0)
                upstream_count = pipeline_data.get('DirectUpstreamPipelineCount', 0)
                downstream_count = pipeline_data.get('DirectDownstreamPipelineCount', 0)
                dataflow_count = pipeline_data.get('DataFlowCount', 0)
                
                st.metric("⏰ Triggers", int(trigger_count) if pd.notna(trigger_count) else 0)
                st.metric("⬆️ Upstream Pipelines", int(upstream_count) if pd.notna(upstream_count) else 0)
                st.metric("⬇️ Downstream Pipelines", int(downstream_count) if pd.notna(downstream_count) else 0)
                st.metric("🌊 DataFlows", int(dataflow_count) if pd.notna(dataflow_count) else 0)
            
            with col2:
                # Dependency visualization
                st.markdown("#### 🌐 Dependency Map")
                
                self.render_pipeline_dependency_sankey(pipeline_data)
        
        st.markdown("---")
        
        # ═══════════════════════════════════════════════════════════════════
        # Full Table View
        # ═══════════════════════════════════════════════════════════════════
        
        with st.expander("📊 View All Pipeline Details"):
            # Select columns to display
            display_columns = ['Pipeline', 'Impact', 'BlastRadius']
            
            optional_columns = [
                'DirectUpstreamTriggerCount',
                'DirectUpstreamPipelineCount', 
                'DirectDownstreamPipelineCount',
                'DataFlowCount',
                'IsOrphaned'
            ]
            
            for col in optional_columns:
                if col in filtered_df.columns:
                    display_columns.append(col)
            
            display_df = filtered_df[display_columns].copy()
            
            # ✅ FIX: Better styling with proper background colors
            def style_impact_row(row):
                """Style entire row based on impact"""
                impact = row['Impact']
                
                if impact == 'CRITICAL':
                    return ['background-color: #ffebee'] * len(row)
                elif impact == 'HIGH':
                    return ['background-color: #fff3e0'] * len(row)
                elif impact == 'MEDIUM':
                    return ['background-color: #fffde7'] * len(row)
                elif impact == 'LOW':
                    return ['background-color: #e8f5e9'] * len(row)
                return [''] * len(row)
            
            # Apply styling
            styled_df = display_df.style.apply(style_impact_row, axis=1)
            
            st.dataframe(styled_df, use_container_width=True, height=400)
            
            # Export button
            csv_bytes = to_csv_bytes(display_df)
            st.download_button(
                label="📥 Download Impact Analysis CSV",
                data=csv_bytes,
                file_name="impact_analysis.csv",
                mime="text/csv",
                key="download_impact_csv",
            )

    def render_pipeline_dependency_sankey(self, pipeline_data):
        """
        Render Sankey diagram for pipeline dependencies
        
        FIXED:
        - Proper None/empty handling
        - Better visualization
        - Fallback messages
        """
        
        # Extract dependencies
        pipeline_name = pipeline_data.get('Pipeline', 'Unknown')
        
        # ✅ FIX: Safe extraction with proper None/empty handling
        def safe_split(value):
            """Split string safely, return empty list if None/empty"""
            if pd.isna(value):
                return []
            
            value_str = str(value).strip()
            
            if not value_str or value_str in ['', 'None', 'nan', 'NaN']:
                return []
            
            return [x.strip() for x in value_str.split(',') if x.strip() and x.strip() not in ['None', 'nan', 'NaN', '']]
        
        # Extract all dependency types
        triggers = safe_split(pipeline_data.get('DirectUpstreamTriggers', ''))
        upstream = safe_split(pipeline_data.get('DirectUpstreamPipelines', ''))
        downstream = safe_split(pipeline_data.get('DirectDownstreamPipelines', ''))
        dataflows = safe_split(pipeline_data.get('UsedDataFlows', ''))
        
        # ✅ FIX: Check if we have ANY dependencies
        total_deps = len(triggers) + len(upstream) + len(downstream) + len(dataflows)
        
        if total_deps == 0:
            st.info("📭 No dependencies to visualize for this pipeline")
            
            # Show details
            with st.expander("ℹ️ Why is this empty?"):
                st.markdown(f"""
                **Pipeline:** `{pipeline_name}`
                
                **Dependency Counts:**
                - ⏰ Upstream Triggers: {len(triggers)}
                - ⬆️ Upstream Pipelines: {len(upstream)}
                - ⬇️ Downstream Pipelines: {len(downstream)}
                - 🌊 DataFlows Used: {len(dataflows)}
                
                **Possible reasons:**
                - Pipeline is orphaned (no trigger)
                - Pipeline is a leaf node (no downstream)
                - Pipeline doesn't use DataFlows
                
                **Check Impact Analysis tab for full details.**
                """)
            return
        
        # Build Sankey data
        labels = []
        sources = []
        targets = []
        values = []
        colors = []
        
        # Node index mapping
        node_index = {}
        current_idx = 0
        
        # Add pipeline as central node
        labels.append(pipeline_name)
        node_index[pipeline_name] = current_idx
        current_idx += 1
        
        # Add triggers → pipeline
        for trigger in triggers[:5]:  # Limit to 5 for clarity
            if trigger not in node_index:
                labels.append(trigger)
                node_index[trigger] = current_idx
                current_idx += 1
            
            sources.append(node_index[trigger])
            targets.append(node_index[pipeline_name])
            values.append(3)
            colors.append('rgba(255, 215, 0, 0.5)')  # Gold
        
        # Add upstream pipelines → pipeline
        for pipe in upstream[:5]:
            if pipe not in node_index:
                labels.append(pipe)
                node_index[pipe] = current_idx
                current_idx += 1
            
            sources.append(node_index[pipe])
            targets.append(node_index[pipeline_name])
            values.append(2)
            colors.append('rgba(135, 206, 235, 0.5)')  # Sky blue
        
        # Add pipeline → downstream pipelines
        for pipe in downstream[:5]:
            if pipe not in node_index:
                labels.append(pipe)
                node_index[pipe] = current_idx
                current_idx += 1
            
            sources.append(node_index[pipeline_name])
            targets.append(node_index[pipe])
            values.append(2)
            colors.append('rgba(144, 238, 144, 0.5)')  # Light green
        
        # Add pipeline → dataflows
        for df in dataflows[:5]:
            if df not in node_index:
                labels.append(df)
                node_index[df] = current_idx
                current_idx += 1
            
            sources.append(node_index[pipeline_name])
            targets.append(node_index[df])
            values.append(1)
            colors.append('rgba(221, 160, 221, 0.5)')  # Plum
        
        # ✅ FIX: Final validation
        if not sources or not targets:
            st.warning("⚠️ Could not build dependency graph - no valid links found")
            return
        
        # Create Sankey diagram
        try:
            fig = go.Figure(data=[go.Sankey(
                node=dict(
                    pad=15,
                    thickness=20,
                    line=dict(color="white", width=2),
                    label=labels,
                    color=[
                        '#90EE90' if l == pipeline_name else  # Light green for main pipeline
                        '#FFD700' if l in triggers else       # Gold for triggers
                        '#DDA0DD' if l in dataflows else      # Plum for dataflows
                        '#87CEEB'                             # Sky blue for pipelines
                        for l in labels
                    ],
                    hovertemplate='<b>%{label}</b><extra></extra>'
                ),
                link=dict(
                    source=sources,
                    target=targets,
                    value=values,
                    color=colors,
                    hovertemplate='%{source.label} → %{target.label}<extra></extra>'
                )
            )])
            
            fig.update_layout(
                title={
                    'text': f"Dependencies: {pipeline_name}",
                    'font': {'size': 16}
                },
                height=400,
                margin=dict(l=20, r=20, t=50, b=20),
                font=dict(size=10)
            )
            
            safe_plotly(fig)
            
            # Legend
            st.markdown("""
            **Legend:** 
            🟡 Triggers · 🔵 Upstream Pipelines · 🟢 Downstream Pipelines · 🟣 DataFlows
            """)
            
        except Exception as e:
            st.error(f"❌ Could not render Sankey diagram: {e}")
            
            with st.expander("🔍 Debug Info"):
                st.write("Labels:", labels)
                st.write("Sources:", sources)
                st.write("Targets:", targets)
                st.write("Values:", values)

    # ═══════════════════════════════════════════════════════════════════════
    # ORPHANED RESOURCES TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_orphaned_resources_tab(self):
        """
        Render orphaned resources analysis

        FIXED:
        - Multiple orphaned resource types
        - Recommendations
        - Cleanup suggestions
        """

        st.markdown("### ⚠️ Orphaned Resources Analysis")
        st.markdown("*Identify unused resources that can be cleaned up*")

        # ═══════════════════════════════════════════════════════════════════
        # Summary Cards
        # ═══════════════════════════════════════════════════════════════════

        orphaned_pipelines = safe_get_dataframe(
            "OrphanedPipelines", "Orphaned_Pipelines"
        )
        orphaned_datasets = safe_get_dataframe("OrphanedDatasets", "Orphaned_Datasets")
        orphaned_linkedservices = safe_get_dataframe(
            "OrphanedLinkedServices", "Orphaned_LinkedServices"
        )
        orphaned_triggers = safe_get_dataframe("OrphanedTriggers", "Orphaned_Triggers")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            count = len(orphaned_pipelines)
            st.markdown(
                f"""
            <div class="metric-card gradient-fire">
                <div style="font-size: 2em;">📦</div>
                <div class="metric-label">Orphaned Pipelines</div>
                <div class="metric-value">{count}</div>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col2:
            count = len(orphaned_datasets)
            st.markdown(
                f"""
            <div class="metric-card gradient-orange">
                <div style="font-size: 2em;">📊</div>
                <div class="metric-label">Orphaned Datasets</div>
                <div class="metric-value">{count}</div>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col3:
            count = len(orphaned_linkedservices)
            st.markdown(
                f"""
            <div class="metric-card gradient-pink">
                <div style="font-size: 2em;">🔗</div>
                <div class="metric-label">Orphaned Services</div>
                <div class="metric-value">{count}</div>
            </div>
            """,
                unsafe_allow_html=True,
            )

        with col4:
            count = len(orphaned_triggers)
            st.markdown(
                f"""
            <div class="metric-card gradient-teal">
                <div style="font-size: 2em;">⏰</div>
                <div class="metric-label">Broken/Inactive Triggers</div>
                <div class="metric-value">{count}</div>
            </div>
            """,
                unsafe_allow_html=True,
            )

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Orphaned Resources Breakdown
        # ═══════════════════════════════════════════════════════════════════

        tabs = st.tabs(
            ["📦 Pipelines", "📊 Datasets", "🔗 Linked Services", "⏰ Triggers"]
        )

        # Tab 1: Orphaned Pipelines
        with tabs[0]:
            if orphaned_pipelines.empty:
                st.success("✅ No orphaned pipelines found!")
            else:
                st.markdown(f"#### 📦 Orphaned Pipelines ({len(orphaned_pipelines)})")
                st.markdown("*Pipelines with no triggers or callers*")

                # Display table
                if "Pipeline" in orphaned_pipelines.columns:
                    display_cols = ["Pipeline"]
                    if "Reason" in orphaned_pipelines.columns:
                        display_cols.append("Reason")
                    if "Recommendation" in orphaned_pipelines.columns:
                        display_cols.append("Recommendation")

                    st.dataframe(
                        orphaned_pipelines[display_cols],
                        use_container_width=True,
                        height=400,
                    )

                    # Export button
                    csv_bytes = to_csv_bytes(orphaned_pipelines)
                    st.download_button(
                        label="📥 Download Orphaned Pipelines CSV",
                        data=csv_bytes,
                        file_name="orphaned_pipelines.csv",
                        mime="text/csv",
                        key="download_orphaned_pipelines",
                    )
                else:
                    st.dataframe(orphaned_pipelines, use_container_width=True)

        # Tab 2: Orphaned Datasets
        with tabs[1]:
            if orphaned_datasets.empty:
                st.success("✅ No orphaned datasets found!")
            else:
                st.markdown(f"#### 📊 Orphaned Datasets ({len(orphaned_datasets)})")
                st.markdown("*Datasets not used by any pipeline or dataflow*")

                if "Dataset" in orphaned_datasets.columns:
                    display_cols = ["Dataset"]
                    if "Reason" in orphaned_datasets.columns:
                        display_cols.append("Reason")
                    if "Recommendation" in orphaned_datasets.columns:
                        display_cols.append("Recommendation")

                    st.dataframe(
                        orphaned_datasets[display_cols],
                        use_container_width=True,
                        height=400,
                    )

                    csv_bytes = to_csv_bytes(orphaned_datasets)
                    st.download_button(
                        label="📥 Download Orphaned Datasets CSV",
                        data=csv_bytes,
                        file_name="orphaned_datasets.csv",
                        mime="text/csv",
                        key="download_orphaned_datasets",
                    )
                else:
                    st.dataframe(orphaned_datasets, use_container_width=True)

        # Tab 3: Orphaned Linked Services
        with tabs[2]:
            if orphaned_linkedservices.empty:
                st.success("✅ No orphaned linked services found!")
            else:
                st.markdown(
                    f"#### 🔗 Orphaned Linked Services ({len(orphaned_linkedservices)})"
                )
                st.markdown("*Linked services not used by any dataset or dataflow*")

                if "LinkedService" in orphaned_linkedservices.columns:
                    display_cols = ["LinkedService"]
                    if "Reason" in orphaned_linkedservices.columns:
                        display_cols.append("Reason")
                    if "Recommendation" in orphaned_linkedservices.columns:
                        display_cols.append("Recommendation")

                    st.dataframe(
                        orphaned_linkedservices[display_cols],
                        use_container_width=True,
                        height=400,
                    )

                    csv_bytes = to_csv_bytes(orphaned_linkedservices)
                    st.download_button(
                        label="📥 Download Orphaned Services CSV",
                        data=csv_bytes,
                        file_name="orphaned_linkedservices.csv",
                        mime="text/csv",
                        key="download_orphaned_services",
                    )
                else:
                    st.dataframe(orphaned_linkedservices, use_container_width=True)

        # Tab 4: Orphaned/Broken Triggers
        with tabs[3]:
            if orphaned_triggers.empty:
                st.success("✅ No broken or inactive triggers found!")
            else:
                st.markdown(
                    f"#### ⏰ Broken/Inactive Triggers ({len(orphaned_triggers)})"
                )
                st.markdown("*Triggers that are stopped or misconfigured*")

                # Group by type if available
                if "Type" in orphaned_triggers.columns:
                    type_counts = orphaned_triggers["Type"].value_counts()

                    col1, col2, col3 = st.columns(3)

                    with col1:
                        st.metric("Inactive (Stopped)", type_counts.get("Inactive", 0))
                    with col2:
                        st.metric(
                            "Broken References", type_counts.get("BrokenReference", 0)
                        )
                    with col3:
                        st.metric("Misconfigured", type_counts.get("Misconfigured", 0))

                    st.markdown("---")

                display_cols = []
                for col in [
                    "Trigger",
                    "Pipeline",
                    "State",
                    "Reason",
                    "Type",
                    "Recommendation",
                ]:
                    if col in orphaned_triggers.columns:
                        display_cols.append(col)

                if display_cols:
                    st.dataframe(
                        orphaned_triggers[display_cols],
                        use_container_width=True,
                        height=400,
                    )
                else:
                    st.dataframe(orphaned_triggers, use_container_width=True)

                csv_bytes = to_csv_bytes(orphaned_triggers)
                st.download_button(
                    label="📥 Download Trigger Issues CSV",
                    data=csv_bytes,
                    file_name="orphaned_triggers.csv",
                    mime="text/csv",
                    key="download_orphaned_triggers",
                )

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Cleanup Recommendations
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("### 💡 Cleanup Recommendations")

        total_orphaned = (
            len(orphaned_pipelines)
            + len(orphaned_datasets)
            + len(orphaned_linkedservices)
            + len(orphaned_triggers)
        )

        if total_orphaned == 0:
            st.success(
                "🎉 Excellent! No orphaned resources found. Your factory is well-maintained!"
            )
        else:
            body = (
                f"<p>Found <strong>{total_orphaned}</strong> orphaned or broken resources.</p>"
                "<h4 style='margin-top:12px;'>Recommended Steps:</h4>"
                "<ol>"
                "<li><strong>Review orphaned pipelines</strong> - Verify they're truly unused before deletion</li>"
                "<li><strong>Check broken trigger references</strong> - Fix or remove broken triggers</li>"
                "<li><strong>Clean up datasets</strong> - Remove datasets not used by any pipeline</li>"
                "<li><strong>Archive linked services</strong> - Keep for future use or remove if obsolete</li>"
                "<li><strong>Document before deletion</strong> - Export the lists above for records</li>"
                "</ol>"
                "<p style='margin-top: 12px; padding: 10px; background: #fff3cd; border-radius: 5px;'>"
                "💡 <strong>Tip:</strong> Use the download buttons above to export lists before cleanup."
                " Start with pipelines that have LOW impact first."
                "</p>"
            )
            render_info_card("⚠️ Action Required", body, color="#FF8800")

    # ═══════════════════════════════════════════════════════════════════════
    # STATISTICS TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_statistics_tab(self):
        """
        Render statistics dashboard

        FIXED:
        - Multiple chart types
        - Activity distribution
        - Resource usage
        - Trend analysis
        """

        st.markdown("### 📊 Statistics & Analytics Dashboard")

        # Activity statistics
        activity_df = safe_get_dataframe("ActivityCount")

        if not activity_df.empty:
            st.markdown("#### ⚡ Activity Type Distribution")

            # Remove total row
            activity_df = activity_df[
                ~activity_df["ActivityType"].str.contains("TOTAL", na=False)
            ]

            # Ensure Count column is numeric for charts
            if "Count" in activity_df.columns:
                activity_df["Count"] = pd.to_numeric(
                    activity_df["Count"], errors="coerce"
                ).fillna(0).astype(int)

            col1, col2 = st.columns(2)

            with col1:
                # Horizontal bar chart
                fig = go.Figure(
                    go.Bar(
                        y=activity_df["ActivityType"].head(10),
                        x=activity_df["Count"].head(10),
                        orientation="h",
                        marker=dict(
                            color=activity_df["Count"].head(10),
                            colorscale="Viridis",
                            showscale=True,
                        ),
                        text=activity_df["Count"].head(10),
                        textposition="auto",
                        hovertemplate="<b>%{y}</b><br>Count: %{x}<extra></extra>",
                    )
                )

                fig.update_layout(
                    title="Top 10 Activity Types",
                    xaxis_title="Count",
                    yaxis_title="Activity Type",
                    height=400,
                    margin=dict(l=20, r=20, t=60, b=20),
                )

                safe_plotly(fig, df=activity_df, required_columns=["ActivityType", "Count"], info_message="📊 No activity data to display")

            with col2:
                # Pie chart (ensure percentages display correctly)
                # Prepare pie data (group, coerce numeric, drop zeros)
                labels_slice, values_slice = prepare_pie_data(activity_df, "ActivityType", "Count", top_n=8)

                if not labels_slice:
                    st.info("📊 No activity breakdown to display")
                else:
                    fig = go.Figure(
                        data=[
                            go.Pie(
                                labels=labels_slice,
                                values=values_slice,
                                hole=0.3,
                                marker=dict(colors=px.colors.qualitative.Pastel),
                                textinfo="none",
                                texttemplate="%{label}<br>%{percent:.1%} (%{value})",
                                insidetextorientation="radial",
                                hovertemplate="<b>%{label}</b><br>Count: %{value}<br>%{percent:.1%}<extra></extra>",
                            )
                        ]
                    )

                fig.update_layout(
                    title="Activity Type Breakdown",
                    height=400,
                    margin=dict(l=20, r=20, t=60, b=20),
                )

                safe_plotly(fig, df=activity_df, required_columns=["ActivityType", "Count"], info_message="📊 No activity data to display")

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Resource Usage Statistics
        # ═══════════════════════════════════════════════════════════════════

        dataset_usage = safe_get_dataframe(
            "DatasetUsage", "Dataset_Usage", "Datasetusage", "datasetusage"
        )

        if not dataset_usage.empty:
            st.markdown("#### 📊 Dataset Usage Statistics")

            # Top used datasets
            if "UsageCount" in dataset_usage.columns:
                top_datasets = dataset_usage.nlargest(10, "UsageCount")

                fig = go.Figure(
                    go.Bar(
                        x=top_datasets["Dataset"],
                        y=top_datasets["UsageCount"],
                        marker=dict(
                            color=top_datasets["UsageCount"],
                            colorscale="Blues",
                            showscale=True,
                        ),
                        text=top_datasets["UsageCount"],
                        textposition="auto",
                        hovertemplate="<b>%{x}</b><br>Usage: %{y}<extra></extra>",
                    )
                )

                fig.update_layout(
                    title="Top 10 Most Used Datasets",
                    xaxis_title="Dataset",
                    yaxis_title="Usage Count",
                    height=400,
                    margin=dict(l=20, r=20, t=60, b=20),
                    xaxis={"tickangle": -45},
                )

                st.plotly_chart(fig, use_container_width=True)

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Transformation Usage
        # ═══════════════════════════════════════════════════════════════════

        trans_usage = safe_get_dataframe(
            "TransformationUsage",
            "Transformation_Usage",
            "Transformationusage",
            "transformationusage",
        )

        if not trans_usage.empty:
            st.markdown("#### 🔄 DataFlow Transformation Usage")

            col1, col2 = st.columns(2)

            with col1:
                # Bar chart
                fig = go.Figure(
                    go.Bar(
                        x=trans_usage["TransformationType"],
                        y=trans_usage["UsageCount"],
                        marker=dict(
                            color=trans_usage["UsageCount"],
                            colorscale="Purples",
                            showscale=False,
                        ),
                        text=trans_usage["UsageCount"],
                        textposition="auto",
                    )
                )

                fig.update_layout(
                    title="Transformation Types",
                    xaxis_title="Type",
                    yaxis_title="Count",
                    height=350,
                    xaxis={"tickangle": -45},
                )

                st.plotly_chart(fig, use_container_width=True)

            with col2:
                # Table view
                st.dataframe(
                    trans_usage[["TransformationType", "UsageCount", "Percentage"]],
                    use_container_width=True,
                    height=350,
                )

    # ═══════════════════════════════════════════════════════════════════════
    # DATAFLOW ANALYSIS TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_dataflow_tab(self):
        """
        Render DataFlow analysis

        FIXED:
        - DataFlow lineage visualization
        - Transformation analysis
        - Source/Sink tracking
        """

        st.markdown("### 🌊 DataFlow Analysis Dashboard")

        dataflow_df = safe_get_dataframe("DataFlows", "DataFlow_Summary")
        lineage_df = safe_get_dataframe("DataFlowLineage", "DataFlow_Lineage")
        trans_df = safe_get_dataframe(
            "DataFlowTransformations", "DataFlow_Transformations"
        )

        if dataflow_df.empty:
            st.info("📊 No DataFlow data available")
            return

        # ═══════════════════════════════════════════════════════════════════
        # DataFlow Overview
        # ═══════════════════════════════════════════════════════════════════

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("Total DataFlows", len(dataflow_df))

        with col2:
            total_sources = (
                dataflow_df["Sources"].sum() if "Sources" in dataflow_df.columns else 0
            )
            st.metric("Total Sources", int(total_sources))

        with col3:
            total_sinks = (
                dataflow_df["Sinks"].sum() if "Sinks" in dataflow_df.columns else 0
            )
            st.metric("Total Sinks", int(total_sinks))

        with col4:
            total_trans = (
                dataflow_df["Transformations"].sum()
                if "Transformations" in dataflow_df.columns
                else 0
            )
            st.metric("Total Transformations", int(total_trans))

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # DataFlow List
        # ═══════════════════════════════════════════════════════════════════

        if "DataFlow" in dataflow_df.columns:
            selected_dataflow = st.selectbox(
                "🔍 Select DataFlow for details",
                dataflow_df["DataFlow"].tolist(),
                key="dataflow_selector",
            )

            if selected_dataflow:
                df_data = dataflow_df[
                    dataflow_df["DataFlow"] == selected_dataflow
                ].iloc[0]

                # DataFlow details
                col1, col2 = st.columns([1, 2])

                with col1:
                    body = (
                        f"<h3 style='color: #667eea; margin-bottom:8px;'>{selected_dataflow}</h3>"
                        f"<div style='margin: 8px 0;'><strong>Type:</strong> {df_data.get('Type', 'MappingDataFlow')}</div>"
                        f"<div style='margin: 8px 0;'><strong>Sources:</strong> {df_data.get('Sources', 0)}</div>"
                        f"<div style='margin: 8px 0;'><strong>Sinks:</strong> {df_data.get('Sinks', 0)}</div>"
                        f"<div style='margin: 8px 0;'><strong>Transformations:</strong> {df_data.get('Transformations', 0)}</div>"
                    )
                    render_info_card(selected_dataflow, body)

                with col2:
                    # Show lineage for this dataflow
                    df_lineage = (
                        lineage_df[lineage_df["DataFlow"] == selected_dataflow]
                        if not lineage_df.empty and "DataFlow" in lineage_df.columns
                        else pd.DataFrame()
                    )

                    if not df_lineage.empty:
                        st.markdown("#### 🔄 Data Lineage")

                        # Display as table
                        display_cols = []
                        for col in [
                            "SourceName",
                            "SourceTable",
                            "SinkName",
                            "SinkTable",
                            "TransformationTypes",
                        ]:
                            if col in df_lineage.columns:
                                display_cols.append(col)

                        if display_cols:
                            st.dataframe(
                                df_lineage[display_cols], use_container_width=True
                            )
                    else:
                        st.info("No lineage data available for this DataFlow")
                        # ═══════════════════════════════════════════════════════════════════════

    # DATA LINEAGE TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_lineage_tab(self):
        """
        Render data lineage visualization

        FIXED:
        - Source to Sink flow visualization
        - Interactive Sankey diagram
        - Filterable lineage table
        """

        st.markdown("### 📈 Data Lineage Analysis")
        st.markdown("*Track data flow from source to sink across your factory*")

        lineage_df = safe_get_dataframe("DataLineage", "Data_Lineage")

        if lineage_df.empty:
            st.info("📊 No data lineage information available")
            return

        # ═══════════════════════════════════════════════════════════════════
        # Lineage Overview
        # ═══════════════════════════════════════════════════════════════════

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("Total Lineage Records", len(lineage_df))

        with col2:
            unique_sources = (
                lineage_df["Source"].nunique() if "Source" in lineage_df.columns else 0
            )
            st.metric("Unique Sources", unique_sources)

        with col3:
            unique_sinks = (
                lineage_df["Sink"].nunique() if "Sink" in lineage_df.columns else 0
            )
            st.metric("Unique Sinks", unique_sinks)

        with col4:
            copy_count = (
                len(lineage_df[lineage_df["Type"] == "Copy"])
                if "Type" in lineage_df.columns
                else 0
            )
            st.metric("Copy Activities", copy_count)

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Filters
        # ═══════════════════════════════════════════════════════════════════

        col1, col2, col3 = st.columns(3)

        with col1:
            if "Pipeline" in lineage_df.columns:
                pipelines = ["All"] + sorted(lineage_df["Pipeline"].unique().tolist())
                pipeline_filter = st.selectbox(
                    "🔍 Filter by Pipeline", pipelines, key="lineage_pipeline_filter"
                )

        with col2:
            if "Type" in lineage_df.columns:
                types = ["All"] + sorted(lineage_df["Type"].unique().tolist())
                type_filter = st.selectbox(
                    "🎯 Filter by Type", types, key="lineage_type_filter"
                )

        with col3:
            search_term = st.text_input(
                "🔍 Search Source/Sink", "", key="lineage_search"
            )

        # Apply filters
        filtered_df = lineage_df.copy()

        if pipeline_filter != "All" and "Pipeline" in filtered_df.columns:
            filtered_df = filtered_df[filtered_df["Pipeline"] == pipeline_filter]

        if type_filter != "All" and "Type" in filtered_df.columns:
            filtered_df = filtered_df[filtered_df["Type"] == type_filter]

        if search_term:
            if "Source" in filtered_df.columns and "Sink" in filtered_df.columns:
                mask = filtered_df["Source"].str.contains(
                    search_term, case=False, na=False
                ) | filtered_df["Sink"].str.contains(search_term, case=False, na=False)
                filtered_df = filtered_df[mask]

        if filtered_df.empty:
            st.info("📭 No lineage records match the selected filters")
            return

        st.markdown(f"### 📊 Lineage Flow ({len(filtered_df)} records)")

        # ═══════════════════════════════════════════════════════════════════
        # Sankey Diagram
        # ═══════════════════════════════════════════════════════════════════

        if len(filtered_df) > 0 and len(filtered_df) <= 100:  # Limit for performance
            st.markdown("#### 🌊 Data Flow Visualization")

            self.render_lineage_sankey(filtered_df)
        elif len(filtered_df) > 100:
            st.warning(
                f"⚠️ Too many records ({len(filtered_df)}) for visualization. Showing table only. Apply filters to reduce dataset."
            )

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Lineage Table
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("#### 📋 Detailed Lineage Table")

        # Select columns to display
        display_cols = []
        for col in [
            "Pipeline",
            "Activity",
            "Type",
            "Source",
            "SourceTable",
            "Sink",
            "SinkTable",
            "Transformation",
        ]:
            if col in filtered_df.columns:
                display_cols.append(col)

        if display_cols:
            st.dataframe(
                filtered_df[display_cols], use_container_width=True, height=400
            )
        else:
            st.dataframe(filtered_df, use_container_width=True, height=400)

        # Export button
        csv_bytes = to_csv_bytes(filtered_df)
        st.download_button(
            label="📥 Download Lineage Data (CSV)",
            data=csv_bytes,
            file_name="data_lineage.csv",
            mime="text/csv",
            key="download_lineage",
        )

    def render_lineage_sankey(self, lineage_df: pd.DataFrame):
        """
        Render Sankey diagram for data lineage

        Args:
            lineage_df: Filtered lineage DataFrame
        """

        # Build Sankey data
        labels = []
        sources = []
        targets = []
        values = []
        colors = []

        node_index = {}
        current_idx = 0

        # Process each lineage record (limit to 50 for performance)
        for _, row in lineage_df.head(50).iterrows():
            source = row.get("Source", "")
            sink = row.get("Sink", "")

            if not source or not sink:
                continue

            # Add source node
            if source not in node_index:
                labels.append(source)
                node_index[source] = current_idx
                current_idx += 1

            # Add sink node
            if sink not in node_index:
                labels.append(sink)
                node_index[sink] = current_idx
                current_idx += 1

            # Add link
            sources.append(node_index[source])
            targets.append(node_index[sink])
            values.append(1)

            # Color by type
            flow_type = row.get("Type", "Unknown")
            if flow_type == "Copy":
                colors.append("rgba(102, 126, 234, 0.4)")
            elif flow_type == "DataFlow":
                colors.append("rgba(221, 160, 221, 0.4)")
            else:
                colors.append("rgba(135, 206, 235, 0.4)")

        if not sources:
            st.info("📭 No data to visualize")
            return

        # Create Sankey diagram
        fig = go.Figure(
            data=[
                go.Sankey(
                    node=dict(
                        pad=15,
                        thickness=20,
                        line=dict(color="white", width=2),
                        label=labels,
                        color=[
                            "#4facfe" if i % 2 == 0 else "#f093fb"
                            for i in range(len(labels))
                        ],
                    ),
                    link=dict(
                        source=sources, target=targets, value=values, color=colors
                    ),
                )
            ]
        )

        fig.update_layout(
            title="Data Flow: Source → Sink",
            height=500,
            margin=dict(l=20, r=20, t=40, b=20),
            font=dict(size=10),
        )

        st.plotly_chart(fig, use_container_width=True)

    # ═══════════════════════════════════════════════════════════════════════
    # DATA EXPLORER TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_explorer_tab(self):
        """
        Render data explorer for raw data browsing

        FIXED:
        - All sheets accessible
        - Search and filter
        - Export functionality
        """

        st.markdown("### 🔍 Data Explorer")
        st.markdown("*Browse and export raw analysis data*")

        if not st.session_state.excel_data:
            st.warning("⚠️ No data loaded")
            return

        # ═══════════════════════════════════════════════════════════════════
        # Sheet Selection
        # ═══════════════════════════════════════════════════════════════════

        sheet_names = list(st.session_state.excel_data.keys())

        if not sheet_names:
            st.warning("⚠️ No sheets available")
            return

        # Group sheets by category
        core_sheets = [
            s
            for s in sheet_names
            if any(
                x in s
                for x in [
                    "Pipeline",
                    "Activity",
                    "DataFlow",
                    "Dataset",
                    "Trigger",
                    "LinkedService",
                ]
            )
        ]
        analysis_sheets = [
            s
            for s in sheet_names
            if any(x in s for x in ["Impact", "Lineage", "Orphaned", "Usage"])
        ]
        other_sheets = [
            s for s in sheet_names if s not in core_sheets and s not in analysis_sheets
        ]

        col1, col2 = st.columns([1, 3])

        with col1:
            st.markdown("#### 📚 Sheet Categories")

            category = st.radio(
                "Select Category",
                ["Core Resources", "Analysis", "Other", "All Sheets"],
                key="explorer_category",
            )

            if category == "Core Resources":
                available_sheets = core_sheets
            elif category == "Analysis":
                available_sheets = analysis_sheets
            elif category == "Other":
                available_sheets = other_sheets
            else:
                available_sheets = sheet_names

            if not available_sheets:
                st.info("No sheets in this category")
                return

            selected_sheet = st.selectbox(
                "Select Sheet", available_sheets, key="explorer_sheet"
            )

        with col2:
            if selected_sheet:
                df = st.session_state.excel_data.get(selected_sheet)

                if df is None or not isinstance(df, pd.DataFrame):
                    st.warning(f"⚠️ Sheet '{selected_sheet}' is not a valid DataFrame")
                    return

                st.markdown(f"#### 📊 {selected_sheet}")

                # Sheet info
                info_col1, info_col2, info_col3 = st.columns(3)

                with info_col1:
                    st.metric("Rows", len(df))

                with info_col2:
                    st.metric("Columns", len(df.columns))

                with info_col3:
                    memory_mb = df.memory_usage(deep=True).sum() / 1024 / 1024
                    st.metric("Memory", f"{memory_mb:.2f} MB")

                st.markdown("---")

                # ═══════════════════════════════════════════════════════════
                # Search and Filter
                # ═══════════════════════════════════════════════════════════

                with st.expander("🔍 Search & Filter Options"):
                    search_col, filter_col = st.columns(2)

                    with search_col:
                        search_term = st.text_input(
                            "🔍 Search all columns",
                            "",
                            key=f"explorer_search_{selected_sheet}",
                        )

                    with filter_col:
                        if not df.empty:
                            filter_column = st.selectbox(
                                "Filter by Column",
                                ["None"] + df.columns.tolist(),
                                key=f"explorer_filter_col_{selected_sheet}",
                            )

                            if filter_column != "None":
                                unique_values = df[filter_column].unique()
                                if len(unique_values) <= 50:
                                    filter_value = st.multiselect(
                                        f"Select {filter_column}",
                                        unique_values,
                                        key=f"explorer_filter_val_{selected_sheet}",
                                    )
                                else:
                                    st.info(
                                        f"Too many unique values ({len(unique_values)}) for filter"
                                    )
                                    filter_value = None
                            else:
                                filter_value = None
                        else:
                            filter_column = "None"
                            filter_value = None

                # Apply filters
                display_df = df.copy()

                if search_term:
                    # Search across all string columns
                    mask = False
                    for col in display_df.select_dtypes(include=["object"]).columns:
                        mask |= (
                            display_df[col]
                            .astype(str)
                            .str.contains(search_term, case=False, na=False)
                        )
                    display_df = display_df[mask]

                if filter_column != "None" and filter_value:
                    display_df = display_df[
                        display_df[filter_column].isin(filter_value)
                    ]

                # Display data
                st.markdown(f"**Showing {len(display_df)} of {len(df)} rows**")

                # Pagination for large datasets
                rows_per_page = 100
                total_pages = (len(display_df) - 1) // rows_per_page + 1

                if total_pages > 1:
                    page = st.slider(
                        "Page", 1, total_pages, 1, key=f"explorer_page_{selected_sheet}"
                    )
                    start_idx = (page - 1) * rows_per_page
                    end_idx = min(start_idx + rows_per_page, len(display_df))
                    page_df = display_df.iloc[start_idx:end_idx]
                else:
                    page_df = display_df

                st.dataframe(page_df, use_container_width=True, height=500)

                # ═══════════════════════════════════════════════════════════
                # Export Options
                # ═══════════════════════════════════════════════════════════

                st.markdown("---")
                st.markdown("#### 📥 Export Options")

                col1, col2, col3 = st.columns(3)

                with col1:
                    # CSV Export
                    csv_bytes = to_csv_bytes(display_df)
                    st.download_button(
                        label="📄 Download as CSV",
                        data=csv_bytes,
                        file_name=f"{selected_sheet}.csv",
                        mime="text/csv",
                        key=f"download_csv_{selected_sheet}",
                    )

                with col2:
                    # JSON Export
                    json_bytes = to_json_bytes(display_df.to_dict(orient="records"))
                    st.download_button(
                        label="📋 Download as JSON",
                        data=json_bytes,
                        file_name=f"{selected_sheet}.json",
                        mime="application/json",
                        key=f"download_json_{selected_sheet}",
                    )

                with col3:
                    # Excel Export (single sheet)
                    if HAS_OPENPYXL:
                        buffer = io.BytesIO()
                        with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
                            display_df.to_excel(
                                writer, sheet_name=selected_sheet[:31], index=False
                            )

                        st.download_button(
                            label="📊 Download as Excel",
                            data=buffer.getvalue(),
                            file_name=f"{selected_sheet}.xlsx",
                            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                            key=f"download_excel_{selected_sheet}",
                        )
                    else:
                        st.info("Install openpyxl for Excel export")

                # Column statistics
                with st.expander("📊 Column Statistics"):
                    if not display_df.empty:
                        stats_df = display_df.describe(include="all").transpose()
                        st.dataframe(stats_df, use_container_width=True)
                    else:
                        st.info("No data to analyze")

    # ═══════════════════════════════════════════════════════════════════════
    # EXPORT TAB
    # ═══════════════════════════════════════════════════════════════════════

    def render_export_tab(self):
        """
        Render export options for bulk data download

        FIXED:
        - Multiple format support
        - Custom sheet selection
        - Batch export
        """

        st.markdown("### 📥 Export Dashboard")
        st.markdown("*Download analysis data in multiple formats*")

        if not st.session_state.excel_data:
            st.warning("⚠️ No data loaded")
            return

        # ═══════════════════════════════════════════════════════════════════
        # Export Configuration
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("#### 🎯 Select Data to Export")

        sheet_names = list(st.session_state.excel_data.keys())

        # Preset selections
        col1, col2 = st.columns(2)

        with col1:
            if st.button("✅ Select All Sheets", use_container_width=True):
                st.session_state.export_selected_sheets = sheet_names

        with col2:
            if st.button("❌ Clear Selection", use_container_width=True):
                st.session_state.export_selected_sheets = []

        # Sheet selection
        if "export_selected_sheets" not in st.session_state:
            st.session_state.export_selected_sheets = sheet_names[
                :5
            ]  # Default to first 5

        selected_sheets = st.multiselect(
            "Select Sheets to Export",
            sheet_names,
            default=st.session_state.export_selected_sheets,
            key="export_sheets_multiselect",
        )

        st.session_state.export_selected_sheets = selected_sheets

        if not selected_sheets:
            st.info("👆 Select at least one sheet to export")
            return

        st.markdown(f"**Selected: {len(selected_sheets)} sheets**")

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Export Format Selection
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("#### 📋 Export Format")

        col1, col2, col3 = st.columns(3)

        with col1:
            st.markdown("##### 📄 CSV (Zip)")
            st.markdown("*One CSV file per sheet*")

            if st.button(
                "📥 Download CSV Bundle", type="primary", use_container_width=True
            ):
                self.export_as_csv_zip(selected_sheets)

        with col2:
            st.markdown("##### 📊 Excel Workbook")
            st.markdown("*All sheets in one file*")

            if HAS_OPENPYXL:
                if st.button(
                    "📥 Download Excel File", type="primary", use_container_width=True
                ):
                    self.export_as_excel(selected_sheets)
            else:
                st.info("Install openpyxl for Excel export")

        with col3:
            st.markdown("##### 📋 JSON")
            st.markdown("*Structured JSON format*")

            if st.button(
                "📥 Download JSON Bundle", type="primary", use_container_width=True
            ):
                self.export_as_json(selected_sheets)

        st.markdown("---")

        # ═══════════════════════════════════════════════════════════════════
        # Quick Reports
        # ═══════════════════════════════════════════════════════════════════

        st.markdown("#### 📊 Quick Reports")

        col1, col2, col3 = st.columns(3)

        with col1:
            st.markdown("##### 🎯 Impact Report")
            st.markdown("*CRITICAL & HIGH impact pipelines*")

            if st.button("📥 Download Impact Report", use_container_width=True):
                self.export_impact_report()

        with col2:
            st.markdown("##### ⚠️ Cleanup Report")
            st.markdown("*All orphaned resources*")

            if st.button("📥 Download Cleanup Report", use_container_width=True):
                self.export_cleanup_report()

        with col3:
            st.markdown("##### 📈 Summary Report")
            st.markdown("*Executive summary*")

            if st.button("📥 Download Summary Report", use_container_width=True):
                self.export_summary_report()

    def export_as_csv_zip(self, sheet_names: List[str]):
        """Export selected sheets as CSV files in a zip archive"""
        import zipfile

        try:
            buffer = io.BytesIO()

            with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
                for sheet_name in sheet_names:
                    df = st.session_state.excel_data.get(sheet_name)

                    if df is not None and isinstance(df, pd.DataFrame):
                        csv_bytes = to_csv_bytes(df)
                        zip_file.writestr(f"{sheet_name}.csv", csv_bytes)

            st.download_button(
                label="✅ Click to Download ZIP",
                data=buffer.getvalue(),
                file_name="adf_analysis_export.zip",
                mime="application/zip",
                key="download_csv_zip",
            )

            st.success(f"✅ Created ZIP with {len(sheet_names)} CSV files")

        except Exception as e:
            st.error(f"❌ Export failed: {e}")

    def export_as_excel(self, sheet_names: List[str]):
        """Export selected sheets as Excel workbook"""
        try:
            buffer = io.BytesIO()

            with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
                for sheet_name in sheet_names:
                    df = st.session_state.excel_data.get(sheet_name)

                    if df is not None and isinstance(df, pd.DataFrame):
                        # Truncate sheet name to 31 chars (Excel limit)
                        safe_name = sheet_name[:31]
                        df.to_excel(writer, sheet_name=safe_name, index=False)

            st.download_button(
                label="✅ Click to Download Excel",
                data=buffer.getvalue(),
                file_name="adf_analysis_export.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                key="download_excel_workbook",
            )

            st.success(f"✅ Created Excel workbook with {len(sheet_names)} sheets")

        except Exception as e:
            st.error(f"❌ Export failed: {e}")

    def export_as_json(self, sheet_names: List[str]):
        """Export selected sheets as JSON"""
        try:
            export_data = {}

            for sheet_name in sheet_names:
                df = st.session_state.excel_data.get(sheet_name)

                if df is not None and isinstance(df, pd.DataFrame):
                    export_data[sheet_name] = df.to_dict(orient="records")

            json_bytes = to_json_bytes(export_data)

            st.download_button(
                label="✅ Click to Download JSON",
                data=json_bytes,
                file_name="adf_analysis_export.json",
                mime="application/json",
                key="download_json_bundle",
            )

            st.success(f"✅ Created JSON with {len(sheet_names)} sheets")

        except Exception as e:
            st.error(f"❌ Export failed: {e}")

    def export_impact_report(self):
        """Export focused impact report"""
        try:
            impact_df = safe_get_dataframe("ImpactAnalysis", "PipelineAnalysis")

            if impact_df.empty:
                st.warning("⚠️ No impact data available")
                return

            # Filter CRITICAL and HIGH only
            if "Impact" in impact_df.columns:
                critical_high = impact_df[
                    impact_df["Impact"].isin(["CRITICAL", "HIGH"])
                ]
            else:
                critical_high = impact_df

            csv_bytes = to_csv_bytes(critical_high)

            st.download_button(
                label="✅ Click to Download Impact Report",
                data=csv_bytes,
                file_name="impact_report_critical_high.csv",
                mime="text/csv",
                key="download_impact_report",
            )

            st.success(f"✅ Created impact report with {len(critical_high)} pipelines")

        except Exception as e:
            st.error(f"❌ Export failed: {e}")

    def export_cleanup_report(self):
        """Export orphaned resources report"""
        try:
            # Combine all orphaned resources
            orphaned_data = {}

            for sheet_name in [
                "OrphanedPipelines",
                "OrphanedDatasets",
                "OrphanedLinkedServices",
                "OrphanedTriggers",
            ]:
                df = safe_get_dataframe(sheet_name)
                if not df.empty:
                    orphaned_data[sheet_name] = df

            if not orphaned_data:
                st.warning("⚠️ No orphaned resources found")
                return

            # Export as Excel with multiple sheets
            buffer = io.BytesIO()

            with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
                for sheet_name, df in orphaned_data.items():
                    df.to_excel(writer, sheet_name=sheet_name[:31], index=False)

            st.download_button(
                label="✅ Click to Download Cleanup Report",
                data=buffer.getvalue(),
                file_name="cleanup_report_orphaned_resources.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                key="download_cleanup_report",
            )

            total_orphaned = sum(len(df) for df in orphaned_data.values())
            st.success(
                f"✅ Created cleanup report with {total_orphaned} orphaned resources"
            )

        except Exception as e:
            st.error(f"❌ Export failed: {e}")

    def export_summary_report(self):
        """Export executive summary report"""
        try:
            summary_df = safe_get_dataframe("Summary")

            if summary_df.empty:
                st.warning("⚠️ No summary data available")
                return

            csv_bytes = to_csv_bytes(summary_df)

            st.download_button(
                label="✅ Click to Download Summary Report",
                data=csv_bytes,
                file_name="executive_summary.csv",
                mime="text/csv",
                key="download_summary_report",
            )

            st.success("✅ Created executive summary report")

        except Exception as e:
            st.error(f"❌ Export failed: {e}")


# ═══════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════


def main():
    """
    Main application entry point

    FIXED:
    - Proper error handling
    - Session state initialization
    - Clean UI flow
    """

    try:
        # Create and run dashboard
        dashboard = ADF_Dashboard()
        dashboard.run()

    except Exception as e:
        st.error(f"❌ Application Error: {e}")

        with st.expander("🔍 Debug Information"):
            st.code(traceback.format_exc())

        st.markdown("---")
        st.markdown(
            """
        ### 🔧 Troubleshooting
        
        **Common Issues:**
        1. **File Upload Error** - Ensure Excel file is from ADF Analyzer v9.1
        2. **Missing Sheets** - Check that all required sheets exist in Excel file
        3. **Memory Error** - Try with smaller dataset or close other applications
        4. **Display Issues** - Try refreshing the page (F5)
        
        **Quick Fixes:**
        - Clear browser cache and refresh
        - Upload file again
        - Try sample data to verify app is working
        
        **Need Help?**
        - Check that dependencies are installed: `pip install streamlit pandas plotly networkx openpyxl`
        - Ensure Python 3.7+ is being used
        - Verify Excel file is not corrupted
        """
        )


if __name__ == "__main__":
    main()
