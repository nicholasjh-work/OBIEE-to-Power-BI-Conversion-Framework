"""
Generate a migration status report from the inventory config.

Reads config/migration_inventory.yaml and outputs a summary
showing how many reports are migrated, in progress, and pending.

Usage:
    python scripts/generate_mapping_report.py
"""
import logging
from collections import Counter
from pathlib import Path

import yaml

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def main():
    config_path = Path(__file__).parent.parent / "config" / "migration_inventory.yaml"
    if not config_path.exists():
        logger.error("Inventory file not found: %s", config_path)
        return

    with open(config_path) as f:
        inventory = yaml.safe_load(f)

    reports = inventory.get("reports", [])
    total = len(reports)

    status_counts = Counter(r.get("status", "unknown") for r in reports)
    dataset_counts = Counter(r.get("target_dataset", "unmapped") for r in reports)

    logger.info("Migration Status Report")
    logger.info("=" * 40)
    logger.info("Total reports: %d", total)
    logger.info("")
    logger.info("By status:")
    for status, count in status_counts.most_common():
        pct = count / total * 100
        logger.info("  %-15s %3d  (%5.1f%%)", status, count, pct)

    logger.info("")
    logger.info("By target dataset:")
    for dataset, count in dataset_counts.most_common():
        logger.info("  %-20s %3d", dataset, count)

    # Flag any reports without a target dataset
    unmapped = [r for r in reports if not r.get("target_dataset")]
    if unmapped:
        logger.warning("")
        logger.warning("%d reports have no target dataset assigned:", len(unmapped))
        for r in unmapped[:10]:
            logger.warning("  - %s (%s)", r.get("name", "unnamed"), r.get("subject_area", "unknown"))


if __name__ == "__main__":
    main()
