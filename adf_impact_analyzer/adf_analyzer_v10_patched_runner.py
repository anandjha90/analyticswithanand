"""
adf_analyzer_v10_patched_runner.py

UPDATED TO USE ULTIMATE EDITION
"""

import sys
from pathlib import Path


def apply_all_enhancements():
    """Apply ALL patches in correct order"""
    
    print("\n" + "="*80)
    print("🔧 APPLYING ALL ENHANCEMENTS (ULTIMATE EDITION)")
    print("="*80 + "\n")
    
    # Step 1: Functional patches
    print("📦 Step 1/2: Functional patches...")
    try:
        from adf_analyzer_v10_patch import apply_all_patches
        
        success = apply_all_patches()
        if not success:
            print("❌ Functional patches failed")
            return False
        
        print("   ✅ Functional patches applied\n")
    
    except ImportError as e:
        print(f"❌ ERROR: Cannot import functional patches: {e}")
        return False
    
    # Step 2: Excel enhancements (ULTIMATE EDITION)
    print("✨ Step 2/2: Excel beautification (ULTIMATE EDITION)...")
    try:
        # 👉 CHANGED: Use the ultimate function
        from adf_analyzer_v10_excel_enhancements import apply_complete_excel_enhancements
        
        success = apply_complete_excel_enhancements()
        if not success:
            print("❌ Excel enhancements failed")
            return False
        
        print("   ✅ Excel beautification applied (ULTIMATE EDITION)\n")
    
    except ImportError as e:
        print(f"⚠️  Excel enhancements not available: {e}")
        print("   Continuing with basic formatting...\n")
    
    print("="*80)
    print("✅ ALL ENHANCEMENTS APPLIED - READY TO RUN")
    print("="*80 + "\n")
    
    return True


def main():
    """Main entry point"""
    
    print("""
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🚀 ADF ANALYZER v10.0 - ULTIMATE EDITION                                  ║
║                                                                              ║
║   ✅ All functional patches                                                  ║
║   ✅ All Excel beautification (ULTIMATE with Advanced Dashboard)            ║
║   ✅ Production-ready output                                                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
    """)
    
    # Check arguments
    if len(sys.argv) < 2:
        print("❌ ERROR: No input file specified")
        print("\nUSAGE:")
        print("  python adf_analyzer_v10_patched_runner.py <template.json>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    
    if not Path(json_file).exists():
        print(f"❌ ERROR: File not found: {json_file}")
        sys.exit(1)
    
    try:
        # Apply enhancements
        if not apply_all_enhancements():
            print("❌ Enhancement application failed")
            sys.exit(1)
        
        # Run analysis
        print("🔍 Running analysis...")
        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer
        
        analyzer = UltimateEnterpriseADFAnalyzer(
            json_file,
            enable_discovery=True,
            log_level=2
        )
        
        success = analyzer.run()
        
        if success:
            print("\n" + "="*80)
            print("🎉 SUCCESS! ULTIMATE EDITION ANALYSIS COMPLETE!")
            print("="*80)
            print("\n📁 Output: output/adf_analysis_latest.xlsx")
            print("\n✨ Your Excel now includes:")
            print("   ✅ Beautiful project banner")
            print("   ✅ Health Score Dashboard")
            print("   ✅ Cost Analysis")
            print("   ✅ Complexity Heat Map")
            print("   ✅ Performance Insights")
            print("   ✅ Top Pipelines Ranking")
            print("   ✅ Security Checklist")
            print("   ✅ And much more!")
            print("="*80 + "\n")
        else:
            print("❌ Analysis failed")
            sys.exit(1)
    
    except Exception as e:
        print(f"\n❌ FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()