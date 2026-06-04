"""ADF Analyzer v10 Patch Module - Additional parsers and functionality enhancements"""

import re
from typing import Any, Dict, List

def patch_databricks_activities(analyzer_class):
    """
     PATCH #1: Add Databricks activity parsers

    Handles:
    - DatabricksNotebook
    - DatabricksSparkJar
    - DatabricksSparkPython
    """

    def _parse_databricks_activity(self, parsed, type_props: dict, activity_type: str):
        """Parse Databricks activities"""
        try:
            if activity_type == 'DatabricksNotebook':

                notebook_path = type_props.get('notebookPath', '')
                if notebook_path:
                    parsed.file_path = self._extract_value(notebook_path)
                    parsed.role = f"Databricks NB: {parsed.file_path[:30]}"

                base_params = type_props.get('baseParameters', {})
                if isinstance(base_params, dict):
                    param_strs = [
                        f"{k}={self._extract_value(v)[:30]}"
                        for k, v in list(base_params.items())[:5]
                    ]
                    if param_strs:
                        parsed.values_info = f"Params: {', '.join(param_strs)}"

                libraries = type_props.get('libraries', [])
                if libraries:
                    lib_count = len(libraries)
                    if parsed.values_info:
                        parsed.values_info += f" | Libraries: {lib_count}"
                    else:
                        parsed.values_info = f"Libraries: {lib_count}"

            elif activity_type == 'DatabricksSparkJar':

                main_class = type_props.get('mainClassName', '')
                if main_class:
                    parsed.role = f"Databricks Jar: {main_class[:30]}"

                parameters = type_props.get('parameters', [])
                if parameters:
                    parsed.values_info = f"Parameters: {len(parameters)}"

            elif activity_type == 'DatabricksSparkPython':

                python_file = type_props.get('pythonFile', '')
                if python_file:
                    parsed.file_path = self._extract_value(python_file)
                    parsed.role = f"Databricks Py: {parsed.file_path[:30]}"

                parameters = type_props.get('parameters', [])
                if parameters:
                    parsed.values_info = f"Parameters: {len(parameters)}"

        except Exception as e:
            self.logger.warning(f"Databricks activity parsing failed: {e}", activity_type)

    analyzer_class._parse_databricks_activity = _parse_databricks_activity

    print("   Patch applied: Databricks activities")

def patch_azure_function_activity(analyzer_class):
    """
     PATCH #2: Add Azure Function activity parser
    """

    def _parse_azure_function_activity(self, parsed, type_props: dict):
        """Parse Azure Function activity"""
        try:
            function_name = type_props.get('functionName', '')
            method = type_props.get('method', 'GET')

            if function_name:
                parsed.role = f"AzFunc {method}: {self._extract_value(function_name)}"

            body = type_props.get('body', '')
            if body:
                body_str = self._extract_value(body)[:100]
                parsed.values_info = f"Body: {body_str}"

            headers = type_props.get('headers', {})
            if isinstance(headers, dict) and headers:
                header_count = len(headers)
                if parsed.values_info:
                    parsed.values_info += f" | Headers: {header_count}"
                else:
                    parsed.values_info = f"Headers: {header_count}"

        except Exception as e:
            self.logger.warning(f"Azure Function activity parsing failed: {e}")

    analyzer_class._parse_azure_function_activity = _parse_azure_function_activity

    print("   Patch applied: Azure Function activity")

def patch_missing_hdinsight_activities(analyzer_class):
    """
     PATCH #3: Add missing HDInsight activities

    Handles:
    - HDInsightMapReduce
    """

    def _parse_hdinsight_mapreduce_activity(self, parsed, type_props: dict):
        """Parse HDInsight MapReduce activity"""
        try:
            jar_file = type_props.get('jarFilePath', '')
            class_name = type_props.get('className', '')

            if jar_file:
                parsed.file_path = self._extract_value(jar_file)

            if class_name:
                parsed.role = f"HDI MapReduce: {self._extract_value(class_name)[:30]}"

            arguments = type_props.get('arguments', [])
            if arguments:
                parsed.values_info = f"Arguments: {len(arguments)}"

        except Exception as e:
            self.logger.warning(f"HDInsight MapReduce parsing failed: {e}")

    analyzer_class._parse_hdinsight_mapreduce_activity = _parse_hdinsight_mapreduce_activity

    print("   Patch applied: HDInsight MapReduce activity")

