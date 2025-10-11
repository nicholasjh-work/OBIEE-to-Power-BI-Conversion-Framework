# OBIEE to Power BI Conversion Framework  
*Author: Nicholas Hidalgo*  
*Location: Boston, MA*  

**Project timeline:** 2017 – 2019  
**Originally authored:** 2017 – 2019 for enterprise reporting modernization  
**Public release:** 2025 (sanitized, industry context only)

---

### Overview
This repository documents the process used to migrate legacy Oracle BI Enterprise Edition (OBIEE) reports to Power BI.  
It reflects the steps, structure, and decisions from a multi-year modernization of reporting assets.  
The goal was to unify data models, reduce maintenance effort, and improve end-user accessibility.

---

### Structure
/obiee_exports/ # Sample XML exports and logical model fragments
/powerbi_equivalents/ # .pbix files or screenshots of equivalent Power BI visuals
/schema_maps/ # Field-level mappings between OBIEE subject areas and datasets
/validation/ # Report comparison scripts and QA documentation
/docs/ # Notes on DAX translation, data lineage, and adoption tracking

---

### Migration Scope
- ~240 legacy reports across finance, risk, and operations  
- 10 subject areas consolidated to 6 datasets  
- OBIEE RPD semantic layer refactored into Power BI dataflows  
- Standardized date and lookup tables for consistency across teams  

---

### Technical Notes
1. **Model Translation:** Logical table joins and hierarchies re-implemented as Power Query relationships.  
2. **DAX Replacements:** Legacy presentation layer expressions re-created with DAX calculated columns and measures.  
3. **Security:** Row-level filters applied to match OBIEE presentation catalog permissions.  
4. **Validation:** For each report, record counts and aggregates were verified within 1 percent variance.  

---

### Example Mapping
| OBIEE Field | Power BI Measure | Notes |
|--------------|------------------|-------|
| Ledger Amount | `SUM(Financials[Amount])` | Direct aggregate |
| OBIEE KPI – Margin | `DIVIDE([Revenue]-[Cost],[Revenue])` | Translated DAX formula |
| OBIEE Filter – Region = EMEA | `Region IN {"EMEA"}` | Replicated in report-level filter |

---

### Lessons Learned
- Maintain a data dictionary throughout migration; it becomes your single source of truth.  
- Automate dataset refresh validation early; manual spot-checks don’t scale.  
- Keep naming standards identical between systems to avoid re-training users.  

---

### How to Use
1. Review `/schema_maps` to see field-level translations.  
2. Use `/validation` scripts to compare aggregations between legacy and new models.  
3. Open `/powerbi_equivalents` for visual reference.  

---

### Author’s Note
Migrations succeed when you treat them as model engineering, not report re-painting.  
The examples here capture the mechanics and trade-offs that made the transition stable and repeatable.

---

**© 2017–2019 Nicholas Hidalgo.**
