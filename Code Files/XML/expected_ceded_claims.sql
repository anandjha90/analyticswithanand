-- For ToolID = "1"
WITH cte_toolID_1 AS (
    SELECT
        "Item",
        "Ffilekey",
        "PolM_Sub_Seg",
        "Treaty",
        "Expected Claims"
    FROM
        EXPECTED_CEDED_CLAIMS_OUTPUT_TBL
),
  
-- For ToolID = "2"  
cte_toolID_2 AS (
    SELECT 
      "Net IBNR Reallocation: PL Based on Distribution of Future Net Mortality",
      "F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","F13","F14","F15","F16","F17","F18","F19","F20","F21",
      "F22","F23","F24", "F25","F26","F27","F28","F29","F30",
      "F31","F32","F33","F34","F35","F36"
    FROM
        SomeTable2
),
  
-- For ToolID = "6"  
cte_toolID_6 AS (
    SELECT 
      "Field_37", "Anticipated Net", "Field_37_2", "Field_37_3", "Full Year Plan (Net)", "Field_37_4", "Field_37_5", "Incr (Decr) IBNR",
      "Field_37_6", "Ending GL", "Field_37_7", "Current GL (Direct)",
      "Field_37_8", "Field_37_9", "Desired Direct", "Field_37_10", "Full Year Plan (Direct)", "Field_37_11", "Field_37_12",
      "Incr (Decr) IBNR2","Field_37_13", "Ending GL2", "Field_37_14","Current GL (Ceded)", "Field_37_15", "Field_37_16", "Desired Ceded", "Field_37_17",
      "Full Year Plan (Ceded)", "Field_37_18", "Field_37_19", "Incr (Decr) IBNR3", "Field_37_20",
      "Ending GL3", "Field_37_21", "Field_37_22"
    FROM SomeTable6
),

-- For ToolID = "27"  
cte_toolID_27 AS (
    SELECT 
      "Net IBNR Reallocation: PL&A Based on Distribution of Future Net Mortality",
      "F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","F13","F14","F15","F16","F17","F18","F19","F20","F21",
      "F22","F23","F24", "F25","F26","F27","F28","F29","F30","F31","F32"
    FROM
        SomeTable27
),
  
-- For ToolID = "28" 
cte_toolID_28 AS (
    SELECT 
      "Field_33", "Anticipated Net", "Field_33_2", "Field_33_3",
      "Full Year Plan (Net)", "Field_33_4", "Field_33_5",
      "Incr (Decr) IBNR", "Field_33_6", "Ending GL", "Field_33_7", "Current GL (Direct)",
      "Field_33_8", "Field_33_9", "Full Year Plan (Direct)", "Field_33_10", "Field_33_11",
      "Incr (Decr) IBNR2", "Field_33_12", "Ending GL2", "Field_33_13",
      "Current GL (Ceded)", "Field_33_14", "Field_33_15", "Field_33_16", "Desired Ceded",
      "Field_33_17", "Full Year Plan (Ceded)", "Field_33_18", "Field_33_19", "Incr (Decr) IBNR3",
      "Field_33_20", "Ending GL3", "Field_33_21", "Field_33_22"
  FROM 
       SomeTable28;
 ), 

-- For ToolID = "54" 
cte_toolID_28 AS (
    SELECT   
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "BT"
    FROM 
       SomeTable54;
 ), 
  
SELECT
    cte_1.Item,
    cte_1.Expected_Claims,
    cte_2.F4
FROM
    cte_1
LEFT JOIN cte_2
    ON cte_1.PolM_Sub_Seg = cte_2.F4;