def patch_salesforce_activities(analyzer_class):
    """
     PATCH #4: Add Salesforce source/sink activities
    """

    def _parse_salesforce_activity(self, parsed, type_props: dict, activity_type: str):
        """Parse Salesforce activities"""
        try:
            if 'Source' in activity_type:

                query = type_props.get('query', '')
                if query:
                    parsed.sql = self._extract_value(query)[:10000]
                    parsed.role = "Salesforce Query"

            elif 'Sink' in activity_type:

                object_name = type_props.get('sObjectName', '')
                if object_name:
                    parsed.sink_table = self._extract_value(object_name)
                    parsed.role = f"Salesforce Sink: {parsed.sink_table[:30]}"

                write_behavior = type_props.get('writeBehavior', '')
                if write_behavior:
                    parsed.values_info = f"WriteBehavior: {write_behavior}"

        except Exception as e:
            self.logger.warning(f"Salesforce activity parsing failed: {e}")

    analyzer_class._parse_salesforce_activity = _parse_salesforce_activity

    print("   Patch applied: Salesforce activities")

def patch_parse_activity_dispatcher(analyzer_class):
    """
     PATCH #5: Update parse_activity to dispatch to new parsers
    """

    original_parse_activity = analyzer_class.parse_activity

    def enhanced_parse_activity(self, activity: dict, pipeline: str, seq: int,
                               parent: str = '', depth: int = 0):
        """Enhanced parse_activity with new type handlers"""

        parsed = original_parse_activity(self, activity, pipeline, seq, parent, depth)

        if parsed is None:
            return None

        activity_type = activity.get('type', 'Unknown')
        type_props = activity.get('typeProperties', {})

        if activity_type in ['DatabricksNotebook', 'DatabricksSparkJar', 'DatabricksSparkPython']:
            self._parse_databricks_activity(parsed, type_props, activity_type)

        elif activity_type == 'AzureFunctionActivity':
            self._parse_azure_function_activity(parsed, type_props)

        elif activity_type == 'HDInsightMapReduce':
            self._parse_hdinsight_mapreduce_activity(parsed, type_props)

        elif 'Salesforce' in activity_type:
            self._parse_salesforce_activity(parsed, type_props, activity_type)

        return parsed

    analyzer_class.parse_activity = enhanced_parse_activity

    print("   Patch applied: Activity dispatcher updated")

