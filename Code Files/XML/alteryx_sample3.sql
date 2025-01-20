-- For ToolID = "1"
WITH cte_toolID_1 AS (
    SELECT
        id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother
    FROM
        cusExSupplyTracker_ExternaSupplier
	WHERE 
        country IN ("China","United States Minor Outlying Islands") -- Condition As per ToolID="33"
    ),
	
-- For ToolID = "2"
cte_toolID_2 AS (
    SELECT
	    auditid,
		auditrecordno,
		UPPERCASE(companyname) AS companyname , -- As per ToolID = '35' specified in metainfo tag
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		department,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
 
        CASE 
			WHEN auditworkflowcurrentstatus IN ('Open', 'Closed') THEN  -- -- Condition As per ToolID = "35"
				CASE 
					WHEN DATEDIFF(day, auditdate, auditclosingdate) - 1 < 10 THEN auditid
					ELSE NULL
				END
			ELSE NULL
		END AS Audit_Date_Calcol
		
	FROM	
	    ExternalSupplyAudit
	),
	
-- JOIN Conditions       -- as per connection parameters for ToolID = "13" & ToolID = "14"
cte_ExternaSupplier_inner_join_audit AS
(
	SELECT 
        cte1.id,
		cte1.suppliername,
		cte1.supplierid,
		cte1.ecovadisid,
		cte1.cdpid,
		cte1.smdrericaid,
		cte1.smdmodifieddate,
		cte1.supplierparent,
		cte1.address,
		cte1.city,
		cte1.country,
		cte1.buyerregion,
		cte1.supplierregion,
		cte1.sector,
		cte1.curveid,
		cte1.ecomodifieddate,
		cte1.cdpmodifieddate,
		cte1.scorecard,
		cte1.scorecardbusinessunit,
		cte1.rollupsector,
		cte1.categoryfamily,
		cte1.externalsupplycategory,
		cte1.primarycategory,
		cte1.spend,
		cte1.categorystatus,
		cte1.businessunit,
		cte1.primaryplatform,
		cte1.ericastatus,
		cte1.reportingyear,
		cte1.segment,
		cte1.producttype,
		cte1.programstartyear,
		cte1.programendyear,
		cte1.program,
		cte1.ehscurrentrisk,
		cte1.laborcurrentrisk,
		cte1.ehsonsiteassess,
		cte1.onassessehsdate,
		cte1.laboronsiteassess,
		cte1.ethicslabordate,
		cte1.pieamrrisk,
		cte1.ecovatotalscore,
		cte1.ecovadisdate,
		cte1.reassessyear,
		cte1.ecovadiscoreenv,
		cte1.ecovadiscorelab,
		cte1.ecovadiscoresup,
		cte1.jjstatus,
		cte1.firesafetydate,
		cte1.informationsource,
		cte1.automatedfiredetectionandalarmsystem,
		cte1.automatedfiresuppressionsystem,
		cte1.hydrantsystem,
		cte1.twomeansofegress,
		cte1.commentsehssteam,
		cte1.commentsfiresafety,
		cte1.commentsother,
		
		cte2.auditid,
		cte2.auditrecordno,
		cte2.companyname , 
		cte2.nodeid,
		cte2.property,
		cte2.propertycode,
		cte2.audittype,
		cte2.auditsubtype,
		cte2.auditchecklist,
		cte2.auditworkflowcurrentstatus,
		cte2.auditworkflowcurrentstage,
		cte2.sitelocation,
		cte2.department,
		cte2.auditdate,
		cte2.auditor,
		cte2.thirdpartyauditors,
		cte2.siteleader,
		cte2.ehsleader,
		cte2.campusehsdirector,
		cte2.regionalehsleader,
		cte2.spoc,
		cte2.enterprisepsleader,
		cte2.segmentpsleader,
		cte2.businesspsleader,
		cte2.auditcapastatus,
		cte2.auditclosingdate,
		cte2.externalsupplierid,
		cte2.findingid,
		cte2.findingrecordno,
		cte2.findingstatus,
		cte2.datefindingclosed,
		cte2.findingdescription,
		cte2.findingpriority,
		cte2.findingauditid,
		cte2.findingsitelocation,
		cte2.findingdepartment,
		cte2.findingrepeated,
		cte2.findingregulatorynoncompliance,
		cte2.jnjstandardreference,
		cte2.closewithoutcapa,
		cte2.closewithoutcapacomments,
		cte2.reference,
		cte2.capaid,
		cte2.findrecordno,
		cte2.datecreated,
		cte2.capaassigned,
		cte2.actionno,
		cte2.capacurrentworkflowstatus,
		cte2.capacurrentworkflowstage,
		cte2.capasitelocation,
		cte2.capasubsitelocation,
		cte2.capadepartment,
		cte2.actionrequired,
		cte2.actionowner,
		cte2.actionownerreportinghierarchy,
		cte2.priority,
		cte2.requiresextensionapproval,
		cte2.targetdate,
		cte2.capacontroltype,
		cte2.capacomments,
		cte2.completioncomments,
		cte2.describeactionscompleted,
		cte2.completedby,
		cte2.completiondate,
		cte2.extensionreason,
		cte2.Audit_Date_Calcol,
		NULL as Right_id    -- as per ToolID="3" specified in meta tag
		NULL as "*Unknown"  -- as per ToolID="3" specified in meta tag 
	FROM 
		cte_toolID_1 as cte1
	INNER JOIN
		cte_toolID_2 as cte2
	ON cte1.id = cte2.externalsupplierid
),

