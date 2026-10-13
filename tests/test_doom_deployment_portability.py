"""Deployment guards and provisioning without private experiment artifacts."""
import io
import json
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'stunts/doom-dcg'))
pytest.importorskip('solders')
import lanes_testnet as L

def test_default_initialization_needs_no_private_measurements(monkeypatch):
    monkeypatch.delenv('DOOM_INIT_METRICS', raising=False)
    values = L._measured_init_cu()
    assert len(values) == (sum(L.D.STATE_LENGTHS) + 16383) // 16384
    assert set(values) == {L.D.KERNEL_COMPUTE_CEILING}

def test_mismatched_measurement_count_is_rejected(tmp_path, monkeypatch):
    path = tmp_path / 'metrics.json'
    path.write_text(json.dumps({'initialization': {'cu_by_phase': [{'cu': 1}]}}))
    monkeypatch.setenv('DOOM_INIT_METRICS', str(path))
    with pytest.raises(ValueError, match='phase count'):
        L._measured_init_cu()

def test_wrong_network_is_rejected_before_cli(monkeypatch):
    monkeypatch.setattr(L.urllib.request, 'urlopen', lambda *a, **k: io.BytesIO(b'{"result":"wrong-network"}'))
    with pytest.raises(RuntimeError, match='expected Fogo testnet'):
        L.verify_testnet_rpc()

def test_expected_testnet_is_accepted(monkeypatch):
    payload = json.dumps({'result': L.D.TESTNET_GENESIS}).encode()
    monkeypatch.setattr(L.urllib.request, 'urlopen', lambda *a, **k: io.BytesIO(payload))
    L.verify_testnet_rpc()

def test_missing_source_refuses_deployment_before_cli(tmp_path, monkeypatch):
    import types
    path = tmp_path / 'resource.bin'
    path.write_bytes(b'test')
    monkeypatch.setattr(L.D, 'RESOURCE_BYTES', 4)
    monkeypatch.setattr(L.D, 'resource_tree', lambda data: [[L.D.DOOM_RESOURCE_ROOT]])
    monkeypatch.setattr(L, 'verify_testnet_rpc', lambda: None)
    monkeypatch.setattr(L.D, 'load_config', lambda directory: {'resource_key': 'fixture'})
    monkeypatch.setattr(L.urllib.request, 'urlopen', lambda *a, **k: io.BytesIO(b'{"result":{"value":null}}'))
    submitted = []
    monkeypatch.setattr(L.subprocess, 'run', lambda *a, **k: submitted.append(a))
    with pytest.raises(RuntimeError, match='source account is absent'):
        L.deploy(types.SimpleNamespace(run_dir=tmp_path, resource=path))
    assert submitted == []

def test_mismatched_source_bytes_are_rejected(tmp_path, monkeypatch):
    import base64
    path = tmp_path / 'resource.bin'
    path.write_bytes(b'test')
    monkeypatch.setattr(L.D, 'RESOURCE_BYTES', 4)
    monkeypatch.setattr(L.D, 'resource_tree', lambda data: [[L.D.DOOM_RESOURCE_ROOT]])
    payload = json.dumps({'result': {'value': {'executable': False, 'data': [base64.b64encode(b'wrong').decode(), 'base64']}}}).encode()
    monkeypatch.setattr(L.urllib.request, 'urlopen', lambda *a, **k: io.BytesIO(payload))
    with pytest.raises(RuntimeError, match='does not match'):
        L.verify_resource_source({'resource_key': 'fixture'}, path)