def patch_dataset_location_extraction(analyzer_class):
    """
     PATCH #6: Add missing dataset types to location extraction

    Adds:
    - AzureTable
    - Office365Table
    - GoogleBigQuery
    - AmazonRedshift
    - Hive, Impala, Spark, Presto, Phoenix, Netezza
    """

    original_extract_dataset_location = analyzer_class._extract_dataset_location

    def enhanced_extract_dataset_location(self, ds_resource: dict) -> str:
        """Enhanced dataset location extraction"""

        location = original_extract_dataset_location(self, ds_resource)

        if location:
            return location

        try:
            props = ds_resource.get('properties', {})
            type_props = props.get('typeProperties', {})
            ds_type = props.get('type', '')

            if 'AzureTable' in ds_type:
                table_name = type_props.get('tableName')
                if table_name:
                    table_val = self._extract_value(table_name)
                    return self._clean_parameter_expression(table_val)[:200]

            if 'Office365' in ds_type:
                table_name = type_props.get('tableName')
                if table_name:
                    table_val = self._extract_value(table_name)

                    predicate = type_props.get('predicate', '')
                    if predicate:
                        return f"{table_val} WHERE {predicate[:50]}"[:200]

                    return self._clean_parameter_expression(table_val)[:200]

            if 'BigQuery' in ds_type:
                project = type_props.get('project', '')
                dataset = type_props.get('dataset', '')
                table = type_props.get('table', '')

                parts = []
                if project:
                    parts.append(self._extract_value(project))
                if dataset:
                    parts.append(self._extract_value(dataset))
                if table:
                    parts.append(self._extract_value(table))

                if parts:
                    return '.'.join(parts)[:200]

            if 'Redshift' in ds_type:
                schema_val = None
                table_val = None

                schema_field = type_props.get('schema') or type_props.get('schemaName')
                table_field = type_props.get('table') or type_props.get('tableName')

                if schema_field:
                    schema_val = self._extract_value(schema_field)
                if table_field:
                    table_val = self._extract_value(table_field)

                if schema_val and table_val:
                    schema_display = self._clean_parameter_expression(schema_val)
                    table_display = self._clean_parameter_expression(table_val)
                    return f"{schema_display}.{table_display}"[:200]

                return self._clean_parameter_expression(table_val or schema_val or '')[:200]

            big_data_types = ['Hive', 'Impala', 'Spark', 'Presto', 'Phoenix', 'Netezza']

            if any(bd_type in ds_type for bd_type in big_data_types):
                schema_val = None
                table_val = None

                schema_field = type_props.get('schema') or type_props.get('schemaName')
                table_field = type_props.get('table') or type_props.get('tableName')

                if schema_field:
                    schema_val = self._extract_value(schema_field)
                if table_field:
                    table_val = self._extract_value(table_field)

                if schema_val and table_val:
                    return f"{schema_val}.{table_val}"[:200]

                return (table_val or schema_val or '')[:200]

            if 'AdWords' in ds_type:
                query = type_props.get('query', '')
                if query:
                    return f"Query: {self._extract_value(query)[:150]}"[:200]

            if 'Concur' in ds_type:
                entity_name = type_props.get('entityName', '')
                if entity_name:
                    return self._extract_value(entity_name)[:200]

        except Exception as e:
            self.logger.debug(f"Enhanced dataset location extraction failed: {e}")

        return ''

    analyzer_class._extract_dataset_location = enhanced_extract_dataset_location

    print("   Patch applied: Enhanced dataset location extraction (+10 types)")