cte_ExternaSupplier_left_join_audit AS
(
	SELECT 
        cte1.id,
		cte1.suppliername,
		cte1.supplierid,
		cte1.ecovadisid,
		cte1.cdpid,
		cte1.smdrericaid,
		cte1.smdmodifieddate,
		cte1.supplierparent,
		cte1.address,
		cte1.city,
		cte1.country,
		cte1.buyerregion,
		cte1.supplierregion,
		cte1.sector,
		cte1.curveid,
		cte1.ecomodifieddate,
		cte1.cdpmodifieddate,
		cte1.scorecard,
		cte1.scorecardbusinessunit,
		cte1.rollupsector,
		cte1.categoryfamily,
		cte1.externalsupplycategory,
		cte1.primarycategory,
		cte1.spend,
		cte1.categorystatus,
		cte1.businessunit,
		cte1.primaryplatform,
		cte1.ericastatus,
		cte1.reportingyear,
		cte1.segment,
		cte1.producttype,
		cte1.programstartyear,
		cte1.programendyear,
		cte1.program,
		cte1.ehscurrentrisk,
		cte1.laborcurrentrisk,
		cte1.ehsonsiteassess,
		cte1.onassessehsdate,
		cte1.laboronsiteassess,
		cte1.ethicslabordate,
		cte1.pieamrrisk,
		cte1.ecovatotalscore,
		cte1.ecovadisdate,
		cte1.reassessyear,
		cte1.ecovadiscoreenv,
		cte1.ecovadiscorelab,
		cte1.ecovadiscoresup,
		cte1.jjstatus,
		cte1.firesafetydate,
		cte1.informationsource,
		cte1.automatedfiredetectionandalarmsystem,
		cte1.automatedfiresuppressionsystem,
		cte1.hydrantsystem,
		cte1.twomeansofegress,
		cte1.commentsehssteam,
		cte1.commentsfiresafety,
		cte1.commentsother,
		
		cte2.auditid,
		cte2.auditrecordno,
		cte2.companyname , 
		cte2.nodeid,
		cte2.property,
		cte2.propertycode,
		cte2.audittype,
		cte2.auditsubtype,
		cte2.auditchecklist,
		cte2.auditworkflowcurrentstatus,
		cte2.auditworkflowcurrentstage,
		cte2.sitelocation,
		cte2.department,
		cte2.auditdate,
		cte2.auditor,
		cte2.thirdpartyauditors,
		cte2.siteleader,
		cte2.ehsleader,
		cte2.campusehsdirector,
		cte2.regionalehsleader,
		cte2.spoc,
		cte2.enterprisepsleader,
		cte2.segmentpsleader,
		cte2.businesspsleader,
		cte2.auditcapastatus,
		cte2.auditclosingdate,
		cte2.externalsupplierid,
		cte2.findingid,
		cte2.findingrecordno,
		cte2.findingstatus,
		cte2.datefindingclosed,
		cte2.findingdescription,
		cte2.findingpriority,
		cte2.findingauditid,
		cte2.findingsitelocation,
		cte2.findingdepartment,
		cte2.findingrepeated,
		cte2.findingregulatorynoncompliance,
		cte2.jnjstandardreference,
		cte2.closewithoutcapa,
		cte2.closewithoutcapacomments,
		cte2.reference,
		cte2.capaid,
		cte2.findrecordno,
		cte2.datecreated,
		cte2.capaassigned,
		cte2.actionno,
		cte2.capacurrentworkflowstatus,
		cte2.capacurrentworkflowstage,
		cte2.capasitelocation,
		cte2.capasubsitelocation,
		cte2.capadepartment,
		cte2.actionrequired,
		cte2.actionowner,
		cte2.actionownerreportinghierarchy,
		cte2.priority,
		cte2.requiresextensionapproval,
		cte2.targetdate,
		cte2.capacontroltype,
		cte2.capacomments,
		cte2.completioncomments,
		cte2.describeactionscompleted,
		cte2.completedby,
		cte2.completiondate,
		cte2.extensionreason,
		cte2.Audit_Date_Calcol,
		NULL as Right_id    -- as per ToolID="3" specified in meta tag
		NULL as "*Unknown"  -- as per ToolID="3" specified in meta tag 
	FROM 
		cte_toolID_1 as cte1
	LEFT JOIN
		cte_toolID_2 as cte2
	ON cte1.id = cte2.externalsupplierid
),


