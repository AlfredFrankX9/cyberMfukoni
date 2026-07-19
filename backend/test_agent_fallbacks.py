import re
from app.services import agent_service


def test_fallback_greeting():
    res = agent_service.get_fallback_response("hi")
    assert isinstance(res, str)
    assert res.strip() != ""


def test_fallback_phishing_keyword():
    res = agent_service.get_fallback_response("I received a suspicious link — is this phishing?")
    assert isinstance(res, str)
    assert res.strip() != ""


def test_fallback_password_keyword():
    res = agent_service.get_fallback_response("password advice")
    assert isinstance(res, str)
    assert res.strip() != ""


def test_fallback_unknown_returns_generic():
    res = agent_service.get_fallback_response("")
    assert isinstance(res, str)
    assert res.strip() != ""