def patch_trigger_parsers(analyzer_class):
    """
     PATCH #7: Add missing trigger types

    Adds:
    - ChainingTrigger
    - CustomEventsTrigger
    - RerunTumblingWindowTrigger
    """

    original_parse_trigger = analyzer_class.parse_trigger

    def enhanced_parse_trigger(self, resource: dict):
        """Enhanced trigger parser"""

        try:
            name = self._extract_name(resource.get('name', ''))
            props = resource.get('properties', {})
            trigger_type = props.get('type', 'Unknown')
            type_props = props.get('typeProperties', {})

            if trigger_type in ['ChainingTrigger', 'CustomEventsTrigger', 'RerunTumblingWindowTrigger']:

                self.metrics['trigger_types'][trigger_type] += 1

                runtime_state = props.get('runtimeState', 'Unknown')

                rec = {
                    'Trigger': name,
                    'Type': trigger_type,
                    'State': runtime_state,
                    'Frequency': '',
                    'Interval': '',
                    'Schedule': '',
                    'StartTime': '',
                    'EndTime': '',
                    'TimeZone': '',
                    'Pipelines': '',
                    'Description': self._extract_value(props.get('description', ''))
                }

                if trigger_type == 'ChainingTrigger':
                    depends_on = type_props.get('dependsOn', [])
                    dep_triggers = []

                    if isinstance(depends_on, list):
                        for dep in depends_on:
                            if isinstance(dep, dict):
                                ref_trigger = dep.get('referenceTrigger', {})
                                if isinstance(ref_trigger, dict):
                                    trigger_name = self._extract_name(ref_trigger.get('referenceName', ''))
                                    if trigger_name:
                                        dep_triggers.append(trigger_name)

                    if dep_triggers:
                        rec['Schedule'] = f"Depends on: {', '.join(dep_triggers)}"
                    else:
                        rec['Schedule'] = 'Chaining trigger'

                elif trigger_type == 'CustomEventsTrigger':
                    events = type_props.get('events', [])
                    if events:
                        rec['Schedule'] = f"Custom events: {', '.join(events[:3])}"
                    else:
                        rec['Schedule'] = 'Event Grid trigger'

                elif trigger_type == 'RerunTumblingWindowTrigger':
                    parent_trigger = type_props.get('parentTrigger', {})
                    if isinstance(parent_trigger, dict):
                        parent_name = self._extract_name(parent_trigger.get('referenceName', ''))
                        rec['Schedule'] = f"Rerun of: {parent_name}"

                pipelines = props.get('pipelines', [])
                pipeline_names = []

                if isinstance(pipelines, list):
                    for p in pipelines:
                        if isinstance(p, dict):
                            ref = p.get('pipelineReference', {})
                            if isinstance(ref, dict):
                                pname = self._extract_name(ref.get('referenceName', ''))
                                if pname:
                                    pipeline_names.append(pname)

                                    if runtime_state == 'Started':
                                        self.usage_tracking['pipelines_used'].add(pname)
                                        self.usage_tracking['triggers_used'].add(name)

                                    params = p.get('parameters', {})
                                    param_summary = []
                                    if isinstance(params, dict):
                                        for param_name, param_value in list(params.items())[:5]:
                                            value_str = self._extract_value(param_value)
                                            param_summary.append(f"{param_name}={value_str[:30]}")

                                    self.results['trigger_details'].append({
                                        'Trigger': name,
                                        'Pipeline': pname,
                                        'TriggerType': trigger_type,
                                        'Schedule': rec['Schedule'],
                                        'State': runtime_state,
                                        'Parameters': ', '.join(param_summary) if param_summary else 'None'
                                    })

                rec['Pipelines'] = ', '.join(pipeline_names[:10])
                if len(pipeline_names) > 10:
                    rec['Pipelines'] += f" (+{len(pipeline_names)-10} more)"

                self.results['triggers'].append(rec)

            else:

                original_parse_trigger(self, resource)

        except Exception as e:
            self.logger.warning(f"Enhanced trigger parsing failed: {e}", name)

    analyzer_class.parse_trigger = enhanced_parse_trigger

    print("   Patch applied: Enhanced trigger parsing (+3 types)")

def patch_global_parameters_resource(analyzer_class):
    """
     PATCH #8: Add GlobalParameters as separate resource type
    """

    original_register = analyzer_class.register_all_resources

    def enhanced_register_all_resources(self):
        """Enhanced resource registration"""

        original_register(self)

        resources = self.data.get('resources', [])

        for resource in resources:
            if not isinstance(resource, dict):
                continue

            try:
                res_type = resource.get('type', '')

                if 'globalparameters' in res_type.lower():
                    name = self._extract_name(resource.get('name', ''))

                    self.resources['globalParameters'][name] = resource
                    self.resources['all'][name] = {
                        'type': res_type,
                        'resource': resource
                    }

                    props = resource.get('properties', {})
                    if isinstance(props, dict):
                        for param_name, param_def in props.items():
                            if isinstance(param_def, dict):
                                param_type = param_def.get('type', 'unknown')
                                param_value = param_def.get('value', '')

                                self.results['global_parameters'].append({
                                    'ParameterName': param_name,
                                    'Type': param_type,
                                    'Value': self._extract_value(param_value)[:500],
                                    'Source': 'Resource',
                                    'Metadata': ''
                                })

            except Exception as e:
                continue

        if self.resources['globalParameters']:
            self.logger.info(f"  • Global Parameters (resource): {len(self.resources['globalParameters'])}")

    analyzer_class.register_all_resources = enhanced_register_all_resources

    print("   Patch applied: GlobalParameters as resource")

def patch_template_outputs(analyzer_class):
    """
     PATCH #9: Add template outputs capture
    """

    original_load_template = analyzer_class.load_template

    def enhanced_load_template(self) -> bool:
        """Enhanced template loading with outputs"""

        result = original_load_template(self)

        if result:

            outputs = self.data.get('outputs', {})
            if outputs:
                self.logger.info(f"Template outputs: {len(outputs)}")

                for output_name, output_def in outputs.items():
                    if isinstance(output_def, dict):
                        output_type = output_def.get('type', 'unknown')
                        output_value = output_def.get('value', '')

                        if 'template_outputs' not in self.results:
                            self.results['template_outputs'] = []

                        self.results['template_outputs'].append({
                            'OutputName': output_name,
                            'Type': output_type,
                            'Value': self._extract_value(output_value)[:500]
                        })

        return result

    analyzer_class.load_template = enhanced_load_template

    print("   Patch applied: Template outputs capture")

