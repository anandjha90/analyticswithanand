DATE TABLE
let
    //Variables
    StartDate = #date(2023, 1, 1),
    EndDate = Today,
    Today = Date.EndOfYear(DateTime.Date(DateTime.LocalNow())),
    Duration = Duration.Days(Duration.From(Today-StartDate))+1,

    //Date Columns
    Dates = List.Dates(StartDate, Duration, #duration(1,0,0,0)),
    #"Converted to Table" = Table.FromList(Dates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),

    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"Date", type date}}),

    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),

    #"Inserted Quarter" = Table.AddColumn(#"Inserted Year", "QuarterNo", each Date.QuarterOfYear([Date]), Int64.Type),

    #"Added Custom" = Table.AddColumn(#"Inserted Quarter", "Quarter", each "Q"&Text.From([QuarterNo])),
    #"Inserted Month" = Table.AddColumn(#"Added Custom", "MonthNumber", each Date.Month([Date]), Int64.Type),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Date.MonthName([Date]), type text),
    #"Inserted Merged Column" = Table.AddColumn(#"Inserted Month Name", "Merged", each Text.Combine({[Month Name], Text.From([Year], "en-IN")}, ","), type text),
    #"Renamed Columns1" = Table.RenameColumns(#"Inserted Merged Column",{{"Merged", "MonthYear"}})
in
    #"Renamed Columns1"
