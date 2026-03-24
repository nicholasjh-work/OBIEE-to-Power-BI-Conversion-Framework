"""Tests for migration validation logic."""
import pytest
from unittest.mock import MagicMock
from scripts.run_validation import run_count_check, ValidationResult


class TestCountCheck:
    def test_passing_count(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = (15000,)
        config = {"count_sql": "SELECT COUNT(*) FROM test_view"}
        result = run_count_check(cursor, "finance", config)
        assert result.passed is True
        assert result.pbi_value == 15000

    def test_zero_count_fails(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = (0,)
        config = {"count_sql": "SELECT COUNT(*) FROM empty_view"}
        result = run_count_check(cursor, "finance", config)
        assert result.passed is False

    def test_connection_error(self):
        cursor = MagicMock()
        cursor.execute.side_effect = Exception("timeout")
        config = {"count_sql": "SELECT COUNT(*) FROM broken_view"}
        result = run_count_check(cursor, "risk", config)
        assert result.passed is False
        assert "timeout" in result.detail