cte_ExternaSupplier_union_audit AS
(
SELECT 
        id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol
FROM 
    cte_ExternaSupplier_left_join_audit
    
UNION    -- -- as per ToolID = "10" specified in meta tag

SELECT 
        id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol
FROM 
    cte_ExternaSupplier_inner_join_audit
),
 
-- For ToolID = "11"  
cte_toolID_11 AS (
	SELECT
	    External_Supplier,
		Include,
		Type,
		Company
	FROM
	    External_Supply_Supplier_Attributes
    ),
	
cte_ExternaSupplier_union_audit_left_join_cte_toolID_11 AS (
    SELECT 
      id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company,
		NULL as "*Unknown"
		
    FROM
        cte_ExternaSupplier_union_audit as esua
	LEFT JOIN
		cte_toolID_11 as cte11
	ON 	esua.suppliername = cte11.External_Supplier
),

cte_ExternaSupplier_union_audit_inner_join_cte_toolID_11 AS (
    SELECT 
		id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company,
		NULL as "*Unknown"
		
    FROM
        cte_ExternaSupplier_union_audit as esua
	INNER JOIN
		cte_toolID_11 as cte11
	ON 	esua.suppliername = cte11.External_Supplier
),

cte_ExternaSupplier_union_toolID_11 AS (
    SELECT 
      id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company,
		
    FROM
	    cte_ExternaSupplier_union_audit_inner_join_cte_toolID_11
	
	UNION   -- as per tooldID = 13, 14 & 24 specified in connection parameters

	SELECT 
        id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company
	FROM
	    cte_ExternaSupplier_union_audit_left_join_cte_toolID_11
),

cte_toolID_28 AS (
    SELECT
	    id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		supplierparent,
		address,
		city,
		country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company,
		DateTimeNow() AS External_Supply_Refresh_Date   -- as per ToolID = '28'
	FROM
         cte_ExternaSupplier_union_toolID_11
),

cte_toolID_48_control_container AS (   -- as per Control Container 48
    SELECT
	    id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		country AS Reported_Country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company,
		NULL AS "*Unknown"
		
	FROM
         cte_ExternaSupplier_union_toolID_11
),

cte_toolID_39 AS (      
    SELECT
	   categoryfamily,
	   MAX(spend) AS Maximum_Spend             -- as per ToolID= '39'
	    
	FROM 
         cte_toolID_48_control_container
	GROUP BY 
		categoryfamily
),

