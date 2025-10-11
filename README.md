# OBIEE to Power BI Conversion Framework  
*Author: Nicholas Hidalgo*  
*Location: Boston, MA*  

**Project timeline:** 2017 – 2019  
**Originally authored:** 2017 – 2019 for enterprise reporting modernization  

---

### Overview
This repository documents the process used to migrate legacy Oracle BI Enterprise Edition (OBIEE) reports to Power BI.  
It captures the actual migration logic, schema mappings, and validation methods used between 2017 and 2019.  
The goal was to unify data models, improve reliability, and reduce redundant semantic layers.

---

### Structure
/obiee_exports/ # Sample XML exports and RPD fragments
/powerbi_equivalents/ # Power BI .pbix files or screenshots of visuals
/schema_maps/ # Field-level mapping between OBIEE subject areas and Power BI datasets
/validation/ # Report comparison scripts and QA documentation
/docs/ # Notes on DAX translation, lineage, and testing procedures

---

### Migration Scope
- ~240 legacy reports across finance, risk, and operations  
- 10 subject areas consolidated into 6 datasets  
- OBIEE RPD semantic layer refactored into Power BI dataflows  
- Standardized date and lookup tables for cross-report consistency  

---

### Technical Notes
1. **Model Translation:** Logical table joins and hierarchies re-implemented as Power Query relationships.  
2. **DAX Replacements:** OBIEE presentation-layer expressions recreated using DAX calculated columns and measures.  
3. **Security:** Row-level filters replicate OBIEE catalog permissions.  
4. **Validation:** Each report’s record counts and aggregates verified within 1% variance.

---

### Example Mapping
| OBIEE Field | Power BI Measure | Notes |
|--------------|------------------|-------|
| Ledger Amount | `SUM(Financials[Amount])` | Direct aggregate |
| OBIEE KPI – Margin | `DIVIDE([Revenue]-[Cost],[Revenue])` | Equivalent DAX measure |
| Filter – Region = EMEA | `Region IN {"EMEA"}` | Replicated in report-level filter |

---

### Lessons Learned
- Keep a live data dictionary during migration; it becomes the reference point.  
- Automate refresh validation early; manual spot checks don’t scale.  
- Preserve naming standards across tools to minimize retraining.

---

### How to Use
1. Review `/schema_maps` for field-level translations.  
2. Use `/validation` scripts to compare legacy vs. Power BI aggregations.  
3. Check `/powerbi_equivalents` for visual references.

---

### Author’s Note
Migrations succeed when handled as data-model engineering, not visual replication.  
The contents here show the real engineering work that made that migration consistent and reliable.

---

**© 2017–2019 Nicholas Hidalgo.**