def patch_excel_export(analyzer_class):
    """
     PATCH #10: Add Excel export for new sheets
    """

    original_write_additional_resource_sheets = analyzer_class._write_additional_resource_sheets

    def enhanced_write_additional_resource_sheets(self, writer):
        """Enhanced additional resource sheets"""

        original_write_additional_resource_sheets(self, writer)

        if hasattr(self, 'results') and 'template_outputs' in self.results:
            if self.results['template_outputs']:
                import pandas as pd
                df = pd.DataFrame(self.results['template_outputs'])
                safe_name = self._get_unique_sheet_name('TemplateOutputs')
                df.to_excel(writer, sheet_name=safe_name, index=False)
                self._format_sheet(writer, safe_name, freeze_panes=True, auto_filter=True)

                self.logger.info(f"  ✓ TemplateOutputs: {len(df):,} rows")

    analyzer_class._write_additional_resource_sheets = enhanced_write_additional_resource_sheets

    print("   Patch applied: Excel export for new sheets")

def apply_all_patches(analyzer_class=None):
    """
     MASTER FUNCTION: Apply all patches to analyzer

    Usage:
        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
        from adf_analyzer_v10_patch import apply_all_patches

        apply_all_patches(UltimateEnterpriseADFAnalyzer)

        analyzer = UltimateEnterpriseADFAnalyzer('template.json')
        analyzer.run()

    Or with auto-import:
        from adf_analyzer_v10_patch import apply_all_patches

        apply_all_patches()  # Auto-imports and patches

        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
        analyzer = UltimateEnterpriseADFAnalyzer('template.json')
        analyzer.run()
    """

    if analyzer_class is None:
        try:
            from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
            analyzer_class = UltimateEnterpriseADFAnalyzer
        except ImportError:
            print(" ERROR: Could not import UltimateEnterpriseADFAnalyzer")
            print("   Make sure adf_analyzer_v10_complete.py is in the same directory")
            return False

    print("\n" + "="*80)
    print("🔧 APPLYING COMPREHENSIVE PATCHES TO ADF ANALYZER v10.0")
    print("="*80 + "\n")

    try:

        patch_databricks_activities(analyzer_class)
        patch_azure_function_activity(analyzer_class)
        patch_missing_hdinsight_activities(analyzer_class)
        patch_salesforce_activities(analyzer_class)
        patch_parse_activity_dispatcher(analyzer_class)

        patch_dataset_location_extraction(analyzer_class)

        patch_trigger_parsers(analyzer_class)

        patch_global_parameters_resource(analyzer_class)
        patch_template_outputs(analyzer_class)

        patch_excel_export(analyzer_class)

        print("\n" + "="*80)
        print(" ALL PATCHES APPLIED SUCCESSFULLY")
        print("="*80)
        print("\nEnhancements added:")
        print("  • 4 new activity types (Databricks, AzureFunction, HDI MapReduce, Salesforce)")
        print("  • 10 new dataset types (AzureTable, Office365, BigQuery, Redshift, etc.)")
        print("  • 3 new trigger types (ChainingTrigger, CustomEvents, Rerun)")
        print("  • GlobalParameters as resource")
        print("  • Template outputs capture")
        print("  • Enhanced Excel export")
        print("\nTotal gaps fixed: 10/10 ")
        print("="*80 + "\n")

        return True

    except Exception as e:
        print(f"\n PATCH APPLICATION FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False

def auto_patch():
    """
    Auto-apply patches when module is imported

    This allows:
        import adf_analyzer_v10_patch  # Automatically patches
        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
    """
    try:
        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
        apply_all_patches(UltimateEnterpriseADFAnalyzer)
    except ImportError:
        pass  # Silently fail if base module not found