cte_toolID_43 AS (
    SELECT
	    id,
		suppliername,
		supplierid,
		ecovadisid,
		cdpid,
		smdrericaid,
		smdmodifieddate,
		Reported_Country,
		buyerregion,
		supplierregion,
		sector,
		curveid,
		ecomodifieddate,
		cdpmodifieddate,
		scorecard,
		scorecardbusinessunit,
		rollupsector,
		categoryfamily,
		externalsupplycategory,
		primarycategory,
		spend,
		categorystatus,
		businessunit,
		primaryplatform,
		ericastatus,
		reportingyear,
		segment,
		producttype,
		programstartyear,
		programendyear,
		program,
		ehscurrentrisk,
		laborcurrentrisk,
		ehsonsiteassess,
		onassessehsdate,
		laboronsiteassess,
		ethicslabordate,
		pieamrrisk,
		ecovatotalscore,
		ecovadisdate,
		reassessyear,
		ecovadiscoreenv,
		ecovadiscorelab,
		ecovadiscoresup,
		jjstatus,
		firesafetydate,
		informationsource,
		automatedfiredetectionandalarmsystem,
		automatedfiresuppressionsystem,
		hydrantsystem,
		twomeansofegress,
		commentsehssteam,
		commentsfiresafety,
		commentsother,
		auditid,
		auditrecordno,
		companyname , 
		nodeid,
		property,
		propertycode,
		audittype,
		auditsubtype,
		auditchecklist,
		auditworkflowcurrentstatus,
		auditworkflowcurrentstage,
		sitelocation,
		cdepartment,
		auditdate,
		auditor,
		thirdpartyauditors,
		siteleader,
		ehsleader,
		campusehsdirector,
		regionalehsleader,
		spoc,
		enterprisepsleader,
		segmentpsleader,
		businesspsleader,
		auditcapastatus,
		auditclosingdate,
		externalsupplierid,
		findingid,
		findingrecordno,
		findingstatus,
		datefindingclosed,
		findingdescription,
		findingpriority,
		findingauditid,
		findingsitelocation,
		findingdepartment,
		findingrepeated,
		findingregulatorynoncompliance,
		jnjstandardreference,
		closewithoutcapa,
		closewithoutcapacomments,
		reference,
		capaid,
		findrecordno,
		datecreated,
		capaassigned,
		actionno,
		capacurrentworkflowstatus,
		capacurrentworkflowstage,
		capasitelocation,
		capasubsitelocation,
		capadepartment,
		actionrequired,
		actionowner,
		actionownerreportinghierarchy,
		priority,
		requiresextensionapproval,
		targetdate,
		capacontroltype,
		capacomments,
		completioncomments,
		describeactionscompleted,
		completedby,
		completiondate,
		extensionreason,
		Audit_Date_Calcol,
		External_Supplier,
		Include,
		Type,
		Company
		
	FROM
         cte_toolID_48_control_container
	ORDER BY Reported_Country DESC	      -- -- as per ToolID= '43'
)

-- to save files to a local file system

-- create a file format
create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 
    
-- creating an internal stage
CREATE OR REPLACE STAGE my_internal_stage
file_format = csv_file_format;

-- Example for Table 1
COPY INTO @my_internal_stage/customer_data.csv
FROM (SELECT * FROM customer_data);

-- Example for Table 2
COPY INTO @my_internal_stage/sales_region_data.csv
FROM (SELECT * FROM sales_region_data);

-- for showing all the stages in snowflake
SHOW STAGES;

-- for seeing all the files in internal stage
LIST @my_internal_stage;s

-- download the data into taget local file system
GET @my_internal_stage file://D:\Snowflake_Output; -- run this in SNOWSQL using CLI not in SNOWFLAKE UI and set the desired path


-- For file output w.r.t Snowflake/AWS or local system depenidng upon the business requirement
-- 1. Creating a Snowflake Stage
-- A stage is a Snowflake object that points to a location where data files are stored. 
-- You can create a stage for either internal Snowflake storage or external cloud storage (like AWS S3, Azure Blob, or Google Cloud Storage).

