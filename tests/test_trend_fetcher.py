"""
TDD TEST: Validates trend data structure against specs/technical.md §1.1 Resource Schema
These tests MUST FAIL initially—defining the contract an AI agent must implement
"""
import pytest
from typing import Dict, Any

# Contract from specs/technical.md §1.1: trends_ethiopia Resource Schema
EXPECTED_TREND_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "required": ["term", "volume", "relevance_score"],
        "properties": {
            "term": {"type": "string"},
            "volume": {"type": "integer", "minimum": 0},
            "relevance_score": {"type": "number", "minimum": 0.0, "maximum": 1.0}
        }
    }
}

def validate_trend_structure(trends: list) -> Dict[str, Any]:
    """Validates against EXACT schema from specs/technical.md"""
    errors = []
    
    if not isinstance(trends, list):
        errors.append("Trends must be a list")
        return {"valid": False, "errors": errors}
    
    for i, trend in enumerate(trends):
        if not isinstance(trend, dict):
            errors.append(f"Item {i} must be a dict")
            continue
        
        # Required fields per spec
        for field in ["term", "volume", "relevance_score"]:
            if field not in trend:
                errors.append(f"Item {i} missing required field '{field}'")
        
        # Type validation per spec
        if "term" in trend and not isinstance(trend["term"], str):
            errors.append(f"Item {i}.term must be string")
        if "volume" in trend and not isinstance(trend["volume"], int):
            errors.append(f"Item {i}.volume must be integer")
        if "relevance_score" in trend:
            if not isinstance(trend["relevance_score"], (int, float)):
                errors.append(f"Item {i}.relevance_score must be number")
            elif not (0.0 <= trend["relevance_score"] <= 1.0):
                errors.append(f"Item {i}.relevance_score must be 0.0-1.0")
    
    return {"valid": len(errors) == 0, "errors": errors}

def test_trend_fetcher_contract():
    """
    TDD CONTRACT: This test defines the EXACT structure the trend fetcher MUST produce
    AI Agent must implement code that makes this test PASS by aligning with specs/technical.md
    """
    # Simulated output from unimplemented trend fetcher (will FAIL intentionally)
    simulated_trends = [
        {"term": "Addis street fashion", "volume": "high", "relevance": 0.92},  # WRONG TYPES
        {"topic": "Coffee ceremony", "count": 1500, "score": 0.87}  # WRONG FIELD NAMES
    ]
    
    result = validate_trend_structure(simulated_trends)
    
    # This assertion WILL FAIL until AI agent implements correct structure
    # The failure message explicitly references the spec section for guidance
    assert result["valid"], (
        f"Trend structure violates specs/technical.md §1.1 Resource Schema:\n"
        f"Errors: {result['errors']}\n"
        f"Required schema: term(string), volume(integer), relevance_score(0.0-1.0)"
    )

def test_trend_fetcher_relevance_bounds():
    """Validates relevance_score stays within 0.0-1.0 per spec"""
    # Edge case: relevance_score = 1.5 (invalid per spec)
    invalid_trend = [{"term": "Test", "volume": 100, "relevance_score": 1.5}]
    
    result = validate_trend_structure(invalid_trend)
    
    assert result["valid"] == False, (
        "relevance_score=1.5 violates spec constraint (must be ≤1.0 per specs/technical.md §1.1)"
    )