----------------------------------------------------AWS (S3) INTEGRATION------------------------------------------------------------------------
CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/banking_role' 
STORAGE_ALLOWED_LOCATIONS =('s3://czec-banking/DOWNLOAD_CSV/'); 

DESC integration s3_int;

----------------------- stage---------------------------------------------------------
-- Define an external stage to access the AWS S3 bucket. 
-- Ensure the necessary IAM role and S3 bucket policies are set for Snowflake to read from the bucket.

-- create a file format
create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 
 
-- create an external stage 
CREATE OR REPLACE STAGE s3_stage
URL ='s3://czec-banking/DOWNLOAD_CSV/'
file_format = csv_file_format
storage_integration = s3_int;

-- to show all stages
SHOW STAGES;

-- To show files processsed in stage 
LIST @s3_stage;

-- Example for Table 1
COPY INTO @s3_stage/customer_data.csv
FROM (SELECT * FROM customer_data);

-- Example for Table 2
COPY INTO @s3_stage/sales_region_data.csv
FROM (SELECT * FROM sales_region_data);

-- Alternative Approach

-- if staging details are not availble such as no roles and policies have been created abnd client have given aws access key then execute below steps
CREATE OR REPLACE STAGE my_external_stage
URL = 's3://czec-banking/DOWNLOAD_CSV/' -- path to S3 bucket folder
--STORAGE_INTEGRATION = my_s3_integration
CREDENTIALS = (
    AWS_KEY_ID = '*********************'                         -- aws access key 
    AWS_SECRET_KEY = '************************'					 -- aws secret access key
)
FILE_FORMAT = csv_file_format;

COPY INTO @my_external_stage/customer_data.csv -- copying data into external stage give proper file name with extension else it will create with data.csv(filename)
FROM (SELECT * FROM customer_data)
OVERWRITE=TRUE ; 

-- if file already exists with teh same name it will overwrite it else if you have not use this property and trying to write to the same file you get an error

COPY INTO @my_external_stage/sales_region_data.csv -- copying data into external stage give proper file name with extension else it will create with data.csv(filename)
FROM (SELECT * FROM sales_region_data)
OVERWRITE=TRUE ; 



--Automate the Process
-- Use Python or Shell scripting to automate the entire process if needed.
# import thenecessary library
import boto3
import botocore
from botocore.config import Config
import getpass
import snowflake.connector
import pandas as pd
import os
from io import StringIO
import csv


# Establish the connection
conn = snowflake.connector.connect(
    account= 'your_account_name',
    user='your_user_name',
    password = getpass.getpass('Your Snowflake Password: '),
    warehouse='your_warehouse',
    database='your_database',
    schema='your_schema',
    role='your_role'
)

# Test the connection
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_VERSION()")
print(cursor.fetchone())

# Set up AWS credentials manually (only for testing)
aws_access_key_id = 'your_secret_key'
aws_secret_access_key = 'your_aws_secret_access_key' 
region_name = 'your_region_name' 

# Create a session using the manual credentials
session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)

# Create an S3 client
s3 = session.client('s3')

# Now you can use the S3 client to perform operations to list all buckets
response = s3.list_buckets()
print(response)

# ACCESSING SPECIFIC BUCKET INFO

# Specify the name of your S3 bucket
bucket_name = 'czec-banking'
# List all objects in the specific S3 bucket
response = s3.list_objects_v2(Bucket=bucket_name)
# Print object keys (file names)
if 'Contents' in response:
    for obj in response['Contents']:
        print(f"Object Key: {obj['Key']}")
else:
    print("No objects found in the bucket.")

tables = ['sales_region_data', 'customer_data']  # Add all your table names here

# iterate through all the tables available in snowflake for which you want to extract data and put it in aws s3 specific folder inside a bucket
# Export data to S3
for table in tables:
    file_name = f"{table}.csv"
    export_query = f"""
    COPY INTO @my_external_stage/{file_name} -- create a stage my_external_stage in snowflake by referring code files
    FROM (SELECT * FROM {table})
    OVERWRITE=TRUE;
    """
    conn.cursor().execute(export_query)   -- export the data into respective s3 bucket folder
    print(f"Exported {table} data to S3 as {file_name}")

print("All tables exported successfully!")
		 
